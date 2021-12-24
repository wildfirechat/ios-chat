//
//  WFCCMarkUnreadMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMarkUnreadMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCMarkUnreadMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.messageUid) {
        [dataDict setObject:@(self.messageUid) forKey:@"u"];
        [dataDict setObject:@(self.timestamp) forKey:@"t"];
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
        self.messageUid = [dictionary[@"u"] longLongValue];
        self.timestamp = [dictionary[@"t"] longLongValue];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MARK_UNREAD_SYNC;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_NOT_PERSIST;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return nil;
}
@end
