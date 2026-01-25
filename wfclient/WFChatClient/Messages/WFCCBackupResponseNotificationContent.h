//
//  WFCCBackupResponseNotificationContent.h
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 备份响应通知消息
 * PC端响应iOS端的备份请求
 */
@interface WFCCBackupResponseNotificationContent : WFCCNotificationMessageContent

/**
 * 是否同意备份请求
 */
@property (nonatomic, assign) BOOL approved;

/**
 * 服务器IP地址（同意时有效）
 */
@property (nonatomic, strong) NSString *serverIP;

/**
 * 服务器端口（同意时有效）
 */
@property (nonatomic, assign) NSInteger serverPort;

/**
 * 初始化拒绝消息
 */
+ (instancetype)rejectedResponse;

/**
 * 初始化同意消息
 */
+ (instancetype)approvedResponseWithIP:(NSString *)ip port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
