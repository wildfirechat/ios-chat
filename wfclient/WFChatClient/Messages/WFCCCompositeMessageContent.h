//
//  WFCCCompositeMessageContent.h
//  WFChatClient
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
@class WFCCMessage;

NS_ASSUME_NONNULL_BEGIN

/**
组合消息
*/
@interface WFCCCompositeMessageContent : WFCCMediaMessageContent

/**
标题
*/
@property (nonatomic, strong)NSString *title;

/**
包含的消息列表
*/
@property (nonatomic, strong)NSArray<WFCCMessage *> *messages;

/**
是否已加载
*/
@property(nonatomic, assign)BOOL loaded;
@end

NS_ASSUME_NONNULL_END
