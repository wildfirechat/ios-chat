//
//  PluginBoardView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WFCUPluginBoardViewDelegate <NSObject>
- (void)onItemClicked:(NSUInteger)itemTag;
@end

@interface WFCUPluginBoardView : UIView
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withVoip withPtt:(BOOL)withPtt withPoll:(BOOL) withPoll withCollection:(BOOL)withCollection;

/// 面板高度。iPad 双栏下面板内联在会话栏里（不再当作键盘弹出），由调用方按这个高度摆放。
+ (CGFloat)boardHeight;
@end
