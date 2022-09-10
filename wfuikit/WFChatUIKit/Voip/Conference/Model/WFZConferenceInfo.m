//
//  ConferenceInfo.m
//  WFZoom
//
//  Created by WF Chat on 2021/9/4.
//  Copyright © 2021年 WildFireChat. All rights reserved.
//

#import "WFZConferenceInfo.h"


@implementation WFZConferenceInfo
+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    WFZConferenceInfo *info = [[WFZConferenceInfo alloc] init];
    info.conferenceId = dictionary[@"conferenceId"];
    info.conferenceTitle = dictionary[@"conferenceTitle"];
    info.password = dictionary[@"password"];
    if([info.password isKindOfClass:[NSNull class]])
        info.password = nil;
    info.pin = dictionary[@"pin"];
    info.owner = dictionary[@"owner"];
    info.startTime = [dictionary[@"startTime"] longLongValue];
    info.endTime = [dictionary[@"endTime"] longLongValue];
    info.audience = [dictionary[@"audience"] boolValue];
    info.advance = [dictionary[@"advance"] boolValue];
    info.allowSwitchMode = [dictionary[@"allowSwitchMode"] boolValue];
    info.noJoinBeforeStart = [dictionary[@"noJoinBeforeStart"] boolValue];
    
    return info;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"conferenceId"] = self.conferenceId;
    dict[@"conferenceTitle"] = self.conferenceTitle;
    dict[@"password"] = self.password;
    dict[@"pin"] = self.pin;
    dict[@"owner"] = self.owner;
    dict[@"startTime"] = @(self.startTime);
    dict[@"endTime"] = @(self.endTime);
    dict[@"audience"] = @(self.audience);
    dict[@"advance"] = @(self.advance);
    dict[@"allowSwitchMode"] = @(self.allowSwitchMode);
    dict[@"noJoinBeforeStart"] = @(self.noJoinBeforeStart);
    
    return dict;
}
@end
