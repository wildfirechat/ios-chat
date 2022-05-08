//
//  WFCCMultiCallOngoingMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 通话正在进行消息
 */
@interface WFCCMultiCallOngoingMessageContent : WFCCMessageContent
@property (nonatomic, strong)NSString *callId;
@property (nonatomic, strong)NSString *initiator;
@property (nonatomic, assign)BOOL audioOnly;
@property (nonatomic, strong)NSArray<NSString *> *targetIds;

@end
