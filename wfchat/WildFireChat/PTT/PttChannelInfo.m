//
//  PttChannelInfo.m
//  WildFireChat
//
//  Created by Tom Lee on 2021/10/1.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import "PttChannelInfo.h"

@implementation PttChannelInfo
+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    PttChannelInfo *info = [[PttChannelInfo alloc] init];
    info.channelId = dictionary[@"channelId"];
    info.channelTitle = dictionary[@"channelTitle"];
    info.channelDesc = dictionary[@"channelDesc"];
    info.password = dictionary[@"password"];
    if([info.password isKindOfClass:[NSNull class]])
        info.password = nil;
    info.pin = dictionary[@"pin"];
    info.owner = dictionary[@"owner"];
    info.open = [dictionary[@"open"] boolValue];
    return info;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"channelId"] = self.channelId;
    dict[@"channelTitle"] = self.channelTitle;
    dict[@"channelDesc"] = self.channelDesc;
    dict[@"password"] = self.password;
    dict[@"pin"] = self.pin;
    dict[@"owner"] = self.owner;
    dict[@"open"] = @(self.open);
    
    return dict;
}
@end
