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
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withVoip withPtt:(BOOL)withPtt;

/**
 * 刷新插件项，根据当前配置动态添加/移除收藏和投票按钮
 * 在 pollServiceProvider 或 collectionServiceProvider 可能在初始化后设置的情况下调用
 */
- (void)reloadItems;
@end
