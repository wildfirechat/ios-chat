//
//  WFCCCreateGroupNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCCreateGroupNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCCreateGroupNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.creator) {
        [dataDict setObject:self.creator forKey:@"o"];
    }
    if (self.groupName) {
        [dataDict setObject:self.groupName forKey:@"n"];
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
        self.creator = dictionary[@"o"];
        self.groupName = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CREATE_GROUP;
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
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.creator]) {
        return [NSString stringWithFormat:@"你创建了群\"%@\"", self.groupName];
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.creator inGroup:self.groupId refresh:NO];
        if (userInfo) {
            return [NSString stringWithFormat:@"%@创建了群\"%@\"", userInfo.readableName, self.groupName];
        } else {
            return [NSString stringWithFormat:@"用户<%@>创建了群\"%@\"", self.creator, self.groupName];
        }
    }
}
@end
