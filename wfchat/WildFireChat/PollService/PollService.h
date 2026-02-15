//
//  PollService.h
//  WildFireChat
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatUIKit/WFChatUIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PollService : NSObject <WFCUPollService>

+ (PollService *)sharedService;

/// 设置投票服务基础 URL，例如：http://localhost:8081
@property (nonatomic, strong) NSString *baseUrl;

@end

NS_ASSUME_NONNULL_END
