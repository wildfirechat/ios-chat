//
//  WFCCPCOnlineInfo.h
//  WFChatClient
//
//  Created by Tom Lee on 2020/4/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

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


@interface WFCCPCOnlineInfo : NSObject
+ (instancetype)infoFromStr:(NSString *)strInfo withType:(WFCCPCOnlineType)type;
@property(nonatomic, assign)WFCCPCOnlineType type;
@property(nonatomic, assign)BOOL isOnline;
@property(nonatomic, assign)int/*WFCCPlatformType*/ platform;
@property(nonatomic, strong)NSString *clientId;
@property(nonatomic, strong)NSString *clientName;
@property(nonatomic, assign)long long timestamp;
@end

NS_ASSUME_NONNULL_END
