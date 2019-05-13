//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCCallStartMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCCallStartMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = self.callId;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.connectTime) {
        [dataDict setObject:@(self.connectTime) forKey:@"c"];
    }
    if (self.endTime) {
        [dataDict setObject:@(self.endTime) forKey:@"e"];
    }
    if (self.status) {
        [dataDict setObject:@(self.status) forKey:@"s"];
    }
    
    [dataDict setObject:self.targetId forKey:@"t"];
    [dataDict setValue:@(self.audioOnly?1:0) forKey:@"a"];
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.callId = payload.content;
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.connectTime = dictionary[@"c"] ? [dictionary[@"c"] longLongValue] : 0;
        self.endTime = dictionary[@"e"] ? [dictionary[@"e"] longLongValue] : 0;
        self.status = dictionary[@"s"] ? [dictionary[@"s"] intValue] : 0;
        self.audioOnly = [dictionary[@"a"] intValue] ? YES : NO;
        self.targetId = dictionary[@"t"];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_TYPE_START;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    if (_audioOnly) {
        return @"[语音通话]";
    } else {
        return @"[视频通话]";
    }
}
@end
