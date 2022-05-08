//
//  WFCCMultiCallOngoingMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMultiCallOngoingMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCMultiCallOngoingMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.content = self.callId;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:self.initiator forKey:@"initiator"];
    [dict setObject:self.targetIds forKey:@"targetIds"];
    [dict setObject:@(self.audioOnly == YES ? 1:0) forKey:@"audioOnly"];
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                   options:kNilOptions
                                                     error:nil];

    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.callId = payload.content;
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.initiator = dictionary[@"initiator"];
        self.targetIds = dictionary[@"targetIds"];
        self.audioOnly = [dictionary[@"audioOnly"] boolValue];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_MULTI_CALL_ONGOING;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return nil;
}
@end
