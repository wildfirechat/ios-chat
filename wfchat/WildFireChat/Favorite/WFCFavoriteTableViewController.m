//
//  FavoriteTableViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteTableViewController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "AppService.h"
#import "WFCFavoriteBaseCell.h"
#import "WFCFavoriteTextCell.h"
#import "WFCFavoriteUnknownCell.h"
#import "WFCFavoriteImageCell.h"
#import "WFCFavoriteFileCell.h"
#import "WFCFavoriteLocationCell.h"
#import "WFCFavoriteSoundCell.h"
#import "WFCFavoriteVideoCell.h"
#import "WFCFavoriteLinkCell.h"
#import "WFCFavoriteCompositeCell.h"
#import "AFNetworking.h"
#import <AVFoundation/AVFoundation.h>


@interface WFCFavoriteTableViewController () <UITableViewDataSource, UITableViewDelegate, MWPhotoBrowserDelegate, AVAudioPlayerDelegate>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)NSMutableArray<WFCUFavoriteItem *> *items;
@property(nonatomic, strong)NSMutableArray<WFCUFavoriteItem *> *imageVideoItems;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL loading;

@property(nonatomic, strong)WFCFavoriteBaseCell *selectedCell;
@property(nonatomic, strong)VideoPlayerKit *videoPlayerViewController;

@property(nonatomic, strong)AVAudioPlayer *player;
@property(nonatomic, assign)BOOL isPlayingSound;
@property(nonatomic, strong)WFCUFavoriteItem *playingSoundItem;
@end

@implementation WFCFavoriteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    self.items = [[NSMutableArray alloc] init];
    
    [self loadMoreData];
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapCell:)]];
    [self.tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapCell:)]];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.title = LocalizedString(@"MyFarovrites");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)playSound:(WFCUFavoriteItem *)item {
    __weak typeof(self)ws = self;
    NSString *downloadDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath;
    if ([item.url.pathExtension isEqual:@"mp3"]) {
        filePath = [downloadDir stringByAppendingPathComponent:[NSString stringWithFormat:@"fav_sound_%d.mp3", item.favId]];
    } else {
        filePath = [downloadDir stringByAppendingPathComponent:[NSString stringWithFormat:@"fav_sound_%d.amr", item.favId]];
    }
    self.isPlayingSound = YES;
    self.playingSoundItem = item;
    [self downloadFileWithURL:item.url savedPath:filePath downloadSuccess:^(NSURLResponse *response, NSURL *path) {
        NSLog(@"sound downloaded!");
        if (!self.isPlayingSound || self.playingSoundItem != item) {
            return;
        }
        
        if (ws.player) {
            [ws.player stop];
        }
        
        ws.player = [[AVAudioPlayer alloc] initWithData:[[WFCCIMService sharedWFCIMService] getWavData:filePath] error:nil];
        [ws.player prepareToPlay];
        ws.player.delegate = self;
        [ws.player play];
    } downloadFailure:^(NSError *error) {
        [ws.view makeToast:@"下载失败!" duration:1 position:CSToastPositionCenter];
    }];
}

- (void)stopPlaySound {
    self.isPlayingSound = NO;
    self.playingSoundItem = nil;
    [self.player stop];
    self.player = nil;
}

- (void)downloadFileWithURL:(NSString*)requestURLString
                  savedPath:(NSString*)savedPath
            downloadSuccess:(void (^)(NSURLResponse *response, NSURL *filePath))success
            downloadFailure:(void (^)(NSError *error))failure {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request =[serializer requestWithMethod:@"GET" URLString:requestURLString parameters:nil error:nil];
    NSURLSessionDownloadTask *task = [[AFHTTPSessionManager manager] downloadTaskWithRequest:request progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:[savedPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error){
                failure(error);
            }else{
                success(response,filePath);
            }
        });
    }];
    
    [task resume];
}

