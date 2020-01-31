//
//  WFCCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupSetManagerNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCGroupSetManagerNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operatorId) {
        [dataDict setObject:self.operatorId forKey:@"o"];
    }
    if (self.type) {
        [dataDict setObject:self.type forKey:@"n"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    if (self.memberIds) {
        [dataDict setObject:self.memberIds forKey:@"ms"];
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
        self.operatorId = dictionary[@"o"];
        self.type = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
        self.memberIds = dictionary[@"ms"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_SET_MANAGER;
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
    NSString *from;
    NSString *targets;
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.operatorId]) {
        from = @"你";
    } else {
        WFCCUserInfo *fromUserInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operatorId inGroup:self.groupId refresh:NO];
        if (fromUserInfo.friendAlias.length > 0) {
            from = fromUserInfo.friendAlias;
        } else if(fromUserInfo.groupAlias.length > 0) {
            from = fromUserInfo.groupAlias;
        } else if (fromUserInfo.displayName.length > 0) {
            from = fromUserInfo.displayName;
        } else {
            from = [NSString stringWithFormat:@"用户<%@>", self.operatorId];
        }
    }
    
    for (NSString *memberId in self.memberIds) {
        NSString *target;
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:memberId]) {
            target = @"你";
        } else {
            WFCCUserInfo *memberUserInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:memberId inGroup:self.groupId refresh:NO];
            if (memberUserInfo.friendAlias.length > 0) {
                target = memberUserInfo.friendAlias;
            } else if(memberUserInfo.groupAlias.length > 0) {
                target = memberUserInfo.groupAlias;
            } else if (memberUserInfo.displayName.length > 0) {
                target = memberUserInfo.displayName;
            } else {
                target = [NSString stringWithFormat:@"用户<%@>", memberId];
            }
        }
        if (!targets) {
            targets = target;
        } else {
            targets = [NSString stringWithFormat:@"%@,%@", targets, target];
        }
    }
    
    if ([self.type isEqualToString:@"1"]) {
        return [NSString stringWithFormat:@"%@ 设置 %@ 为管理员", from, targets];
    } else {
        return [NSString stringWithFormat:@"%@ 取消 %@ 管理员权限", from, targets];
    }
}
@end
