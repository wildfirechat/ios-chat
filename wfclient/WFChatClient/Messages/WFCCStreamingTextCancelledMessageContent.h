//
//  WFCCStreamingTextCancelledMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 流式文本取消消息（20）
 生成无产出/失败时由机器人发送，携带 streamId。
 客户端按 streamId 删除对应的生成中(14)/已生成(15)消息，取消消息自身透传不落库。
 */
@interface WFCCStreamingTextCancelledMessageContent : WFCCMessageContent
/**
 文本内容
 */
@property (nonatomic, strong)NSString *text;
/**
 流ID
 */
@property (nonatomic, strong)NSString *streamId;
@end
