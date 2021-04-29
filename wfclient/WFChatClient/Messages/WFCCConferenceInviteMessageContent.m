//
//  WFCCConferenceInviteMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCConferenceInviteMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCConferenceInviteMessageContent
- (WFCCMessagePayload *)encode {
    
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    payload.content = self.callId;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.host) {
        [dataDict setObject:self.host forKey:@"h"];
    }
    if (self.startTime) {
        [dataDict setObject:@(self.startTime) forKey:@"s"];
    }
    if (self.title) {
        [dataDict setObject:self.title forKey:@"t"];
    }
    if (self.desc) {
        [dataDict setObject:self.desc forKey:@"d"];
    }
    if (self.pin) {
        [dataDict setObject:self.pin forKey:@"p"];
    }
    
    [dataDict setValue:@(self.audioOnly?1:0) forKey:@"a"];
    [dataDict setValue:@(self.audience?1:0) forKey:@"audience"];
    [dataDict setValue:@(self.advanced?1:0) forKey:@"advanced"];
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
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
        self.host = dictionary[@"h"];
        self.startTime = dictionary[@"s"] ? [dictionary[@"s"] longLongValue] : 0;
        self.title = dictionary[@"t"];
        self.desc = dictionary[@"d"];
        self.audioOnly = [dictionary[@"a"] intValue] ? YES : NO;
        self.audience = [dictionary[@"audience"] intValue] ? YES : NO;
        self.advanced = [dictionary[@"advanced"] intValue] ? YES : NO;
        self.pin = dictionary[@"p"];
    }
}

+ (int)getContentType {
    return VOIP_CONTENT_CONFERENCE_INVITE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    if (_audioOnly) {
        return @"[音频会议邀请]";
    } else {
        return @"[视频会议邀请]";
    }
}
@end
