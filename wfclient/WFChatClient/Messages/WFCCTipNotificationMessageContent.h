//
//  WFCCNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 退群的通知消息
 */
@interface WFCCTipNotificationContent : WFCCNotificationMessageContent

/**
 退群成员的ID
 */
@property (nonatomic, strong)NSString *tip;
@end
