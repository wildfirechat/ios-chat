//
//  WFCCConferenceInviteMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 电话总结消息
 */
@interface WFCCConferenceInviteMessageContent : WFCCMessageContent


/**
 CallId
 */
@property (nonatomic, strong)NSString *callId;

/**
 会议主持人
*/
@property (nonatomic, strong)NSString *host;
/**
 会议标题
 */
@property (nonatomic, strong)NSString *title;

/**
 会议描述
 */
@property (nonatomic, strong)NSString *desc;
/**
 会议开始时间
 */
@property (nonatomic, assign)long long startTime;

/*
 是否音频会议
 */
@property (nonatomic, assign, getter=isAudioOnly)BOOL audioOnly;

/*
 会议密码
*/
@property (nonatomic, strong)NSString *pin;

/*
 是否是会议观众
*/
@property (nonatomic, assign)BOOL audience;

/*
 是否是高级会议模式
*/
@property (nonatomic, assign)BOOL advanced;

@end
