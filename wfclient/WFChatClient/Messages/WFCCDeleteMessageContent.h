//
//  WFCCDeleteMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 文本消息
 */
@interface WFCCDeleteMessageContent : WFCCMessageContent

/**
 被删除消息的Uid
 */
@property (nonatomic, assign)long long messageUid;

/**
 撤回用户Id
 */
@property (nonatomic, strong)NSString *operatorId;

/**
被删除消息的发送者用户Id
*/
@property (nonatomic, strong)NSString *originalSender;

/**
删除消息的内容类型
*/
@property (nonatomic, assign)int originalContentType;

/**
删除消息的可搜索内容类型
*/
@property (nonatomic, strong)NSString *originalSearchableContent;

/**
删除消息的内容
*/
@property (nonatomic, strong)NSString *originalContent;

/**
删除消息的Extra内容
*/
@property (nonatomic, strong)NSString *originalExtra;

/**
删除消息的时间戳
*/
@property (nonatomic, assign)long long originalMessageTimestamp;
@end
