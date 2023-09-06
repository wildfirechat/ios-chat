//
//  WFCCRawMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"

/**
 Raw消息内容，消息没有经过decode，只包含payload.
 */
@interface WFCCRawMessageContent : WFCCMediaMessageContent

+ (instancetype)contentOfPayload:(WFCCMessagePayload *)payload;
/**
 消息Payload
 */
@property (nonatomic, strong)WFCCMessagePayload *payload;
@end
