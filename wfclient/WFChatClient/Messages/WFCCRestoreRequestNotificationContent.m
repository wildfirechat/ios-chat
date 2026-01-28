//
//  WFCCRestoreRequestNotificationContent.m
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCRestoreRequestNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCRestoreRequestNotificationContent

- (instancetype)initWithTimestamp:(long long)timestamp {
    self = [super init];
    if (self) {
        _timestamp = timestamp;
    }
    return self;
}

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.timestamp) forKey:@"t"];
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    NSError *__error = nil;
    WFCCDictionary *dictionary = [WFCCDictionary fromData:payload.binaryContent error:&__error];

    if (!__error) {
        self.timestamp = [dictionary[@"t"] longLongValue];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_RESTORE_REQUEST;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    return WFCCString(@"RestoreRequest");
}

@end
