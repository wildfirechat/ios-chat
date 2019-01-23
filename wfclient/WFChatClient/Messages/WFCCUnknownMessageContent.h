//
//  WFCCUnknownMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 未知消息。所有未注册的消息都会解析为为止消息，主要用于新旧版本兼容
 */
@interface WFCCUnknownMessageContent : WFCCMessageContent

/**
 消息类型
 */
@property (nonatomic, assign)NSInteger orignalType;

@end
