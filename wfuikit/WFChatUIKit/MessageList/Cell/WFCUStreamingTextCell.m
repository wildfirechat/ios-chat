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
#import "WFCUMarkdownLabel.h"
#import "WFCUConfigManager.h"

#define TEXT_LABEL_TOP_PADDING 3
#define TEXT_LABEL_BUTTOM_PADDING 5
#define INDICTATORVIEW_HEIGHT 18

@interface WFCUStreamingTextCell () <WFCUMarkdownLabelDelegate>

@end

@implementation WFCUStreamingTextCell

+ (UIFont *)defaultFont {
    return [UIFont systemFontOfSize:18];
}

+ (NSString *)cacheKeyForText:(NSString *)text viewWidth:(CGFloat)width generating:(BOOL)generating {
    // 使用文本内容+宽度+生成状态作为缓存键
    return [NSString stringWithFormat:@"%@_%.0f_%d", @(text.hash), width, generating];
}

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
    
    if (!text) {
        text = @"";
    }
    
    // 使用内容+宽度作为缓存键
    NSString *cacheKey = [self cacheKeyForText:text viewWidth:width generating:generating];
    NSDictionary *dict = [[WFCUConfigManager globalManager].cellSizeCache objectForKey:cacheKey];
    if (dict) {
        float cellWidth = [dict[@"width"] floatValue];
        float cellHeight = [dict[@"height"] floatValue];
        return CGSizeMake(cellWidth, cellHeight);
    }
    
    // 计算 Markdown 文本实际尺寸
    CGSize contentSize = [WFCUMarkdownLabel sizeForText:text maxWidth:width font:[self defaultFont]];
    
    CGSize size = contentSize;
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING;
    
    if(generating) {
        size.height += INDICTATORVIEW_HEIGHT;
    }
    
    // 缓存结果
    [[WFCUConfigManager globalManager].cellSizeCache setObject:@{
        @"width": @(size.width),
        @"height": @(size.height)
    } forKey:cacheKey];
    
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
        indicatorHeight = INDICTATORVIEW_HEIGHT;
    }
    
    self.markdownLabel.frame = CGRectMake(0, TEXT_LABEL_TOP_PADDING, frame.size.width, frame.size.height - TEXT_LABEL_TOP_PADDING - TEXT_LABEL_BUTTOM_PADDING - indicatorHeight);
    [self.markdownLabel setMarkdownText:text font:[WFCUStreamingTextCell defaultFont]];
    
    if(generating) {
        CGRect textRect = self.markdownLabel.frame;
        self.indicatorView.frame = CGRectMake(0, textRect.origin.y + textRect.size.height + 4, 12, 12);
        self.indicatorView.hidden = NO;
        [self.indicatorView startAnimating];
    } else {
        self.indicatorView.frame = CGRectZero;
        self.indicatorView.hidden = YES;
        [self.indicatorView stopAnimating];
    }
}

- (WFCUMarkdownLabel *)markdownLabel {
    if (!_markdownLabel) {
        _markdownLabel = [[WFCUMarkdownLabel alloc] init];
        _markdownLabel.markdownDelegate = self;
        _markdownLabel.backgroundColor = [UIColor clearColor];
        [self.contentArea addSubview:_markdownLabel];
    }
    return _markdownLabel;
}

- (UIActivityIndicatorView *)indicatorView {
    if(!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] init];
        [self.contentArea addSubview:_indicatorView];
    }
    return _indicatorView;
}

#pragma mark - WFCUMarkdownLabelDelegate

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectUrl:(NSString *)urlString {
    [self.delegate didSelectUrl:self withModel:self.model withUrl:urlString];
}

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectPhoneNumber:(NSString *)phoneNumberString {
    [self.delegate didSelectPhoneNumber:self withModel:self.model withPhoneNumber:phoneNumberString];
}

- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectEmail:(NSString *)emailString {
    // 邮件点击处理
}

- (void)markdownLabelDidLongPress:(WFCUMarkdownLabel *)label {
    [self.delegate didLongPressMessageCell:self withModel:self.model];
}

@end
