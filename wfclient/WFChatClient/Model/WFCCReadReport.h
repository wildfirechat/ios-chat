//
//  WFCCConversation.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversation.h"
/**
 会话
 */
@interface WFCCReadReport : WFCCJsonSerializer

/**
构造已读回执

@param conversation 会话
@param userId 用户ID
@param timestamp 时间戳
@return 已读回执实例
*/
+(instancetype)readed:(WFCCConversation *)conversation
               userId:(NSString *)userId
            timestamp:(long long)timestamp;

/**
会话
*/
@property (nonatomic, strong)WFCCConversation *conversation;

/**
用户ID
*/
@property (nonatomic, strong)NSString *userId;

/**
时间戳
*/
@property (nonatomic, assign)long long timestamp;

@end
