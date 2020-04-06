//
//  WFCCPCOnlineInfo.m
//  WFChatClient
//
//  Created by Tom Lee on 2020/4/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCPCOnlineInfo.h"


@implementation WFCCPCOnlineInfo
+ (instancetype)infoFromStr:(NSString *)strInfo withType:(WFCCPCOnlineType)type {
    WFCCPCOnlineInfo *info = [[WFCCPCOnlineInfo alloc] init];
    info.type = type;
    if (strInfo.length) {
        info.isOnline = YES;
        NSArray<NSString *> *parts = [strInfo componentsSeparatedByString:@"|"];
        if (parts.count >= 4) {
            info.timestamp = [parts[0] longLongValue];
            info.type = [parts[1] intValue];
            info.clientId = parts[2];
            info.clientName = parts[3];
        }
    } else {
        info.isOnline = NO;
    }
    
    return info;
}
@end
