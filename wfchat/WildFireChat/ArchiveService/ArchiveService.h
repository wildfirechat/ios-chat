//
//  ArchiveService.h
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatUIKit/WFChatUIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArchiveService : NSObject <WFCUArchiveService>

+ (ArchiveService *)sharedService;

/// 设置归档服务基础 URL，例如：http://localhost:8088
@property (nonatomic, strong) NSString *baseUrl;

@end

NS_ASSUME_NONNULL_END
