//
//  WFCCUnknownMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCUnknownMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCUnknownMessageContent
- (WFCCMessagePayload *)encode {
    return self.orignalPayload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.orignalType = payload.contentType;
    self.orignalPayload = payload;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_UNKNOWN;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}



- (NSString *)digest:(WFCCMessage *)message {
  return [NSString stringWithFormat:@"未知类型消息(%zd)", self.orignalType];
}
@end
