//
//  WFCCRestoreResponseNotificationContent.m
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCRestoreResponseNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCRestoreResponseNotificationContent

+ (instancetype)rejectedResponse {
    WFCCRestoreResponseNotificationContent *content = [[WFCCRestoreResponseNotificationContent alloc] init];
    content.approved = NO;
    return content;
}

+ (instancetype)approvedResponseWithIP:(NSString *)ip port:(NSInteger)port {
    WFCCRestoreResponseNotificationContent *content = [[WFCCRestoreResponseNotificationContent alloc] init];
    content.approved = YES;
    content.serverIP = ip;
    content.serverPort = port;
    return content;
}

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    [dataDict setObject:@(self.approved) forKey:@"a"];

    if (self.approved) {
        if (self.serverIP) {
            [dataDict setObject:self.serverIP forKey:@"ip"];
        }
        [dataDict setObject:@(self.serverPort) forKey:@"p"];
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
        self.approved = [dictionary[@"a"] boolValue];

        if (self.approved) {
            self.serverIP = dictionary[@"ip"];
            self.serverPort = [dictionary[@"p"] integerValue];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_RESTORE_RESPONSE;
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
    return self.approved ? WFCCString(@"RestoreResponseApproved") : WFCCString(@"RestoreResponseRejected");
}

@end
