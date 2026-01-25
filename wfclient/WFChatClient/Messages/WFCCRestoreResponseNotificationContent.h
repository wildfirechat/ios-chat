//
//  WFCCRestoreResponseNotificationContent.h
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 恢复响应通知消息
 * PC端响应iOS端的恢复请求
 */
@interface WFCCRestoreResponseNotificationContent : WFCCNotificationMessageContent

/**
 * 是否同意恢复
 */
@property (nonatomic, assign) BOOL approved;

/**
 * 服务器IP
 */
@property (nonatomic, copy) NSString *serverIP;

/**
 * 服务器端口
 */
@property (nonatomic, assign) NSInteger serverPort;

/**
 * 创建拒绝消息
 */
+ (instancetype)rejectedResponse;

/**
 * 创建同意消息
 */
+ (instancetype)approvedResponseWithIP:(NSString *)ip port:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
