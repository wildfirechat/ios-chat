//
//  WFCCNotDeliveredMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotDeliveredMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCNotDeliveredMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.messageUid) forKey:@"mid"];
    [dataDict setObject:@(self.allFailure) forKey:@"all"];
    [dataDict setObject:self.userIds forKey:@"us"];
    
    [dataDict setObject:@(self.localImErrorCode) forKey:@"lme"];
    [dataDict setObject:@(self.localBridgeErrorCode) forKey:@"lbe"];
    [dataDict setObject:@(self.remoteBridgeErrorCode) forKey:@"rbe"];
    [dataDict setObject:@(self.remoteServerErrorCode) forKey:@"rme"];
    [dataDict setObject:self.errorMessage forKey:@"em"];
    
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
        self.messageUid = [dictionary[@"mid"] longLongValue];
        self.allFailure = [dictionary[@"all"] boolValue];
        self.userIds = dictionary[@"us"];
        
        self.localImErrorCode = [dictionary[@"lme"] intValue];
        self.localBridgeErrorCode = [dictionary[@"lbe"] intValue];
        self.remoteBridgeErrorCode = [dictionary[@"rbe"] intValue];
        self.remoteServerErrorCode = [dictionary[@"rme"] intValue];
        self.errorMessage = dictionary[@"em"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_NOT_DELIVERED;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    if(self.allFailure) {
        return @"消息未能送达";
    } else {
        if(message.conversation.type == Single_Type) {
            return [NSString stringWithFormat:@"消息未能送达"];
        } else {
            return [NSString stringWithFormat:@"消息未能送达部分用户"];
        }
    }
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    return [self digest:message];
}
@end
