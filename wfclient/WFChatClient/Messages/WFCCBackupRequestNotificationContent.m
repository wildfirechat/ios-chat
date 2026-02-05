//
//  WFCCBackupRequestNotificationContent.m
//  WFChatClient
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCBackupRequestNotificationContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCBackupRequestNotificationContent

- (instancetype)initWithConversations:(long)conversationCount
                             messageCount:(long)messageCount
                             includeMedia:(BOOL)includeMedia
                             timestamp:(long long)timestamp {
    self = [super init];
    if (self) {
        self.conversationCount = conversationCount;
        self.messageCount = messageCount;
        self.includeMedia = includeMedia;
        self.timestamp = timestamp;
    }
    return self;
}

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    [dataDict setObject:@(self.conversationCount) forKey:@"cc"];
    [dataDict setObject:@(self.messageCount) forKey:@"mc"];

    [dataDict setObject:@(self.includeMedia) forKey:@"m"];
    [dataDict setObject:@(self.timestamp) forKey:@"t"];

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
        self.conversationCount = [dictionary[@"cc"] longValue];
        self.messageCount = [dictionary[@"mc"] longValue];
        self.includeMedia = [dictionary[@"m"] boolValue];
        self.timestamp = [dictionary[@"t"] longLongValue];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_BACKUP_REQUEST;
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
    return WFCCString(@"BackupRequest");
}

@end
