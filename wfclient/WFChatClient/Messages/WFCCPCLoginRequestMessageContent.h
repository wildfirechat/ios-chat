//
//  WFCCPCLoginRequestMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"
#import "WFCCIMService.h"

/**
 PC登录请求消息
 */
@interface WFCCPCLoginRequestMessageContent : WFCCMessageContent

/**
 PC登录SessionID
 */
@property (nonatomic, strong)NSString *sessionId;

/**
 PC登录类型
 */
@property (nonatomic, assign)WFCCPlatformType platform;

@end
