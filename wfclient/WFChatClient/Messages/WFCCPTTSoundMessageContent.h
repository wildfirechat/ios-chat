//
//  WFCCPTTSoundMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCSoundMessageContent.h"

/**
 语音消息
 */
@interface WFCCPTTSoundMessageContent : WFCCSoundMessageContent

/**
 构造方法

 @param wavPath 文件路径
 @param amrPath 转化为amr的存储路径
 @param duration 时间
 @return 语音消息
 */
+ (instancetype)soundMessageContentForWav:(NSString *)wavPath
                       destinationAmrPath:(NSString *)amrPath
                                 duration:(long)duration;


/**
 构造方法

 @param amrPath amr的存储路径
 @param duration 时间
 @return 语音消息
 */
+ (instancetype)soundMessageContentForAmr:(NSString *)amrPath
                                 duration:(long)duration;

@end
