//
//  WFCCTranscriptionMessageContent.m
//  WFChatClient
//
//  Created by Kimi on 2026/5/18.
//  Copyright © 2026年 WildFireChat. All rights reserved.
//

#import "WFCCTranscriptionMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"

@implementation WFCCTranscriptionMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.transcriptionId) {
        dict[@"id"] = @(self.transcriptionId);
    }
    if (self.meetingId.length) {
        dict[@"meetingId"] = self.meetingId;
    }
    if (self.userId.length) {
        dict[@"userId"] = self.userId;
    }
    if (self.timestamp) {
        dict[@"timestamp"] = @(self.timestamp);
    }
    if (self.duration) {
        dict[@"duration"] = @(self.duration);
    }
    if (self.content.length) {
        dict[@"content"] = self.content;
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
    if (!error) {
        payload.content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    if (payload.content.length) {
        NSData *data = [payload.content dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError *error = nil;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!error && [dict isKindOfClass:[NSDictionary class]]) {
                self.transcriptionId = [dict[@"id"] longLongValue];
                self.meetingId = dict[@"meetingId"];
                self.userId = dict[@"userId"];
                self.timestamp = [dict[@"timestamp"] longLongValue];
                self.duration = [dict[@"duration"] longLongValue];
                self.content = dict[@"content"];
            }
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TRANSCRIPTION;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (instancetype)contentWithId:(long long)transcriptionId
                    meetingId:(NSString *)meetingId
                       userId:(NSString *)userId
                    timestamp:(long long)timestamp
                     duration:(long long)duration
                      content:(NSString *)content {
    WFCCTranscriptionMessageContent *msgContent = [[WFCCTranscriptionMessageContent alloc] init];
    msgContent.transcriptionId = transcriptionId;
    msgContent.meetingId = meetingId;
    msgContent.userId = userId;
    msgContent.timestamp = timestamp;
    msgContent.duration = duration;
    msgContent.content = content;
    return msgContent;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return self.content ?: @"";
}

@end
