//
//  WFCCChangeGroupNameNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/20.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCChangeGroupNameNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCChangeGroupNameNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.name) {
        [dataDict setObject:self.name forKey:@"n"];
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
        self.name = dictionary[@"n"];
        if (self.name == nil) {
            self.name = @"";
        }
        self.groupId = dictionary[@"g"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANGE_GROUP_NAME;
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
        formatMsg = [NSString stringWithFormat:@"你修改群名称为：%@", self.name];
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser inGroup:self.groupId refresh:NO];
        if (userInfo.friendAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", userInfo.friendAlias];
        } else if(userInfo.groupAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", userInfo.groupAlias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", self.operateUser];
        }
        
        formatMsg = [formatMsg stringByAppendingString:self.name];
    }
    
    return formatMsg;
}
@end
