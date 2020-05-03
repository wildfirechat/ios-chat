//
//  WFCCThingsDataContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 物联网数据
 */
@interface WFCCThingsDataContent : WFCCMessageContent
/**
 二进制数据内容
 */
@property (nonatomic, strong)NSData *data;
@end
