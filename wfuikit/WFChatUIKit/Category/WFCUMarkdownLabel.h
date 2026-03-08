//
//  WFCUMarkdownLabel.h
//  WFChat UIKit
//
//  Created by Kimi on 2025/3/8.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUMarkdownLabel;

@protocol WFCUMarkdownLabelDelegate <NSObject>
@optional
- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectUrl:(NSString *)urlString;
- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectPhoneNumber:(NSString *)phoneNumberString;
- (void)markdownLabel:(WFCUMarkdownLabel *)label didSelectEmail:(NSString *)emailString;
- (void)markdownLabelDidLongPress:(WFCUMarkdownLabel *)label;
@end

/**
 * 原生 Markdown 标签（基于 UITextView）
 * 使用 NSAttributedString 渲染，性能更好，无 WebView 内存开销
 */
@interface WFCUMarkdownLabel : UITextView

@property(nonatomic, weak) id<WFCUMarkdownLabelDelegate> markdownDelegate;

- (void)setMarkdownText:(NSString *)markdownText;
- (void)setMarkdownText:(NSString *)markdownText font:(UIFont *)font;

+ (BOOL)containsMarkdown:(NSString *)text;
+ (CGFloat)heightForText:(NSString *)text width:(CGFloat)width font:(UIFont *)font;
+ (CGSize)sizeForText:(NSString *)text maxWidth:(CGFloat)maxWidth font:(UIFont *)font;

/**
 * 清理所有缓存（可在内存警告时调用）
 */
+ (void)clearCache;

@end

NS_ASSUME_NONNULL_END
