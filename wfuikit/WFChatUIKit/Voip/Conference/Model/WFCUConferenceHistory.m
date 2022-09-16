//
//  WFCUConferenceHistory.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/16.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUConferenceHistory.h"
#import "WFZConferenceInfo.h"
@implementation WFCUConferenceHistory
+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    WFCUConferenceHistory *history = [[WFCUConferenceHistory alloc] init];
    history.timestamp = [dictionary[@"timestamp"] longLongValue];
    history.duration = [dictionary[@"duration"] intValue];
    history.conferenceInfo = [WFZConferenceInfo fromDictionary:dictionary[@"info"]];
    return history;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"info"] = [self.conferenceInfo toDictionary];
    dict[@"timestamp"] = @(self.timestamp);
    dict[@"duration"] = @(self.duration);
    return dict;
}
@end
