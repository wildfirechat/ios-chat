//
//  WFCCJoinCallRequestMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCJoinCallRequestMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCJoinCallRequestMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.content = self.callId;
    
    if (self.clientId) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:self.clientId forKey:@"clientId"];
        payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:kNilOptions
                                                         error:nil];
    }
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.callId = payload.content;
    
    NSError *__error = nil;
    WFCCDictionary *dictionary = [WFCCDictionary fromData:payload.binaryContent error:&__error];
    if (!__error) {
        self.clientId = dictionary[@"clientId"];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_JOIN_CALL_REQUEST;
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
