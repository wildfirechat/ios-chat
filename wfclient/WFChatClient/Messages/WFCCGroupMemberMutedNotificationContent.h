//
//  WFCCCreateGroupNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 建群的通知消息
 */
@interface WFCCGroupMemberMutedNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operatorId;

/**
 操作类型，1禁言，0取消禁言
 */
@property (nonatomic, strong)NSString *type;

/**
 Member ID
 */
@property (nonatomic, strong)NSArray<NSString *> *memberIds;
@end
