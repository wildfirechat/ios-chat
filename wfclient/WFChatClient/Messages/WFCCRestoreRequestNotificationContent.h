//
//  WFCCRestoreRequestNotificationContent.h
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 恢复请求通知消息
 * iOS端请求PC端提供恢复备份列表
 */
@interface WFCCRestoreRequestNotificationContent : WFCCNotificationMessageContent

/**
 * 请求时间戳
 */
@property (nonatomic, assign) long long timestamp;

/**
 * 创建恢复请求消息
 */
- (instancetype)initWithTimestamp:(long long)timestamp;

@end

NS_ASSUME_NONNULL_END
