//
//  WFCCGroupRejectJoinNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 群成员禁言的通知消息
 */
/**
拒绝加群通知消息
*/
@interface WFCCGroupRejectJoinNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operatorUserId;

/**
拒绝原因，key为用户ID，value为拒绝原因
 */
@property (nonatomic, strong)NSDictionary<NSString *, NSNumber *> *rejectUser;
@end
