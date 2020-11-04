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


@interface WFCFavoriteTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)NSMutableArray<WFCUFavoriteItem *> *items;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL loading;

@property(nonatomic, strong)WFCFavoriteBaseCell *selectedCell;
@end

@implementation WFCFavoriteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    self.items = [[NSMutableArray alloc] init];
    
    [self loadMoreData];
    [self.tableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapCell:)]];
    [self.tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongTapCell:)]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)onTapCell:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint point = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath) {
            
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
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

-(void)performForward:(UIMenuController *)sender {
    WFCCMessage *message = [[WFCCMessage alloc] init];
    WFCUFavoriteItem *item = self.selectedCell.favoriteItem;
    message.content = [item toContent];
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
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}
@end
