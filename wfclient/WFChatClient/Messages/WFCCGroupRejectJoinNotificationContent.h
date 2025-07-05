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
 被禁言/取消禁言者ID列表
 */
@property (nonatomic, strong)NSDictionary<NSString *, NSNumber *> *rejectUser;
@end
