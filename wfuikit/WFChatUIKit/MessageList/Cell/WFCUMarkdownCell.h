//
//  WFCUMarkdownCell.h
//  WFChat UIKit
//
//  Created by Kimi on 2025/3/8.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

@class WFCUMarkdownLabel;

/**
 * Markdown 消息 Cell（原生版本）
 * 使用 NSAttributedString 渲染 Markdown，性能更好
 */
@interface WFCUMarkdownCell : WFCUMessageCell

@property (strong, nonatomic) WFCUMarkdownLabel *markdownLabel;
@property (strong, nonatomic, nullable) UILabel *reactionLabel;

@end

NS_ASSUME_NONNULL_END
