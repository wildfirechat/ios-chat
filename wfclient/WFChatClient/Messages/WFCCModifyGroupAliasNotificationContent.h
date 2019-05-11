//
//  WFCCModifyGroupAliasNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 群成员修改群昵称的通知消息
 */
@interface WFCCModifyGroupAliasNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 群成员ID
 */
@property (nonatomic, strong)NSString *operateUser;

/**
 群昵称
 */
@property (nonatomic, strong)NSString *alias;

@end
