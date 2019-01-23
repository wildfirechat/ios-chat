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
@interface WFCCFileMessageContent : WFCCMediaMessageContent

/**
 构造方法

 @param filePath 文件路径
 @return 语音消息
 */
+ (instancetype)fileMessageContentFromPath:(NSString *)filePath;

/**
 文件名
 */
@property (nonatomic, strong)NSString *name;

/**
 文件名
 */
@property (nonatomic, assign)NSUInteger size;
@end
