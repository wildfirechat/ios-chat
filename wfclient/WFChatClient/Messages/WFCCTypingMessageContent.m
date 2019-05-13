//
//  TypingMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCTypingMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCTypingMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.content = [NSString stringWithFormat:@"%d", (int)self.type];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.type = [payload.content intValue];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TYPING;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_TRANSPARENT;
}


+ (instancetype)contentType:(WFCCTypingType)type {
    WFCCTypingMessageContent *content = [[WFCCTypingMessageContent alloc] init];
    content.type = type;
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return nil;
}
@end
