//
//  WFCCConversation.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"
#import "WFCCProtocol.h"
/**
 会话类型

 - Single_Type: 单聊
 - Group_Type: 群组
 - Chatroom_Type: 聊天室
 - Channel_Type: 频道
 - Things_Type: 物联网
 - SecretChat_Type: 密聊
 */
typedef NS_ENUM(NSInteger, WFCCConversationType) {
    Single_Type,
    Group_Type,
    Chatroom_Type,
    Channel_Type,
    Things_Type,
    SecretChat_Type,
};

/**
 会话 line。可以扩展自己的line，100以内系统保留，可以扩展使用100-255值。WFCUPadPrimaryNavigationController

 - WFCCConversationLine_Default: 默认（普通消息）
 - WFCCConversationLine_Moments: 朋友圈
 - WFCCConversationLine_Agent: AI/Agent 会话
 */
typedef NS_ENUM(NSInteger, WFCCConversationLine) {
    WFCCConversationLine_Default = 0,
    WFCCConversationLine_Moments = 1,
    WFCCConversationLine_Agent = 2,
};

/**
 会话
 */
@interface WFCCConversation : WFCCJsonSerializer <NSCopying, WFCCDuplicatable>

/**
 构造方法

 @param type 会话类型
 @param target 目标会话ID
 @param line 会话 line，取值见 WFCCConversationLine，默认传 WFCCConversationLine_Default
 @return 会话
 */
+(instancetype)conversationWithType:(WFCCConversationType)type
                             target:(NSString *)target
                               line:(int)line;

/**
 构造方法
 
 @param target 目标会话ID
 @return 单聊会话
 */
+(instancetype)singleConversation:(NSString *)target;

/**
 构造方法
 
 @param target 目标会话ID
 @return 群组会话
 */
+(instancetype)groupConversation:(NSString *)target;

/**
 会话类型
 */
@property (nonatomic, assign)WFCCConversationType type;

/**
 目标会话ID，单聊为对方用户ID，群聊为群ID
 */
@property (nonatomic, strong)NSString *target;

/**
 会话 line，取值见 WFCCConversationLine，默认为 WFCCConversationLine_Default
 */
@property (nonatomic, assign)int line;

@end
