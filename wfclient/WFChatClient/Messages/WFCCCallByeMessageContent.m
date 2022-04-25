//
//  WFCCCallByeMessageContent.m
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCCallByeMessageContent.h"

@implementation WFCCCallByeMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = self.callId;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(self.endReason) forKey:@"r"];
    [dict setObject:@(self.inviteMsgUid) forKey:@"u"];
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:kNilOptions
                                                     error:nil];
    payload.pushData = [[NSString alloc] initWithData:payload.binaryContent encoding:NSUTF8StringEncoding];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.callId = payload.content;
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.endReason = [dictionary[@"r"] intValue];
        self.inviteMsgUid = [dictionary[@"u"] longLongValue];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_TYPE_END;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_NOT_PERSIST;
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"Bye";
}

@end
