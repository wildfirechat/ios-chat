//
//  WFCCTransferGroupOwnerNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCTransferGroupOwnerNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCTransferGroupOwnerNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.owner) {
        [dataDict setObject:self.owner forKey:@"m"];
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
        self.operateUser = dictionary[@"o"];
        self.owner = dictionary[@"m"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER;
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
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.owner inGroup:self.groupId refresh:NO];
        if (userInfo.friendAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"你把群主转让给了%@", userInfo.friendAlias];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"你把群主转让给了%@", userInfo.groupAlias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"你把群主转让给了%@", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"你把群主转让给了%@", self.owner];
        }
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser inGroup:self.groupId refresh:NO];
        if (userInfo.friendAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@把群主转让给了", userInfo.friendAlias];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@把群主转让给了", userInfo.groupAlias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@把群主转让给了", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@把群主转让给了", self.operateUser];
        }
        
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.owner]) {
            formatMsg = [formatMsg stringByAppendingString:@"你"];
        } else {
            userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.owner inGroup:self.groupId refresh:NO];
            if (userInfo.friendAlias.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.friendAlias];
            } else if(userInfo.groupAlias.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.groupAlias];
            } else if (userInfo.displayName.length > 0) {
                formatMsg = [formatMsg stringByAppendingString:userInfo.displayName];
            } else {
                formatMsg = [formatMsg stringByAppendingString:self.owner];
            }
        }
    }
    
    return formatMsg;
}
@end
