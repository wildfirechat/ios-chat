//
//  WFCCAddGroupeMemberNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCAddGroupeMemberNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"


@implementation WFCCAddGroupeMemberNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.invitor) {
        [dataDict setObject:self.invitor forKey:@"o"];
    }
    if (self.invitees) {
        [dataDict setObject:self.invitees forKey:@"ms"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.invitor = dictionary[@"o"];
        self.invitees = dictionary[@"ms"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}



+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest {
    return [self formatNotification];
}

- (NSString *)formatNotification {
    NSString *formatMsg;
    if ([self.invitees count] == 1 && [[self.invitees objectAtIndex:0] isEqualToString:self.invitor]) {
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.invitor]) {
            formatMsg = @"你加入了群聊";
        } else {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.invitor refresh:NO];
            if (userInfo.displayName.length > 0) {
                formatMsg = [NSString stringWithFormat:@"%@加入了群聊", userInfo.displayName];
            } else {
                formatMsg = [NSString stringWithFormat:@"%@加入了群聊", self.invitor];
            }
        }
        return formatMsg;
    }
    
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.invitor]) {
        formatMsg = @"你邀请";
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.invitor refresh:NO];
        if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@邀请", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@邀请", self.invitor];
        }
    }
    
    for (NSString *member in self.invitees) {
        if ([member isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            formatMsg = [formatMsg stringByAppendingString:@" 你"];
        } else {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:member refresh:NO];
            if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@" %@", member];
            }
        }
    }
    formatMsg = [formatMsg stringByAppendingString:@"加入了群聊"];
    return formatMsg;
}
@end
