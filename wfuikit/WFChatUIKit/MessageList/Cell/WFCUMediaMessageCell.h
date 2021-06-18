//
//  MediaMessageCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCell.h"

@interface WFCUMediaMessageCell : WFCUMessageCell
/*
 当自定义媒体消息时，需要实现这个方法，返回进度条的父窗口来展示进度
 */
- (UIView *)getProgressParentView;
@end
