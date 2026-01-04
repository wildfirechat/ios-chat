//
//  SelectableTextView.m
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "SelectableTextView.h"
#import <WebKit/WebKit.h>

@implementation SelectableTextView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    // 配置为看起来像 UILabel
    self.editable = NO;
    self.scrollEnabled = NO;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.backgroundColor = [UIColor clearColor];
    self.textColor = [UIColor blackColor];

    // 启用文本选择
    self.selectable = YES;
    self.userInteractionEnabled = YES;

    // 启用数据检测器（URL、电话号码等）
    self.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;

    // 设置代理以捕获链接点击
    self.delegate = self;

    // 注意：不在 setupView 中设置默认字体
    // 字体应该由创建者设置，以确保与计算高度时使用的字体一致
    // 如果这里设置字体，可能会覆盖外部设置的字体

    // 设置对齐方式
    self.textAlignment = NSTextAlignmentLeft;
}

- (void)setText:(NSString *)text {
    [super setText:text];

    // 检测并高亮 URL 和电话号码
    [self highlightLinksAndPhoneNumbers];
}

- (void)highlightLinksAndPhoneNumbers {
    // UITextView 的 dataDetectorTypes 会自动处理 URL 和电话号码
    // 我们只需要确保它们可以被点击

    // 如果需要自定义链接颜色，可以使用 attributedText
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.text];

    // 添加 URL 属性
    NSRange range = NSMakeRange(0, self.text.length);

    // 重要：保持当前字体，否则会丢失字体设置
    if (self.font) {
        [attributedString addAttribute:NSFontAttributeName value:self.font range:range];
    }

    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];

    // 检测 URL
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber error: nil];
    [detector enumerateMatchesInString:self.text options:0 range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        if (result.resultType == NSTextCheckingTypeLink) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:result.range];
            [attributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:result.range];
            // 链接也保持字体
            if (self.font) {
                [attributedString addAttribute:NSFontAttributeName value:self.font range:result.range];
            }
        } else if (result.resultType == NSTextCheckingTypePhoneNumber) {
            [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:result.range];
            // 电话号码也保持字体
            if (self.font) {
                [attributedString addAttribute:NSFontAttributeName value:self.font range:result.range];
            }
        }
    }];

    self.attributedText = attributedString;
}

#pragma mark - UITextViewDelegate (可选)

// 如果需要自定义链接点击行为，可以实现 UITextViewDelegate
// 但在这里我们使用 UIDataDetectorTypes 自动处理

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // 允许的选择和复制相关操作
    if (action == @selector(copy:) ||
        action == @selector(select:) ||
        action == @selector(selectAll:)) {
        return [super canPerformAction:action withSender:sender];
    }

    // 禁用粘贴、剪切和删除等编辑操作（保持只读）
    if (action == @selector(paste:) ||
        action == @selector(cut:) ||
        action == @selector(delete:) ||
        action == @selector(paste:from:) ||
        action == @selector(pasteAndGo:) ||
        action == @selector(pasteAndMatchStyle:) ||
        action == @selector(pasteAndMatchStyle:from:) ||
        action == @selector(_paste:) ||
        action == @selector(_pasteAndMatchStyle:) ||
        action == @selector(_pasteAndMatchStyle:from:)) {
        return NO;
    }

    return NO;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    // 拦截 URL 点击事件
    if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectUrl:)]) {
        [self.selectableTextViewDelegate didSelectUrl:URL.absoluteString];
        return NO; // 返回 NO 阻止默认行为（在应用内打开）
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    // iOS 10 以前的版本使用这个方法
    if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectUrl:)]) {
        [self.selectableTextViewDelegate didSelectUrl:URL.absoluteString];
        return NO;
    }
    return YES;
}

@end
