//
//  WFCCConversationSearchInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversation.h"
#import "WFCCMessage.h"
#import "WFCCJsonSerializer.h"
/**
 会话搜索信息
 */
@interface WFCCConversationSearchInfo : WFCCJsonSerializer

/**
 会话
 */
@property (nonatomic, strong)WFCCConversation *conversation;

/**
 命中的消息
 */
@property (nonatomic, strong)WFCCMessage *marchedMessage;

/**
 命中数量
 */
@property (nonatomic, assign)int marchedCount;

/**
 搜索关键字
 */
@property (nonatomic, strong)NSString *keyword;
@end
