//
//  WFCCFileRecord.h
//  WFChatClient
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversation.h"
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
文件记录
*/
@interface WFCCFileRecord : WFCCJsonSerializer

/**
所属会话
*/
@property (nonatomic, strong)WFCCConversation *conversation;

/**
消息UID
*/
@property (nonatomic, assign)long long messageUid;

/**
发送者用户ID
*/
@property (nonatomic, strong)NSString *userId;

/**
文件名
*/
@property (nonatomic, strong)NSString *name;

/**
文件URL
*/
@property (nonatomic, strong)NSString *url;

/**
文件大小
*/
@property (nonatomic, assign)int size;

/**
下载次数
*/
@property (nonatomic, assign)int downloadCount;

/**
时间戳
*/
@property (nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
