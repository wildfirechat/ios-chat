//
//  WFCCNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"


@class WFCCMessage;
/**
 通知消息的协议
 */
@protocol WFCCNotificationMessageContent <WFCCMessageContent>

/**
 获取通知的提示内容

 @return 提示内容
 */
- (NSString *)formatNotification:(WFCCMessage *)message;
@end

/**
 通知消息
 */
@interface WFCCNotificationMessageContent : WFCCMessageContent <WFCCNotificationMessageContent>

@end
