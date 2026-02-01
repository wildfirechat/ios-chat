//
//  WFCCStreamingTextGeneratedMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
流式文本已生成消息
*/
@interface WFCCStreamingTextGeneratedMessageContent : WFCCMessageContent
/**
文本内容
*/
@property (nonatomic, strong)NSString *text;
/**
流ID
*/
@property (nonatomic, strong)NSString *streamId;
@end
