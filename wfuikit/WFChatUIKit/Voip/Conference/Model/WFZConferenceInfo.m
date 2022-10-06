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
    if([dictionary[@"managers"] isKindOfClass:[NSArray class]]) {
        info.managers = dictionary[@"managers"];
    }
    info.startTime = [dictionary[@"startTime"] longLongValue];
    info.endTime = [dictionary[@"endTime"] longLongValue];
    info.audience = [dictionary[@"audience"] boolValue];
    info.advance = [dictionary[@"advance"] boolValue];
    info.allowTurnOnMic = [dictionary[@"allowSwitchMode"] boolValue];
    info.noJoinBeforeStart = [dictionary[@"noJoinBeforeStart"] boolValue];
    info.recording = [dictionary[@"recording"] boolValue];
    
    return info;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"conferenceId"] = self.conferenceId;
    dict[@"conferenceTitle"] = self.conferenceTitle;
    dict[@"password"] = self.password;
    dict[@"pin"] = self.pin;
    dict[@"owner"] = self.owner;
    dict[@"managers"] = self.managers;
    dict[@"startTime"] = @(self.startTime);
    dict[@"endTime"] = @(self.endTime);
    dict[@"audience"] = @(self.audience);
    dict[@"advance"] = @(self.advance);
    dict[@"allowSwitchMode"] = @(self.allowTurnOnMic);
    dict[@"noJoinBeforeStart"] = @(self.noJoinBeforeStart);
    dict[@"recording"] = @(self.recording);
    
    return dict;
}
@end
