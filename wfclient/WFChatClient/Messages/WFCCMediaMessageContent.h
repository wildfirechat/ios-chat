//
//  WFCCMediaMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 媒体消息
 */
@interface WFCCMediaMessageContent : WFCCMessageContent

/**
 媒体内容的本地存储路径
 */
@property (nonatomic, strong)NSString *localPath;

/**
 媒体内容的服务器路径
 */
@property (nonatomic, strong)NSString *remoteUrl;
@end
