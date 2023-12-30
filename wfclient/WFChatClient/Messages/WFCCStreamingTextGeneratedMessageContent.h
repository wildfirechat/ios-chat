//
//  WFCCStreamingTextGeneratedMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 富通知消息
 */
@interface WFCCStreamingTextGeneratedMessageContent : WFCCMessageContent
@property (nonatomic, strong)NSString *text;
@property (nonatomic, strong)NSString *streamId;
@end