- (void)showItem:(WFCUFavoriteItem *)item {
    switch (item.favType) {
        case MESSAGE_CONTENT_TYPE_TEXT:
        {
            UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            textContainer.backgroundColor = self.view.backgroundColor;
            
            UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [WFCUUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom])];
            
             textView.text = self.selectedCell.favoriteItem.title;
            textView.textAlignment = NSTextAlignmentCenter;
            textView.font = [UIFont systemFontOfSize:28];
            textView.editable = NO;
            textView.backgroundColor = self.view.backgroundColor;
            
            [textContainer addSubview:textView];
            [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTextMessageDetailView:)]];
            [[UIApplication sharedApplication].keyWindow addSubview:textContainer];
        }
            break;
        case MESSAGE_CONTENT_TYPE_SOUND: {
            if (self.isPlayingSound) {
                [self stopPlaySound];
            } else {
                [self playSound:item];
            }
        }
            break;
        case MESSAGE_CONTENT_TYPE_VIDEO:
        case MESSAGE_CONTENT_TYPE_IMAGE:
        {
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            browser.displayActionButton = YES;
            browser.displayNavArrows = NO;
            browser.displaySelectionButtons = NO;
            browser.alwaysShowControls = NO;
            browser.zoomPhotosToFill = YES;
            browser.enableGrid = YES;
            browser.startOnGrid = NO;
            browser.enableSwipeToDismiss = NO;
            browser.autoPlayOnAppear = NO;
            NSUInteger index = [self.imageVideoItems indexOfObject:item];
            if(index >= self.imageVideoItems.count) {
                index = 0;
            }
            [browser setCurrentPhotoIndex:index];
            [self.navigationController pushViewController:browser animated:YES];
        }
            break;
        case MESSAGE_CONTENT_TYPE_LOCATION:
        {
            WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)[self.selectedCell.favoriteItem toMessage].content;
            WFCULocationViewController *vc = [[WFCULocationViewController alloc] initWithLocationPoint:[[WFCULocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case MESSAGE_CONTENT_TYPE_LINK:
        {
            WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
            bvc.url = self.selectedCell.favoriteItem.url;
            [self.navigationController pushViewController:bvc animated:YES];
        }
            break;
        case MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE:
        {
            WFCUCompositeMessageViewController *vc = [[WFCUCompositeMessageViewController alloc] init];
            vc.message = [self.selectedCell.favoriteItem toMessage];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case MESSAGE_CONTENT_TYPE_FILE:
        {
            WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
            bvc.url = self.selectedCell.favoriteItem.url;
            [self.navigationController pushViewController:bvc animated:YES];
        }
            break;
        default:
            break;
    }
}

- (void)setIsPlayingSound:(BOOL)isPlayingSound {
    _isPlayingSound = isPlayingSound;
    [self.tableView reloadData];
}

- (void)didTapTextMessageDetailView:(id)sender {
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
        [gesture.view.superview removeFromSuperview];
    }
    NSLog(@"close windows");
}

- (void)onTapCell:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath) {
            self.selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
            WFCUFavoriteItem *item = self.selectedCell.favoriteItem;
            [self showItem:item];
        }
    }
}

- (void)onLongTapCell:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath) {
            UIMenuController *menu = [UIMenuController sharedMenuController];

            UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"删除" action:@selector(performDelete:)];
            UIMenuItem *forwardItem = [[UIMenuItem alloc]initWithTitle:@"转发" action:@selector(performForward:)];
            UIMenuItem *copyItem = [[UIMenuItem alloc]initWithTitle:@"拷贝" action:@selector(performCopy:)];

            self.selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (@available(iOS 13.0, *)) {
                [menu showMenuFromView:self.tableView rect:CGRectMake(point.x, point.y, 1, 1)];
            } else {
                [menu setTargetRect:CGRectMake(point.x, point.y, 1, 1) inView:self.tableView];
            }
            
            WFCUFavoriteItem *item = self.selectedCell.favoriteItem;
            
            NSMutableArray *items = [[NSMutableArray alloc] init];
            if (item.favType == MESSAGE_CONTENT_TYPE_TEXT) {
                [items addObject:copyItem];
            }
            [items addObject:deleteItem];
            [items addObject:forwardItem];
            
            [menu setMenuItems:items];
            [menu setMenuVisible:YES];
        }
    }
    
}

- (NSMutableArray<WFCUFavoriteItem *> *)imageVideoItems {
    NSMutableArray *is = [[NSMutableArray alloc] init];
    [self.items enumerateObjectsUsingBlock:^(WFCUFavoriteItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.favType == MESSAGE_CONTENT_TYPE_IMAGE || obj.favType == MESSAGE_CONTENT_TYPE_VIDEO) {
            [is addObject:obj];
        }
    }];
    return is;
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(performDelete:) || action == @selector(performForward:)) {
        return YES; //显示自定义的菜单项
    } else {
        if (action == @selector(performCopy:)) {
            if (self.selectedCell && self.selectedCell.favoriteItem.favType == MESSAGE_CONTENT_TYPE_TEXT) {
                return YES;
            }
        }
        return NO;
    }
    
    return NO;//[super canPerformAction:action withSender:sender];
}

