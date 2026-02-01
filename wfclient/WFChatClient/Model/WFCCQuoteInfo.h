//
//  WFCCQuoteInfo.h
//  WFChatClient
//
//  Created by dali on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN
@class WFCCMessage;

/**
引用信息
*/
@interface WFCCQuoteInfo : WFCCJsonSerializer

/**
从消息构造引用信息

@param message 消息
@return 引用信息实例
*/
- (instancetype)initWithMessage:(WFCCMessage *)message;

/**
被引用消息的UID
*/
@property (nonatomic, assign)long long messageUid;

/**
被引用消息的发送者用户ID
*/
@property (nonatomic, strong)NSString *userId;

/**
被引用消息的发送者显示名称
*/
@property (nonatomic, strong)NSString *userDisplayName;

/**
被引用消息的摘要
*/
@property (nonatomic, strong)NSString *messageDigest;

/**
编码为字典

@return 字典
*/
- (NSDictionary *)encode;

/**
从字典解码

@param dictData 字典数据
*/
- (void)decode:(NSDictionary *)dictData;
@end

NS_ASSUME_NONNULL_END
