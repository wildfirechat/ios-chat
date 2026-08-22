//
//  WFCCStreamingTextCancelledMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCStreamingTextCancelledMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCStreamingTextCancelledMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.text;
    payload.content = self.streamId;
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.searchableContent;
    self.streamId = payload.content;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_STREAMING_TEXT_CANCELLED;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return self.text;
}
@end
