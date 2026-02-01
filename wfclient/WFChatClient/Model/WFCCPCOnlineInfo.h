//
//  WFCCPCOnlineInfo.h
//  WFChatClient
//
//  Created by Tom Lee on 2020/4/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 PC在线类型

 - PC_Online: PC客户端在线
 - Web_Online: Web客户端在线
 - WX_Online: WX小程序客户端在线
 - Pad_Online: Pad客户端在线
 */
typedef NS_ENUM(NSInteger, WFCCPCOnlineType) {
    PC_Online,
    Web_Online,
    WX_Online,
    Pad_Online
};


/**
PC在线信息
*/
@interface WFCCPCOnlineInfo : WFCCJsonSerializer

/**
从字符串构造PC在线信息

@param strInfo 字符串信息
@param type 在线类型
@return PC在线信息实例
*/
+ (instancetype)infoFromStr:(NSString *)strInfo withType:(WFCCPCOnlineType)type;

/**
在线类型
*/
@property(nonatomic, assign)WFCCPCOnlineType type;

/**
是否在线
*/
@property(nonatomic, assign)BOOL isOnline;

/**
平台类型
*/
@property(nonatomic, assign)int/*WFCCPlatformType*/ platform;

/**
客户端ID
*/
@property(nonatomic, strong)NSString *clientId;

/**
客户端名称
*/
@property(nonatomic, strong)NSString *clientName;

/**
时间戳
*/
@property(nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
