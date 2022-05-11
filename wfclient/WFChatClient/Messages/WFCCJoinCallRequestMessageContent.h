//
//  WFCCJoinCallRequestMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 通话正在进行消息
 */
@interface WFCCJoinCallRequestMessageContent : WFCCMessageContent
@property (nonatomic, strong)NSString *callId;
@property (nonatomic, strong)NSString *clientId;
@end
