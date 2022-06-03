//
//  WFCCRawMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCRawMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCRawMessageContent
- (WFCCMessagePayload *)encode {
    return self.payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    self.payload = payload;
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_UNKNOWN;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_NOT_PERSIST;
}

+ (instancetype)contentOfPayload:(WFCCMessagePayload *)payload {
    if(!payload)
        return nil;
    
    WFCCRawMessageContent *raw = [[WFCCRawMessageContent alloc] init];
    raw.payload = payload;
    return raw;
}

- (NSString *)digest:(WFCCMessage *)message {
  return nil;
}
@end
