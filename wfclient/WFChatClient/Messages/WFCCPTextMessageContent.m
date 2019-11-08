//
//  WFCCPTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCPTextMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCPTextMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    payload.searchableContent = self.text;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.searchableContent;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_P_TEXT;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}


+ (instancetype)contentWith:(NSString *)text {
    WFCCPTextMessageContent *content = [[WFCCPTextMessageContent alloc] init];
    content.text = text;
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return self.text;
}
@end
