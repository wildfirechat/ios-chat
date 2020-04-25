//
//  WFCCThingsData0Content.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 物联网 Qos 0数据。指设备以Qos 0类型发送数据，消息在服务不缓存，如果客户端不在线就直接抛弃，如果用户直接操控设备建议使用这种类型。
 */
@interface WFCCThingsData0Content : WFCCMessageContent
/**
 二进制数据内容
 */
@property (nonatomic, strong)NSData *data;
@end
