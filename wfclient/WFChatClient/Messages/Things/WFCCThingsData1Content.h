//
//  WFCCThingsData1Content.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 物联网 Qos 1数据。指设备以Qos 1类型发送数据，消息在服务缓存，如果客户端上线会把所有缓存的消息发送过来，注意如果是用户直接控制设备不要用这种消息，一般是用在服务器接收处理的。
 */
@interface WFCCThingsData1Content : WFCCMessageContent
/**
 二进制数据内容
 */
@property (nonatomic, strong)NSData *data;
@end
