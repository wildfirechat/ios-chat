//
//  WFCCGroupRejectJoinNotificationContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupRejectJoinNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCGroupRejectJoinNotificationContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.operatorUserId) {
        [dataDict setObject:self.operatorUserId forKey:@"o"];
    }
    
    if (self.groupId) {
        [dataDict setObject:self.groupId forKey:@"g"];
    }
    
    if (self.rejectUser) {
        [dataDict setObject:self.rejectUser forKey:@"mi"];
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
        self.operatorUserId = dictionary[@"o"];
        self.groupId = dictionary[@"g"];
        self.rejectUser = dictionary[@"mi"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_REJECT_JOIN_GROUP;
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
    __block NSMutableString *str = [[NSMutableString alloc] init];
    __block bool first = YES;
    [self.rejectUser enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:key inGroup:message.conversation.target refresh:NO];
        NSString *name;
        if (userInfo.readableName.length > 0) {
            name = [NSString stringWithFormat:@"%@", userInfo.readableName];
        } else {
            name = [NSString stringWithFormat:@"%@", key];
        }
        if(first) {
            first = NO;
        } else {
            [str appendString:@", "];
        }
        [str appendString:name];
    }];
    [str appendString:@" 拒绝加入群组"];


    return [str copy];
}
@end
