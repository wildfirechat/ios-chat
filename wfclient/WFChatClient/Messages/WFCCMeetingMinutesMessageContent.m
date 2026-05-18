//
//  WFCCMeetingMinutesMessageContent.m
//  WFChatClient
//
//  Created by Kimi on 2026/5/18.
//  Copyright © 2026年 WildFireChat. All rights reserved.
//

#import "WFCCMeetingMinutesMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"

@implementation WFCCMeetingMinutesMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.content = self.text;
    payload.searchableContent = self.title;
    if (self.meetingId.length) {
        NSDictionary *dict = @{@"meetingId": self.meetingId};
        payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    }
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.content;
    self.title = payload.searchableContent;
    if (payload.binaryContent.length) {
        NSError *error = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:payload.binaryContent options:0 error:&error];
        if (!error && [dict isKindOfClass:[NSDictionary class]]) {
            self.meetingId = dict[@"meetingId"];
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_MEETING_MINUTES;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (instancetype)contentWith:(NSString *)text title:(NSString *)title meetingId:(NSString *)meetingId {
    WFCCMeetingMinutesMessageContent *content = [[WFCCMeetingMinutesMessageContent alloc] init];
    content.text = text;
    content.title = title;
    content.meetingId = meetingId;
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    if (self.title.length) {
        return self.title;
    }
    return self.text;
}

@end
