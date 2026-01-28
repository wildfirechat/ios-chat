//
//  WFCUCompositeMessageViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUCompositeMessageViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "WFCUCompositeBaseCell.h"
#import "WFCUCompositeTextCell.h"
#import <CommonCrypto/CommonCrypto.h>
#import "MBProgressHUD.h"
#import "WFCUBrowserViewController.h"
#import "WFCULocationViewController.h"
#import "WFCULocationPoint.h"
#import "WFCUImage.h"
#import <SDWebImage/SDWebImage.h>
#import "MWPhotoBrowser.h"
#import "WFCUImagePreviewViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Toast.h"


@interface WFCUCompositeMessageViewController () <UITableViewDelegate, UITableViewDataSource, MWPhotoBrowserDelegate, AVAudioPlayerDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *messages;
@property (nonatomic, strong)WFCCCompositeMessageContent *compositeContent;
@property (nonatomic, strong)NSMutableArray<WFCCMessage *> *currentImageMessages;
@property (nonatomic, strong)AVAudioPlayer *player;
@property (nonatomic, assign)long long playingMessageId;
@end

@implementation WFCUCompositeMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.messages = [[NSMutableArray alloc] initWithArray:self.compositeContent.messages];
    
    [self setupTableHeaderView];
    
    self.title = self.compositeContent.title;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    if (!self.compositeContent.loaded && self.compositeContent.remoteUrl) {
        [self downloadComositeContent];
    }
}
- (void)downloadComositeContent {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    [hud showAnimated:YES];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.compositeContent.remoteUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            if(data.length) {
                NSString *uuid = nil;
                if (self.message.messageId > 0) {
                    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
                    uuid = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
                    CFRelease(uuidObject);
                } else {
                    uuid = [self getMD5WithData:data];
                }
                NSString *path = [[WFCCUtilities getDocumentPathWithComponent:@"/COMPOSITE_MESSAGE"] stringByAppendingPathComponent:uuid];
                if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [data writeToFile:path atomically:YES];
                }
                
                WFCCCompositeMessageContent *content = self.compositeContent;
                content.localPath = path;
                self.message.content = content;
                if (self.message.messageId > 0) {
                    [[WFCCIMService sharedWFCIMService] updateMessage:self.message.messageId content:content];
                }
                self.messages = [[NSMutableArray alloc] initWithArray:self.compositeContent.messages];
                [self.tableView reloadData];
            } else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = WFCString(@"LoadFailure");
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            }
        });
    });
}
- (NSString *)getMD5WithData:(NSData *)data {
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, data.bytes, (uint32_t)data.length);
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &md5);
    NSMutableString *resultString = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
      [resultString appendFormat:@"%02x", result[i]];
    }
    return resultString;
}

- (WFCCCompositeMessageContent *)compositeContent {
    return (WFCCCompositeMessageContent *)self.message.content;
}

- (void)setupTableHeaderView {
#define HEADER_HEIGHT 30
#define HEADER_FONT_SIZE 16
#define HEADER_LINE_PADDING 16
    NSDate *from = [[NSDate alloc] initWithTimeIntervalSince1970:self.messages.firstObject.serverTime/1000];
    NSDate *to = [[NSDate alloc] initWithTimeIntervalSince1970:self.messages.lastObject.serverTime/1000];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    
    NSString *fromString = [dateFormatter stringFromDate:from];
    NSString *toString = [dateFormatter stringFromDate:to];
    
    CGFloat width = self.view.frame.size.width;
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, HEADER_HEIGHT)];
    NSString *timeString;
    if ([fromString isEqualToString:toString]) {
        timeString = fromString;
    } else {
        timeString = [NSString stringWithFormat:@"%@ 至 %@", fromString, toString];
    }
    CGSize size = [WFCUUtilities getTextDrawingSize:timeString font:[UIFont systemFontOfSize:HEADER_FONT_SIZE] constrainedSize:CGSizeMake(width, HEADER_HEIGHT)];
    
    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(HEADER_LINE_PADDING, HEADER_HEIGHT/2, (width-size.width)/2-HEADER_LINE_PADDING-HEADER_LINE_PADDING, 1)];
    leftLine.backgroundColor = [UIColor grayColor];
    [headerView addSubview:leftLine];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width-size.width)/2, (HEADER_HEIGHT-size.height)/2, size.width, size.height)];
    label.text = timeString;
    label.textColor = [UIColor grayColor];
    label.font = [UIFont systemFontOfSize:HEADER_FONT_SIZE];
    [headerView addSubview:label];
    
    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake((width+size.width)/2+HEADER_LINE_PADDING, HEADER_HEIGHT/2, (width-size.width)/2-HEADER_LINE_PADDING-HEADER_LINE_PADDING, 1)];
    rightLine.backgroundColor = [UIColor grayColor];
    [headerView addSubview:rightLine];
    
    self.tableView.tableHeaderView = headerView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *msg = self.messages[indexPath.row];
    WFCUCompositeBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([msg.content class])];
    if (!cell) {
        cell = [WFCUCompositeBaseCell cellOfMessage:msg];
    }
    
    if (indexPath.row == self.messages.count-1) {
        cell.lastMessage = YES;
    } else {
        cell.lastMessage = NO;
    }
    
    BOOL sameUser = NO;
    if (indexPath.row != 0) {
        WFCCMessage *premsg = self.messages[indexPath.row-1];
        if ([premsg.fromUser isEqualToString:msg.fromUser]) {
            sameUser = YES;
        }
    }
    cell.hiddenPortrait = sameUser;
    
    cell.message = msg;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *msg = self.messages[indexPath.row];
    WFCUCompositeBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([msg.content class])];
    if (!cell) {
        cell = [WFCUCompositeBaseCell cellOfMessage:msg];
    }

    return [cell.class heightForMessage:msg];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    WFCCMessage *msg = self.messages[indexPath.row];
    [self handleMessageTap:msg];
}

