//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUStickerCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "YLImageView.h"
#import "YLGIFImage.h"
#import "WFCUMediaMessageDownloader.h"
@interface WFCUStickerCell ()

@end

@implementation WFCUStickerCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCStickerMessageContent *imgContent = (WFCCStickerMessageContent *)msgModel.message.content;
    CGSize size = imgContent.size;
    
    if (size.height > width || size.width > width) {
        float scale = MIN(width/size.height, width/size.width);
        size = CGSizeMake(size.width * scale, size.height * scale);
    }
    return size;
}

- (void)setModel:(WFCUMessageModel *)model {
    WFCCStickerMessageContent *stickerMsg = (WFCCStickerMessageContent *)model.message.content;
    __weak typeof(self) weakSelf = self;
    if (!stickerMsg.localPath.length) {
        model.mediaDownloading = YES;
        [[WFCUMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
            if (messageUid == model.message.messageUid) {
                model.mediaDownloading = NO;
                stickerMsg.localPath = localPath;
                [weakSelf setModel:model];
            }
        } error:^(long long messageUid, int error_code) {
            if (messageUid == model.message.messageUid || error_code == -2) {
                model.mediaDownloading = NO;
            }
            
        }];
    }
    [super setModel:model];
    
    self.thumbnailView.frame = self.bubbleView.bounds;
    if (stickerMsg.localPath.length) {
        self.thumbnailView.image = [YLGIFImage imageWithContentsOfFile:stickerMsg.localPath];
    } else {
        self.thumbnailView.image = nil;
    }
    self.bubbleView.image = nil;
}

- (UIImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[YLImageView alloc] init];
        [self.bubbleView addSubview:_thumbnailView];
    }
    return _thumbnailView;
}
@end