-(void)performDelete:(UIMenuController *)sender {
    WFCUFavoriteItem *favItem = self.selectedCell.favoriteItem;
    
    [[AppService sharedAppService] removeFavoriteItem:favItem.favId success:^{
        
    } error:^(int error_code) {
        
    }];
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:self.selectedCell];
    [self.items removeObjectAtIndex:indexPath.section];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
    [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

-(void)performForward:(UIMenuController *)sender {
    WFCCMessage *message = [[WFCCMessage alloc] init];
    WFCUFavoriteItem *item = self.selectedCell.favoriteItem;
    message.content = [item toMessage].content;
    if (!message.content) {
        return;
    }
    
    WFCUForwardViewController *controller = [[WFCUForwardViewController alloc] init];
    controller.message = message;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

-(void)performCopy:(UIMenuController *)sender {
    if (self.selectedCell && self.selectedCell.favoriteItem.favType == MESSAGE_CONTENT_TYPE_TEXT) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.selectedCell.favoriteItem.title;
        [self.view makeToast:@"已拷贝" duration:1 position:CSToastPositionCenter];
    }
}

- (void)loadMoreData {
    if (!self.loading) {
        self.loading = YES;
    } else {
        return;
    }
    
    __weak typeof(self)ws = self;
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] init];
    activityView.center = CGPointMake(self.view.bounds.size.width/2, 10);
    [activityView startAnimating];
    [footer addSubview:activityView];
    self.tableView.tableFooterView =footer;
    
    [[AppService sharedAppService] getFavoriteItems:self.items.count ? [self.items lastObject].favId:0 count:100 success:^(NSArray<WFCUFavoriteItem *> * _Nonnull items, BOOL hasMore) {
        [ws.items addObjectsFromArray:items];
        [ws.tableView reloadData];
        ws.hasMore = hasMore;
        ws.tableView.tableFooterView = nil;
        ws.loading = NO;
    } error:^(int error_code) {
        ws.tableView.tableFooterView = nil;
        ws.loading = NO;
        ws.hasMore = NO;
    }];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.hasMore && ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [self loadMoreData];
    }
}

- (WFCFavoriteBaseCell *)cellOfFavType:(int)favType tableView:(UITableView *)tableView {
    WFCFavoriteBaseCell *cell = nil;
    if (favType == MESSAGE_CONTENT_TYPE_TEXT) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"text"];
        if (!cell) {
            cell = [[WFCFavoriteTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"text"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_IMAGE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"image"];
        if (!cell) {
            cell = [[WFCFavoriteImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"image"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_FILE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"file"];
        if (!cell) {
            cell = [[WFCFavoriteFileCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"file"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_LOCATION) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"location"];
        if (!cell) {
            cell = [[WFCFavoriteLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"location"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_SOUND) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"sound"];
        if (!cell) {
            cell = [[WFCFavoriteSoundCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"sound"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_VIDEO) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"video"];
        if (!cell) {
            cell = [[WFCFavoriteVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"video"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_LINK) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"link"];
        if (!cell) {
            cell = [[WFCFavoriteLinkCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"link"];
        }
    } else if(favType == MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"composite"];
        if (!cell) {
            cell = [[WFCFavoriteCompositeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"composite"];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"unknown"];
        if (!cell) {
            cell = [[WFCFavoriteUnknownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"unknown"];
        }
    }
    
    return cell;
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUFavoriteItem *favItem = self.items[indexPath.section];
    
    WFCFavoriteBaseCell *cell = [self cellOfFavType:favItem.favType tableView:tableView];
    cell.favoriteItem = favItem;
    if (favItem.favType == MESSAGE_CONTENT_TYPE_SOUND) {
        WFCFavoriteSoundCell *soundCell = (WFCFavoriteSoundCell *)cell;
        if (self.isPlayingSound && self.playingSoundItem == favItem) {
            soundCell.isPlaying = YES;
        } else {
            soundCell.isPlaying = NO;
        }
    }
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 10)];
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUFavoriteItem *favItem = self.items[indexPath.section];
    return [[[self cellOfFavType:favItem.favType tableView:tableView] class] heightOf:favItem];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCUFavoriteItem *favItem = self.items[indexPath.section];
        [[AppService sharedAppService] removeFavoriteItem:favItem.favId success:^{
            
        } error:^(int error_code) {
            
        }];
        
        [self.items removeObjectAtIndex:indexPath.section];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - MWPhotoBrowser
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.imageVideoItems.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    WFCUFavoriteItem *item = self.imageVideoItems[index];
    if(item.favType == MESSAGE_CONTENT_TYPE_IMAGE) {
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:item.url]];
        return photo;
    } else if(item.favType == MESSAGE_CONTENT_TYPE_VIDEO) {
        MWPhoto *photo = [MWPhoto videoWithURL:[NSURL URLWithString:item.url]];
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    WFCUFavoriteItem *item = self.imageVideoItems[index];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[item.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    NSString *thumbStr = dict[@"thumb"];
    NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:thumbData];
    
    BOOL video = NO;
    if(item.favType == MESSAGE_CONTENT_TYPE_VIDEO) {
        video = YES;
    }
    MWPhoto *photo = [MWPhoto photoWithImage:image];
    photo.isVideo = video;
    return photo;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopPlaySound];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    [self stopPlaySound];
}
@end
