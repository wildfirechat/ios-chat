//
//  WFCCModifyGroupAliasNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCModifyGroupAliasNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCModifyGroupAliasNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.alias) {
        [dataDict setObject:self.alias forKey:@"n"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    if (self.memberId) {
        [dataDict setObject:self.memberId forKey:@"m"];
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
        self.operateUser = dictionary[@"o"];
        self.alias = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
        self.memberId = dictionary[@"m"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS;
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
        formatMsg = @"你修改";
    } else {
        WFCCUserInfo *userInfo;
        if([self.operateUser isEqualToString:self.memberId]) {
            userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser refresh:NO];
        } else {
            userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser inGroup:self.groupId refresh:NO];
        }
        
        if (self.memberId.length && userInfo.groupAlias.length) {
            formatMsg = [NSString stringWithFormat:@"%@修改", userInfo.groupAlias];
        } else if (userInfo.friendAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改", userInfo.friendAlias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@修改", self.operateUser];
        }
    }
    
    if (self.memberId.length && ![self.memberId isEqualToString:self.operateUser]) {
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.memberId]) {
            formatMsg = [formatMsg stringByAppendingFormat:@"%@的", @"你"];
        } else {
            WFCCUserInfo *member = [[WFCCIMService sharedWFCIMService] getUserInfo:self.memberId refresh:NO];
            if (member.friendAlias.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@的", member.friendAlias];
            } else if (member.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@的", member.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingFormat:@"%@的", self.memberId];
            }
        }
    }
    
    formatMsg = [formatMsg stringByAppendingFormat:@"群昵称为%@", self.alias];
    return formatMsg;
}
@end
