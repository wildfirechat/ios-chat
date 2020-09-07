//
//  WFCCTextMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 名片消息
 */
@interface WFCCCardMessageContent : WFCCMessageContent

/**
 构造方法

 @param userId 用户Id
 @return 名片消息
 */
+ (instancetype)cardWithUserId:(NSString *)userId;

/**
 用户ID
 */
@property (nonatomic, strong)NSString *userId;

/**
 用户号
 */
@property (nonatomic, strong)NSString *name;

/**
 用户昵称
 */
@property (nonatomic, strong)NSString *displayName;

/**
 用户头像
 */
@property (nonatomic, strong)NSString *portrait;
@end
