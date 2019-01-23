//
//  WFCCConversation.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 会话类型

 - Single_Type: 单聊
 - Group_Type: 群组
 - Chatroom_Type: 聊天室
 */
typedef NS_ENUM(NSInteger, WFCCConversationType) {
    Single_Type,
    Group_Type,
    Chatroom_Type,
    Channel_Type,
} ;

/**
 会话
 */
@interface WFCCConversation : NSObject

/**
 构造方法

 @param type 会话类型
 @param target 目标会话ID
 @param line 默认传0
 @return 会话
 */
+(instancetype)conversationWithType:(WFCCConversationType)type
                             target:(NSString *)target
                               line:(int)line;

/**
 会话类型
 */
@property (nonatomic, assign)WFCCConversationType type;

/**
 目标会话ID，单聊为对方用户ID，群聊为群ID
 */
@property (nonatomic, strong)NSString *target;

/**
 默认为0
 */
@property (nonatomic, assign)int line;

@end
