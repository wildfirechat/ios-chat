//
//  WFCCChannelMenuEventMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

@class WFCCChannelMenu;
@interface WFCCChannelMenuEventMessageContent : WFCCMessageContent
@property (nonatomic, strong)WFCCChannelMenu *menu;
@end
