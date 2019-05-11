//
//  WFCCTransferGroupOwnerNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 转让群主的通知消息
 */
@interface WFCCTransferGroupOwnerNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者的ID
 */
@property (nonatomic, strong)NSString *operateUser;

/**
 新的群主ID
 */
@property (nonatomic, strong)NSString *owner;

@end
