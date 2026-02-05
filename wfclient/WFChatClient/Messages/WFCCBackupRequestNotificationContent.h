//
//  WFCCBackupRequestNotificationContent.h
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 备份请求通知消息
 * 当iOS端请求备份到PC端时发送此通知
 */
@interface WFCCBackupRequestNotificationContent : WFCCNotificationMessageContent

/**
 * 会话列数量
 */
@property (nonatomic, assign) long conversationCount;

/**
 * 消息总量
 */
@property (nonatomic, assign) long messageCount;

/**
 * 是否包含媒体文件
 */
@property (nonatomic, assign) BOOL includeMedia;

/**
 * 请求时间戳
 */
@property (nonatomic, assign) long long timestamp;

/**
 * 初始化方法
 */
- (instancetype)initWithConversations:(long)conversationCount
                         messageCount:(long)messageCount
                         includeMedia:(BOOL)includeMedia
                            timestamp:(long long)timestamp;

@end

NS_ASSUME_NONNULL_END
