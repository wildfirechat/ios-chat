//
//  WFCCConversation.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"
/**
 会话
 */
@interface WFCCDeliveryReport : WFCCJsonSerializer

/**
构造投递报告

@param userId 用户ID
@param timestamp 时间戳
@return 投递报告实例
*/
+(instancetype)delivered:(NSString *)userId
               timestamp:(long long)timestamp;

/**
用户ID
*/
@property (nonatomic, strong)NSString *userId;

/**
时间戳
*/
@property (nonatomic, assign)long long timestamp;

@end
