//
//  WFCCSoundMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"

/**
 语音消息
 */
@interface WFCCSoundMessageContent : WFCCMediaMessageContent

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
 时间
 */
@property (nonatomic, assign)long duration;

/**
 获取语音消息的wav数据

 @return wav数据
 */
- (NSData *)getWavData;
@end
