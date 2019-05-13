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
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
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
        self.operateUser = dictionary[@"o"];
        self.alias = dictionary[@"n"];
        self.groupId = dictionary[@"g"];
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
        formatMsg = [NSString stringWithFormat:@"你修改群名片为：%@", self.alias];
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser inGroup:self.groupId refresh:NO];
        
        if (userInfo.friendAlias.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名片为：%@", userInfo.friendAlias, self.alias];
        } else if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名片为：%@", userInfo.displayName, self.alias];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@修改群名片为：%@", self.operateUser, self.alias];
        }
    }
    
    return formatMsg;
}
@end
