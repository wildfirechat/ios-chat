//
//  WFCCLinkMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 链接消息
 */
@interface WFCCLinkMessageContent : WFCCMessageContent

/**
 链接标题
 */
@property (nonatomic, strong)NSString *title;

/**
 内容摘要
 */
@property (nonatomic, strong)NSString *contentDigest;

/**
 链接地址
 */
@property (nonatomic, strong)NSString *url;

/**
 链接图片地址
 */
@property (nonatomic, strong)NSString *thumbnailUrl;

@end
