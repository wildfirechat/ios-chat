//
//  WFCCJoinCallRequestMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 加入通话请求消息
 */
@interface WFCCJoinCallRequestMessageContent : WFCCMessageContent
/**
通话ID
*/
@property (nonatomic, strong)NSString *callId;
/**
客户端ID
*/
@property (nonatomic, strong)NSString *clientId;
@end
