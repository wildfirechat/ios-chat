//
//  ArchivedMessage.h
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArchiveMessagePayload.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 归档消息模型
 * 对应备份服务 API 返回的消息结构
 */
@interface ArchivedMessage : NSObject

/// 消息唯一ID
@property (nonatomic, assign) int64_t mid;

/// 发送者用户ID
@property (nonatomic, strong) NSString *senderId;

/// 会话类型：0单聊, 1群组, 2聊天室, 3频道
@property (nonatomic, assign) int convType;

/// 会话目标（用户ID或群组ID）
@property (nonatomic, strong) NSString *convTarget;

/// 会话线路
@property (nonatomic, assign) int convLine;

/// 消息内容类型
@property (nonatomic, assign) int contentType;

/// 消息内容（已解析的 payload）
@property (nonatomic, strong, nullable) ArchiveMessagePayload *payload;

/// 可搜索文本
@property (nonatomic, strong, nullable) NSString *searchableKey;

/// 当前用户ID（用户视角）
@property (nonatomic, strong) NSString *userId;

/// 消息发送时间（ISO 8601格式，UTC时间）
@property (nonatomic, strong) NSString *messageDt;

/// 用户哈希值（用于分区）
@property (nonatomic, assign) int userHash;

#pragma mark - 便捷方法

/**
 * 从字典创建归档消息对象
 */
+ (nullable instancetype)fromDictionary:(NSDictionary *)dict;

/**
 * 获取本地时间格式的消息时间
 */
- (NSDate *)localMessageDate;

@end

NS_ASSUME_NONNULL_END
