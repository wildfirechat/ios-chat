//
//  TextCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUStreamingTextCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "AttributedLabel.h"

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5

#define INDICTATORVIEW_HEGITH 18
@interface WFCUStreamingTextCell () <AttributedLabelDelegate>

@end

@implementation WFCUStreamingTextCell
+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    NSString *text;
    BOOL generating = NO;
    if([msgModel.message.content isKindOfClass:[WFCCStreamingTextGeneratedMessageContent class]]) {
        WFCCStreamingTextGeneratedMessageContent *cnt = (WFCCStreamingTextGeneratedMessageContent *)msgModel.message.content;
        text = cnt.text;
    } else {
        WFCCStreamingTextGeneratingMessageContent *cnt = (WFCCStreamingTextGeneratingMessageContent *)msgModel.message.content;
        text = cnt.text;
        generating = YES;
    }
    
    CGSize size = [WFCUUtilities getTextDrawingSize:text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING;
    if (size.width < 40) {
        size.width += 4;
        if (size.width > 40) {
            size.width = 40;
        } else if (size.width < 24) {
            size.width = 24;
        }
    }
    if(generating) {
        size.height += INDICTATORVIEW_HEGITH;
    }
  return size;
}

- (void)setModel:(WFCUMessageModel *)model {
  [super setModel:model];
    
    NSString *text;
    BOOL generating = NO;
    if([model.message.content isKindOfClass:[WFCCStreamingTextGeneratedMessageContent class]]) {
        WFCCStreamingTextGeneratedMessageContent *cnt = (WFCCStreamingTextGeneratedMessageContent *)model.message.content;
        text = cnt.text;
    } else {
        WFCCStreamingTextGeneratingMessageContent *cnt = (WFCCStreamingTextGeneratingMessageContent *)model.message.content;
        text = cnt.text;
        generating = YES;
    }
    
    CGRect frame = self.contentArea.bounds;
    CGFloat indicatorHeight = 0;
    if(generating) {
        indicatorHeight = INDICTATORVIEW_HEGITH;
    }
  self.textLabel.frame = CGRectMake(0, TEXT_LABEL_TOP_PADDING, frame.size.width, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING - indicatorHeight);
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    [self.textLabel setText:text];
    if(generating) {
        CGRect textRect = self.textLabel.frame;
        self.indicatorView.frame = CGRectMake(0, textRect.origin.y + textRect.size.height + 4, 12, 12);
        self.indicatorView.hidden = NO;
        [self.indicatorView startAnimating];
    } else {
        self.indicatorView.frame = CGRectZero;
        self.indicatorView.hidden = YES;
        [self.indicatorView stopAnimating];
    }
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[AttributedLabel alloc] init];
        ((AttributedLabel*)_textLabel).attributedLabelDelegate = self;
        _textLabel.numberOfLines = 0;
        _textLabel.font = [UIFont systemFontOfSize:18];
        _textLabel.userInteractionEnabled = YES;
        [self.contentArea addSubview:_textLabel];
    }
    return _textLabel;
}

- (UIActivityIndicatorView *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        [self.contentArea addSubview:_indicatorView];
    }
    return _indicatorView;;
}
#pragma mark - AttributedLabelDelegate
- (void)didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}
- (void)didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}
@end
