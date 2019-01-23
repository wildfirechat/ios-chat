//
//  ImageCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/2.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCULocationCell.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCULocationCell ()
@property(nonatomic, strong) UIImageView *shadowMaskView;
@property (nonatomic, strong)UIImageView *thumbnailView;
@property (nonatomic, strong)UILabel *titleLabel;
@end

@implementation WFCULocationCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCLocationMessageContent *imgContent = (WFCCLocationMessageContent *)msgModel.message.content;
    
    CGSize size = imgContent.thumbnail.size;
    
    if (size.height > width || size.width > width) {
        float scale = MIN(width/size.height, width/size.width);
        size = CGSizeMake(size.width * scale, size.height * scale);
    }
    return size;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCLocationMessageContent *imgContent = (WFCCLocationMessageContent *)model.message.content;
    self.thumbnailView.frame = self.bubbleView.bounds;
    self.thumbnailView.image = imgContent.thumbnail;
    self.titleLabel.text = imgContent.title;
}

- (UIImageView *)thumbnailView {
    if (!_thumbnailView) {
        _thumbnailView = [[UIImageView alloc] init];
        [self.bubbleView addSubview:_thumbnailView];
    }
    return _thumbnailView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bubbleView.frame.size.width, 20)];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor colorWithRed:0.7f green:0.7f blue:0.7f alpha:0.5f];
        [self.bubbleView addSubview:_titleLabel];
    }
    return _titleLabel;
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
