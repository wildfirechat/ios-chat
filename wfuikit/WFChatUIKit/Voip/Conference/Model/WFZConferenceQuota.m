//
//  WFZConferenceQuota.m
//  WFChatUIKit
//
//  Created by WildFireChat on 2025/4/11.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFZConferenceQuota.h"

@implementation WFZConferenceQuota

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    WFZConferenceQuota *quota = [[WFZConferenceQuota alloc] init];
    quota.totalQuota = [dict[@"totalQuota"] intValue];
    quota.usedMinutes = [dict[@"usedMinutes"] intValue];
    quota.remainingMinutes = [dict[@"remainingMinutes"] intValue];
    quota.unlimited = [dict[@"unlimited"] boolValue];
    quota.yearMonth = dict[@"yearMonth"];
    
    return quota;
}

@end
