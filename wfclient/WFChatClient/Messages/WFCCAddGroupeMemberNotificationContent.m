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
#import "WFCCUtilities.h"

@implementation WFCCAddGroupeMemberNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.invitor) {
        [dataDict setObject:self.invitor forKey:@"o"];
    }
    
    if (self.invitees) {
        [dataDict setObject:self.invitees forKey:@"ms"];
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
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.invitor = dictionary[@"o"];
        self.invitees = dictionary[@"ms"];
        self.groupId = dictionary[@"g"];
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

- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)getUserDisplayName:(NSString *)userId {
    return [WFCCUtilities getUserDisplayName:userId inGroup:self.groupId];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    NSString *formatMsg;
    NSMutableString *sourceTargetId = [[NSMutableString alloc] init];
    WFCCGroupMemberSourceType sourceType = [WFCCUtilities getGroupMemberSourceType:self.extra sourceTargetId:sourceTargetId];
    if(sourceType == GroupMemberSource_QrCode && [sourceTargetId length] && [self.invitees count] == 1) {
        return [NSString stringWithFormat:@"%@ 扫描了 %@ 分享的二维码加入了群聊", [self getUserDisplayName:[self.invitees objectAtIndex:0]], [self getUserDisplayName:sourceTargetId]];
    } else if(sourceType == GroupMemberSource_Card && [sourceTargetId length] && [self.invitees count] == 1) {
        return [NSString stringWithFormat:@"%@ 通过 %@ 分享的群名片加入了群聊", [self getUserDisplayName:[self.invitees objectAtIndex:0]], [self getUserDisplayName:sourceTargetId]];
    }
    
    if ([self.invitees count] == 1 && [[self.invitees objectAtIndex:0] isEqualToString:self.invitor]) {
        formatMsg = [NSString stringWithFormat:@"%@ 加入了群聊", [self getUserDisplayName:self.invitor]];
        return formatMsg;
    }
    
    formatMsg = [NSString stringWithFormat:@"%@邀请", [self getUserDisplayName:self.invitor]];
    
    int count = 0;
    if([self.invitees containsObject:[WFCCNetworkService sharedInstance].userId]) {
        formatMsg = [formatMsg stringByAppendingString:@" 你"];
        count++;
    }

    for (NSString *member in self.invitees) {
        if ([member isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            continue;
        } else {
            formatMsg = [formatMsg stringByAppendingFormat:@" %@", [self getUserDisplayName:member]];
            
            count++;
            if(count >= 4) {
                break;
            }
        }
    }
    
    if(self.invitees.count > count) {
        formatMsg = [formatMsg stringByAppendingFormat:@" 等%ld名成员", self.invitees.count];
    }
    formatMsg = [formatMsg stringByAppendingString:@"加入了群聊"];
    return formatMsg;
}
@end
