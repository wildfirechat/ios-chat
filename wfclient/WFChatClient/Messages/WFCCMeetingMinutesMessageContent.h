//
//  WFCCMeetingMinutesMessageContent.h
//  WFChatClient
//
//  Created by Kimi on 2026/5/18.
//  Copyright © 2026年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 会议纪要消息
 */
@interface WFCCMeetingMinutesMessageContent : WFCCMessageContent

/**
 构造方法

 @param text 纪要文本
 @param title 会议标题
 @param meetingId 会议ID
 @return 会议纪要消息
 */
+ (instancetype)contentWith:(NSString *)text title:(NSString *)title meetingId:(NSString *)meetingId;

/**
 纪要文本
 */
@property (nonatomic, strong)NSString *text;

/**
 会议标题
 */
@property (nonatomic, strong)NSString *title;

/**
 会议ID
 */
@property (nonatomic, strong)NSString *meetingId;

@end
