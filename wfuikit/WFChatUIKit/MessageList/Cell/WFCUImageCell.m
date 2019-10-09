//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUImageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"

@interface WFCUImageCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@end

@implementation WFCUImageCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)msgModel.message.content;
    CGSize size = CGSizeMake(120, 120);
    if(imgContent.thumbnail) {
        size = imgContent.thumbnail.size;
    } else {
        size = [WFCCUtilities imageScaleSize:imgContent.size targetSize:CGSizeMake(120, 120) thumbnailPoint:nil];
    }
    
    
    if (size.height > width || size.width > width) {
        float scale = MIN(width/size.height, width/size.width);
        size = CGSizeMake(size.width * scale, size.height * scale);
    }
    return size;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCImageMessageContent *imgContent = (WFCCImageMessageContent *)model.message.content;
    self.thumbnailView.frame = self.bubbleView.bounds;
    if (!imgContent.thumbnail && imgContent.thumbParameter) {
        [self.thumbnailView sd_setImageWithURL:[NSURL URLWithString:[[NSString stringWithFormat:@"%@?%@", imgContent.remoteUrl, imgContent.thumbParameter] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    } else {
        self.thumbnailView.image = imgContent.thumbnail;
    }
}

- (UIImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[UIImageView alloc] init];
        [self.bubbleView addSubview:_thumbnailView];
    }
    return _thumbnailView;
}

- (void)setMaskImage:(UIImage *)maskImage{
    [super setMaskImage:maskImage];
    if (_shadowMaskView) {
        [_shadowMaskView removeFromSuperview];
    }
    _shadowMaskView = [[UIImageView alloc] initWithImage:maskImage];
    
    CGRect frame = CGRectMake(self.bubbleView.frame.origin.x - 1, self.bubbleView.frame.origin.y - 1, self.bubbleView.frame.size.width + 2, self.bubbleView.frame.size.height + 2);
    _shadowMaskView.frame = frame;
    [self.contentView addSubview:_shadowMaskView];
    [self.contentView bringSubviewToFront:self.bubbleView];
    
}

@end
