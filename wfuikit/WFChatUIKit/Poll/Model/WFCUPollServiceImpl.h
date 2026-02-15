//
//  WFCUPollServiceImpl.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUPollService.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票服务默认实现类
 * 使用示例：
 *   WFCUPollServiceImpl *service = [[WFCUPollServiceImpl alloc] init];
 *   service.baseUrl = @"http://your-server:8088";
 *   [WFCUConfigManager globalManager].pollServiceProvider = service;
 */
@interface WFCUPollServiceImpl : NSObject <WFCUPollService>

/// 服务器基础URL，如 http://192.168.1.100:8088
@property (nonatomic, strong) NSString *baseUrl;

/// 获取当前用户的 authCode（用于认证）
@property (nonatomic, copy) NSString *(^authCodeProvider)(void);

@end

NS_ASSUME_NONNULL_END
