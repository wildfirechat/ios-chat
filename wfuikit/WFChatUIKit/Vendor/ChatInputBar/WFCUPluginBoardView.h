//
//  PluginBoardView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

//Agent/AI 会话设置面板在"+"插件板的 item tag
#define WFCU_PLUGIN_TAG_AGENT_AGENT 11

@protocol WFCUPluginBoardViewDelegate <NSObject>
- (void)onItemClicked:(NSUInteger)itemTag;
@end

@interface WFCUPluginBoardView : UIView
// AI 不在线时 "AI 会话设置" 入口置灰禁用（由 ChatInputBar 创建时按群主在线状态设置）
@property (nonatomic, assign)BOOL agentDisabled;
- (instancetype)initWithDelegate:(id<WFCUPluginBoardViewDelegate>)delegate withVoip:(BOOL)withVoip withPtt:(BOOL)withPtt withPoll:(BOOL)withPoll withCollection:(BOOL)withCollection withAgent:(BOOL)withAgent;
@end
