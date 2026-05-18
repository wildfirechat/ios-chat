//
//  WFCCTranscriptionMessageContent.h
//  WFChatClient
//
//  Created by Kimi on 2026/5/18.
//  Copyright © 2026年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 转换消息（透传消息）
 */
@interface WFCCTranscriptionMessageContent : WFCCMessageContent

/**
 构造方法

 @param transcriptionId 唯一标识
 @param meetingId 会议ID
 @param userId 用户ID
 @param timestamp 时间戳
 @param duration 时长
 @param content 内容
 @return 转换消息
 */
+ (instancetype)contentWithId:(long long)transcriptionId
                    meetingId:(NSString *)meetingId
                       userId:(NSString *)userId
                    timestamp:(long long)timestamp
                     duration:(long long)duration
                      content:(NSString *)content;

/**
 唯一标识
 */
@property (nonatomic, assign)long long transcriptionId;

/**
 会议ID
 */
@property (nonatomic, strong)NSString *meetingId;

/**
 用户ID
 */
@property (nonatomic, strong)NSString *userId;

/**
 时间戳
 */
@property (nonatomic, assign)long long timestamp;

/**
 时长
 */
@property (nonatomic, assign)long long duration;

/**
 内容
 */
@property (nonatomic, strong)NSString *content;

@end
