//
//  WFCCPTTInviteMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2021/2/18.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 对讲邀请消息
 */
@interface WFCCPTTInviteMessageContent : WFCCMessageContent


/**
 CallId
 */
@property (nonatomic, strong)NSString *callId;

/**
 会议主持人
*/
@property (nonatomic, strong)NSString *host
;
/**
 会议标题
 */
@property (nonatomic, strong)NSString *title;

/**
 会议描述
 */
@property (nonatomic, strong)NSString *desc;

/*
 会议密码
*/
@property (nonatomic, strong)NSString *pin;
@end
