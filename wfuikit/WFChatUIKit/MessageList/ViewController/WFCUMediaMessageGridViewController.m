//
//  WFCUMediaMessageGridViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/7/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUMediaMessageGridViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "MediaMessageGridViewCell.h"
#import "SDPhotoBrowser.h"
#import "WFCUBrowserViewController.h"
#import "WFCUMediaMessageDownloader.h"
#import "VideoPlayerKit.h"

@interface WFCUMediaMessageGridViewController () <UICollectionViewDataSource, UICollectionViewDelegate, SDPhotoBrowserDelegate>
@property(nonatomic, strong)UICollectionView *collectionView;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *mediaMessages;
@property(nonatomic, strong)WFCCMessage *selectedMsg;
@property(nonatomic, assign)BOOL hasMore;


@property(nonatomic, strong)VideoPlayerKit *videoPlayerViewController;
@end

@implementation WFCUMediaMessageGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc]init];
    CGFloat edgeInset = 5;
    int countInLine = 4;
    flowLayout.sectionInset = UIEdgeInsetsMake(edgeInset, edgeInset, edgeInset, edgeInset);
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    width = width/countInLine - edgeInset - edgeInset;
    flowLayout.itemSize = CGSizeMake(width, width);
    
    self.hasMore = YES;
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[MediaMessageGridViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    [self.view addSubview:self.collectionView];
    
    [self loadMediaMessages];
    [self.collectionView reloadData];
}

- (void)loadMediaMessages {
    self.mediaMessages = [[[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_FILE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:0 count:40 withUser:nil] mutableCopy];
    if (self.mediaMessages.count < 40) {
        self.hasMore = false;
    }
}
- (void)loadMoreMessage {
    NSMutableArray<WFCCMessage *> *moreMessages = [[[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:@[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_FILE), @(MESSAGE_CONTENT_TYPE_VIDEO)] from:self.mediaMessages.lastObject.messageId count:20 withUser:nil] mutableCopy];
    if (moreMessages.count < 20) {
        self.hasMore = false;
    }
    [self.mediaMessages addObjectsFromArray:moreMessages];
    [self.collectionView reloadData];
}

- (void)startPlayVideo:(WFCCVideoMessageContent *)videoMsg {
    NSURL *url = [NSURL URLWithString:videoMsg.remoteUrl];
    if (!self.videoPlayerViewController) {
        self.videoPlayerViewController = [VideoPlayerKit videoPlayerWithContainingView:self.view optionalTopView:nil hideTopViewWithControls:YES];
        self.videoPlayerViewController.allowPortraitFullscreen = YES;
    } else {
        [self.videoPlayerViewController.view removeFromSuperview];
    }
    
    [self.view addSubview:self.videoPlayerViewController.view];
    
    [self.videoPlayerViewController playVideoWithTitle:@" " URL:url videoID:nil shareURL:nil isStreaming:NO playInFullScreen:YES];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediaMessages.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MediaMessageGridViewCell *cell = (MediaMessageGridViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    WFCCMessage *msg = self.mediaMessages[indexPath.row];
    cell.mediaMessage = msg;
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedMsg = self.mediaMessages[indexPath.row];
    if ([self.selectedMsg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        SDPhotoBrowser *browser = [[SDPhotoBrowser alloc] init];
        browser.sourceImagesContainerView = self.view;
        browser.showAll = NO;
        browser.imageCount = 1;
        
        browser.currentImageIndex = 0;
        browser.delegate = self;
        [browser show]; // 展示图片浏览器
    } else if([self.selectedMsg.content isKindOfClass:[WFCCFileMessageContent class]]) {
        WFCCFileMessageContent *fileContent = (WFCCFileMessageContent *)self.selectedMsg.content;
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = fileContent.remoteUrl;
        [self.navigationController pushViewController:bvc animated:YES];
    } else if([self.selectedMsg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoMsg = (WFCCVideoMessageContent *)self.selectedMsg.content;
        if (self.selectedMsg.direction == MessageDirection_Receive && self.selectedMsg.status != Message_Status_Played) {
            [[WFCCIMService sharedWFCIMService] setMediaMessagePlayed:self.selectedMsg.messageId];
            
        }
        
        [self startPlayVideo:videoMsg];
    }
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (self.hasMore && ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        [self loadMoreMessage];
    }
}

#pragma mark - SDPhotoBrowserDelegate
- (UIImage *)photoBrowser:(SDPhotoBrowser *)browser placeholderImageForIndex:(NSInteger)index {
    WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)self.selectedMsg.content;
    return imgCnt.thumbnail;
}

- (NSURL *)photoBrowser:(SDPhotoBrowser *)browser highQualityImageURLForIndex:(NSInteger)index {
    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)self.selectedMsg.content;
    return [NSURL URLWithString:[imgContent.remoteUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}
- (void)photoBrowserDidDismiss:(SDPhotoBrowser *)browser {
    self.selectedMsg = nil;
}
@end
