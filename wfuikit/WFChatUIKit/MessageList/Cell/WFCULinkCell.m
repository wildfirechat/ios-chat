//
//  WFCUCardCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCULinkCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>


@interface WFCULinkCell ()
@property (nonatomic, strong)UIImageView *thumbnailImageView;
@property (nonatomic, strong)UILabel *TitleLabel;
@property (nonatomic, strong)UILabel *contentLabel;
@end

@implementation WFCULinkCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCLinkMessageContent *content = (WFCCLinkMessageContent *)msgModel.message.content;
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 50)];
    
    CGFloat contentWidth = width - 56;
    NSString *contentTxt = content.url;
    if (content.contentDigest.length) {
        contentTxt = content.contentDigest;
    }
    
    CGSize contentSize = [WFCUUtilities getTextDrawingSize:contentTxt font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(contentWidth, 68)];
    
    CGFloat height = titleSize.height + 4 + MAX(contentSize.height, 56);
    
    return CGSizeMake(width, height);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCLinkMessageContent *content = (WFCCLinkMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 50)];
    
    CGFloat contentWidth = width - 56;
    NSString *contentTxt = content.url;
    if (content.contentDigest.length) {
        contentTxt = content.contentDigest;
    }
    
    CGSize contentSize = [WFCUUtilities getTextDrawingSize:contentTxt font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(contentWidth, 68)];
    
    
    self.TitleLabel.text = content.title;
    self.TitleLabel.frame = CGRectMake(0, 0, width, titleSize.height);
    self.contentLabel.text = contentTxt;
    self.contentLabel.frame = CGRectMake(0, titleSize.height+4, contentWidth, contentSize.height);
    [self.thumbnailImageView sd_setImageWithURL:[NSURL URLWithString:content.thumbnailUrl] placeholderImage:[UIImage imageNamed:@"default_link"]];
    self.thumbnailImageView.frame = CGRectMake(contentWidth+4, titleSize.height+4, 48, 48);
}

- (UIImageView *)thumbnailImageView {
    if (!_thumbnailImageView) {
        _thumbnailImageView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 48, 48)];
        [self.contentArea addSubview:_thumbnailImageView];
    }
    return _thumbnailImageView;
}

- (UILabel *)TitleLabel {
    if (!_TitleLabel) {
        CGRect bounds = self.contentArea.bounds;
        _TitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 10, bounds.size.width - 72 - 8, 24)];
        _TitleLabel.font = [UIFont systemFontOfSize:18];
        _TitleLabel.numberOfLines = 0;
        [self.contentArea addSubview:_TitleLabel];
    }
    return _TitleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        CGRect bounds = self.contentArea.bounds;
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 40, bounds.size.width - 72 - 8, 18)];
        _contentLabel.font = [UIFont systemFontOfSize:14];
        _contentLabel.textColor = [UIColor grayColor];
        _contentLabel.numberOfLines = 0;
        [self.contentArea addSubview:_contentLabel];
    }
    return _contentLabel;
}

@end
