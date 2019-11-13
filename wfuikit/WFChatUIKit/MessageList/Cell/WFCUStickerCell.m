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
    [super setModel:model];
    
    WFCCStickerMessageContent *stickerMsg = (WFCCStickerMessageContent *)model.message.content;
    __weak typeof(self) weakSelf = self;
    if (!stickerMsg.localPath.length) {
        model.mediaDownloading = YES;
        [[WFCUMediaMessageDownloader sharedDownloader] tryDownload:model.message success:^(long long messageUid, NSString *localPath) {
            if (messageUid == weakSelf.model.message.messageUid) {
                weakSelf.model.mediaDownloading = NO;
                stickerMsg.localPath = localPath;
                [weakSelf setModel:weakSelf.model];
            }
        } error:^(long long messageUid, int error_code) {
            if (messageUid == weakSelf.model.message.messageUid) {
                weakSelf.model.mediaDownloading = NO;
            }
        }];
    }
    
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
