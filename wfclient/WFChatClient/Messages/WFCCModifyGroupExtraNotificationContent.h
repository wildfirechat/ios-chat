//
//  WFCCModifyGroupExtraNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 群成员修改群附加信息的通知消息
 */
@interface WFCCModifyGroupExtraNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者用户ID
 */
@property (nonatomic, strong)NSString *operateUser;

/**
 群成员附加信息
 */
@property (nonatomic, strong)NSString *groupExtra;
@end
