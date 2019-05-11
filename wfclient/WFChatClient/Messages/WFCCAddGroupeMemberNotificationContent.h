//
//  WFCCAddGroupeMemberNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 群组加人的通知消息
 */
@interface WFCCAddGroupeMemberNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 邀请者ID
 */
@property (nonatomic, strong)NSString *invitor;

/**
 被邀请者ID列表
 */
@property (nonatomic, strong)NSArray<NSString *> *invitees;

@end
