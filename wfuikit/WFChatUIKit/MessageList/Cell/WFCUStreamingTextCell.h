//
//  TextCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCell.h"

@class WFCUMarkdownLabel;

/**
 * 流式文本消息 Cell（支持 Markdown）
 * 用于显示 AI 生成中的文本内容
 */
@interface WFCUStreamingTextCell : WFCUMessageCell

@property (strong, nonatomic) WFCUMarkdownLabel *markdownLabel;
@property (strong, nonatomic) UIActivityIndicatorView *indicatorView;

@end