- (void)handleMessageTap:(WFCCMessage *)msg {
    if ([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        // 处理图片消息
        NSMutableArray<WFCCMessage *> *imageMsgs = [[NSMutableArray alloc] init];
        for (WFCCMessage *message in self.messages) {
            if ([message.content isKindOfClass:[WFCCImageMessageContent class]]) {
                [imageMsgs addObject:message];
            }
        }

        int i;
        for (i = 0; i < imageMsgs.count; i++) {
            if ([imageMsgs objectAtIndex:i].messageId == msg.messageId) {
                break;
            }
        }
        if (i == imageMsgs.count) {
            i = 0;
        }

        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = NO;
        browser.zoomPhotosToFill = NO;
        browser.enableGrid = YES;
        browser.startOnGrid = NO;
        browser.enableSwipeToDismiss = NO;
        browser.autoPlayOnAppear = NO;

        self.currentImageMessages = imageMsgs;
        [browser setCurrentPhotoIndex:i];
        [self.navigationController pushViewController:browser animated:YES];
    } else if([msg.content isKindOfClass:[WFCCTextMessageContent class]]) {
        // 处理文本消息 - 显示大文本
        WFCCTextMessageContent *textContent = (WFCCTextMessageContent *)msg.content;

        UIView *textContainer = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        textContainer.backgroundColor = self.view.backgroundColor;

        UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, [WFCUUtilities wf_navigationFullHeight], [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom])];
        textView.text = textContent.text;
        textView.textAlignment = NSTextAlignmentCenter;
        textView.font = [UIFont systemFontOfSize:28];
        textView.editable = NO;
        textView.backgroundColor = self.view.backgroundColor;

        [textContainer addSubview:textView];
        [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapTextMessageDetailView:)]];
        [[UIApplication sharedApplication].keyWindow addSubview:textContainer];
    } else if([msg.content isKindOfClass:[WFCCSoundMessageContent class]]) {
        // 处理语音消息 - 播放语音
        [self playVoiceMessage:msg];
    } else if([msg.content isKindOfClass:[WFCCLocationMessageContent class]]) {
        // 处理位置消息
        WFCCLocationMessageContent *locContent = (WFCCLocationMessageContent *)msg.content;
        WFCULocationViewController *vc = [[WFCULocationViewController alloc] initWithLocationPoint:[[WFCULocationPoint alloc] initWithCoordinate:locContent.coordinate andTitle:locContent.title]];
        [self.navigationController pushViewController:vc animated:YES];
    } else if ([msg.content isKindOfClass:[WFCCFileMessageContent class]]) {
        // 处理文件消息
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)msg.content;

        __weak typeof(self)ws = self;
        [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:msg.messageUid mediaType:Media_Type_FILE mediaPath:fileContent.remoteUrl success:^(NSString *authorizedUrl, NSString *backupUrl) {
            WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
            bvc.url = authorizedUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        } error:^(int error_code) {
            WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
            bvc.url = fileContent.remoteUrl;
            [ws.navigationController pushViewController:bvc animated:YES];
        }];
    } else if([msg.content isKindOfClass:[WFCCLinkMessageContent class]]) {
        // 处理链接消息
        WFCCLinkMessageContent *content = (WFCCLinkMessageContent *)msg.content;
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = content.url;
        [self.navigationController pushViewController:bvc animated:YES];
    }
}

#pragma mark - MWPhotoBrowser Delegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.currentImageMessages.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.currentImageMessages[index];
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:imgContent.remoteUrl]];
        return photo;
    }
    return nil;
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didTapTextMessageDetailView:(id)sender {
    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        UIGestureRecognizer *gesture = (UIGestureRecognizer *)sender;
        [gesture.view.superview removeFromSuperview];
    }
}

#pragma mark - Voice Message Play
- (void)playVoiceMessage:(WFCCMessage *)msg {
    if (self.playingMessageId == msg.messageId) {
        [self stopPlayer];
    } else {
        if (self.playingMessageId) {
            [self stopPlayer];
        }

        self.playingMessageId = msg.messageId;
        WFCCSoundMessageContent *soundContent = (WFCCSoundMessageContent *)msg.content;

        if (soundContent.localPath.length == 0 || ![WFCUUtilities isFileExist:soundContent.localPath]) {
            // 如果本地没有文件，先下载
            __weak typeof(self) weakSelf = self;
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.label.text = WFCString(@"Loading");

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:soundContent.remoteUrl]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    if (data) {
                        [weakSelf startPlayVoice:msg data:data];
                    } else {
                        [weakSelf.view makeToast:WFCString(@"LoadFailure") duration:1 position:CSToastPositionCenter];
                        weakSelf.playingMessageId = 0;
                    }
                });
            });
        } else {
            // 使用本地文件
            NSData *data = [NSData dataWithContentsOfFile:soundContent.localPath];
            [self startPlayVoice:msg data:data];
        }
    }
}

- (void)startPlayVoice:(WFCCMessage *)msg data:(NSData *)data {
    NSError *error = nil;
    NSData *wavData = [[WFCCIMService sharedWFCIMService] getWavData:data];

    self.player = [[AVAudioPlayer alloc] initWithData:wavData error:&error];
    if (error) {
        NSLog(@"Failed to play voice: %@", error.localizedDescription);
        self.playingMessageId = 0;
        return;
    }

    [self.player setDelegate:self];
    [self.player prepareToPlay];
    [self.player play];
}

- (void)stopPlayer {
    if (self.player) {
        [self.player stop];
        self.player = nil;
    }
    self.playingMessageId = 0;
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopPlayer];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopPlayer];
}

@end
