//
//  WFCCConversationInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/29.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversation.h"
#import "WFCCMessage.h"
#import "WFCCUnreadCount.h"
#import "WFCCJsonSerializer.h"

/**
 会话信息
 */
@interface WFCCConversationInfo : WFCCJsonSerializer

/**
 会话
 */
@property (nonatomic, strong)WFCCConversation *conversation;

/**
 最后一条消息
 */
@property (nonatomic, strong)WFCCMessage *lastMessage;

/**
 草稿
 */
@property (nonatomic, strong)NSString *draft;

/**
 最后一条消息的时间戳
 */
@property (nonatomic, assign)long long timestamp;

/**
 未读数
 */
@property (nonatomic, strong)WFCCUnreadCount *unreadCount;

/**
 是否置顶
 */
@property (nonatomic, assign)int isTop;

/**
 是否设置了免打扰
 */
@property (nonatomic, assign)BOOL isSilent;

@end


