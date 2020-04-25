//
//  WFCCThingsLostEventContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCThingsLostEventContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCThingsLostEventContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return THINGS_CONTENT_TYPE_LOST_EVENT;
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
