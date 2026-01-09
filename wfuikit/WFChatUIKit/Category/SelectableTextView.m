//
//  SelectableTextView.m
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "SelectableTextView.h"
#import <WebKit/WebKit.h>

@interface SelectableTextView () <UIGestureRecognizerDelegate>
@end

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

    // 启用数据检测器（URL、电话号码、地址等）
    // 注意：不包含 UIDataDetectorTypeAddress，因为地址检测会有误报
    self.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;

    // 设置代理以捕获链接点击
    self.delegate = self;

    // 添加长按手势识别器，用于触发 cell 的菜单
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.delegate = self;
    [self addGestureRecognizer:longPress];

    // 添加点击手势识别器，用于检测邮箱地址
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];

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
    // 我们还需要手动检测邮箱地址

    // 如果需要自定义链接颜色，可以使用 attributedText
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.text];

    // 添加 URL 属性
    NSRange range = NSMakeRange(0, self.text.length);

    // 重要：保持当前字体，否则会丢失字体设置
    if (self.font) {
        [attributedString addAttribute:NSFontAttributeName value:self.font range:range];
    }

    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range];

    // 检测 URL、电话号码和邮箱
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

    // 手动检测邮箱地址（使用正则表达式）
    NSString *emailPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:emailPattern options:0 error:nil];
    [emailRegex enumerateMatchesInString:self.text options:0 range:range usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:result.range];
        [attributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:result.range];
        // 邮箱也保持字体
        if (self.font) {
            [attributedString addAttribute:NSFontAttributeName value:self.font range:result.range];
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
    NSString *urlString = URL.absoluteString;

    // 检查是否是电话号码链接（tel:）
    if ([urlString hasPrefix:@"tel:"]) {
        NSString *phoneNumber = [urlString substringFromIndex:4];
        if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
            [self.selectableTextViewDelegate didSelectPhoneNumber:phoneNumber];
            return NO; // 阻止默认行为
        }
    } else if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectUrl:)]) {
        [self.selectableTextViewDelegate didSelectUrl:urlString];
        return NO; // 阻止默认行为（在应用内打开）
    }

    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    // iOS 10 以前的版本使用这个方法
    NSString *urlString = URL.absoluteString;

    // 检查是否是电话号码链接（tel:）
    if ([urlString hasPrefix:@"tel:"]) {
        NSString *phoneNumber = [urlString substringFromIndex:4];
        if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
            [self.selectableTextViewDelegate didSelectPhoneNumber:phoneNumber];
            return NO;
        }
    } else if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectUrl:)]) {
        [self.selectableTextViewDelegate didSelectUrl:urlString];
        return NO;
    }

    return YES;
}

#pragma mark - Tap Gesture (用于检测邮箱点击)

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // 获取点击位置
        CGPoint point = [gestureRecognizer locationInView:self];

        // 获取点击位置的字符索引
        UITextPosition *position = [self closestPositionToPoint:point];
        if (!position) {
            return;
        }

        NSInteger offset = [self offsetFromPosition:self.beginningOfDocument toPosition:position];

        // 检测是否点击了邮箱地址
        NSString *emailPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
        NSRegularExpression *emailRegex = [NSRegularExpression regularExpressionWithPattern:emailPattern options:0 error:nil];
        NSRange searchRange = NSMakeRange(0, self.text.length);

        [emailRegex enumerateMatchesInString:self.text options:0 range:searchRange usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (offset >= result.range.location && offset < NSMaxRange(result.range)) {
                // 点击了邮箱地址
                NSString *email = [self.text substringWithRange:result.range];
                if ([self.selectableTextViewDelegate respondsToSelector:@selector(didSelectEmail:)]) {
                    [self.selectableTextViewDelegate didSelectEmail:email];
                }
                *stop = YES;
            }
        }];
    }
}

#pragma mark - Long Press Gesture

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // 延迟一小段时间，检查是否触发了文本选择
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 检查当前是否有选中的文本
//            if (self.selectedTextRange == nil || [self offsetFromPosition:self.selectedTextRange.start toPosition:self.selectedTextRange.end] == 0) {
                // 没有选中文本，说明用户是想操作消息，而不是选择文本
                if ([self.selectableTextViewDelegate respondsToSelector:@selector(didLongPressTextView:)]) {
                    [self.selectableTextViewDelegate didLongPressTextView:self];
                }
//            }
            // 如果有选中文本，说明用户是想复制文本，不触发消息菜单
        });
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 允许长按手势和 UITextView 的内置手势同时识别
    // 这样既可以触发文本选择，也可以触发 cell 的菜单
    return YES;
}

@end
