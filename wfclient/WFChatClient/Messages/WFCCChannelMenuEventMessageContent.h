//
//  WFCCChannelMenuEventMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

@class WFCCChannelMenu;

/**
频道菜单事件消息
*/
@interface WFCCChannelMenuEventMessageContent : WFCCMessageContent

/**
触发的菜单项
*/
@property (nonatomic, strong)WFCCChannelMenu *menu;
@end
