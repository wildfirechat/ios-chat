//
//  WFCCNotificationMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
提示通知消息
 */
@interface WFCCTipNotificationContent : WFCCNotificationMessageContent

/**
提示文本
 */
@property (nonatomic, strong)NSString *tip;
@end
