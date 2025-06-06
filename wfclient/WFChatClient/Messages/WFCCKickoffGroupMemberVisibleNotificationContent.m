//
//  WFCCKickoffGroupMemberNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCKickoffGroupMemberVisibleNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCKickoffGroupMemberVisibleNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.kickedMembers) {
        [dataDict setObject:self.kickedMembers forKey:@"ms"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    NSError *__error = nil;
    WFCCDictionary *dictionary = [WFCCDictionary fromData:payload.binaryContent error:&__error];
    if (!__error) {
        self.operateUser = dictionary[@"o"];
        self.kickedMembers = dictionary[@"ms"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER_VISIBLE_NOTIFICATION;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    NSString *formatMsg;
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.operateUser]) {
        formatMsg = @"你把";
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser inGroup:self.groupId refresh:NO];
        if (userInfo) {
            formatMsg = [NSString stringWithFormat:@"%@把", userInfo.readableName];
        } else {
            formatMsg = [NSString stringWithFormat:@"用户<%@>把", self.operateUser];
        }
    }
    
    int count = 0;
    if([self.kickedMembers containsObject:[WFCCNetworkService sharedInstance].userId]) {
        formatMsg = [formatMsg stringByAppendingString:@" 你"];
        count++;
    }
    for (NSString *member in self.kickedMembers) {
        if ([member isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            continue;
        } else {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:member inGroup:self.groupId refresh:NO];
            if (userInfo) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.readableName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@" 用户<%@>", member];
            }
            count++;
            if(count >= 4) {
                break;
            }
        }
    }
    if(self.kickedMembers.count > count) {
        formatMsg = [formatMsg stringByAppendingFormat:@" 等%ld名成员", self.kickedMembers.count];
    }
    formatMsg = [formatMsg stringByAppendingString:@"移出群聊"];
    return formatMsg;
}
@end
