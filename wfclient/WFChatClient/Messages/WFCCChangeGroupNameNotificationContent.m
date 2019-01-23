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
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operateUser) {
        [dataDict setObject:self.operateUser forKey:@"o"];
    }
    if (self.name) {
        [dataDict setObject:self.name forKey:@"n"];
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
        self.name = dictionary[@"n"];
        if (self.name == nil) {
            self.name = @"";
        }
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

- (NSString *)digest {
    return [self formatNotification];
}

- (NSString *)formatNotification {
    NSString *formatMsg;
    if ([[WFCCNetworkService sharedInstance].userId isEqualToString:self.operateUser]) {
        formatMsg = [NSString stringWithFormat:@"你修改群名称为：%@", self.name];
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.operateUser refresh:NO];
        if (userInfo.displayName.length > 0) {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", userInfo.displayName];
        } else {
            formatMsg = [NSString stringWithFormat:@"%@修改群名称为：", self.operateUser];
        }
        
        formatMsg = [formatMsg stringByAppendingString:self.name];
    }
    
    return formatMsg;
}
@end
