//
//  WFCCChannelMenuEventMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCChannelMenuEventMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCChannelMenu.h"


@implementation WFCCChannelMenuEventMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.content = [self.menu toJsonStr];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CHANNEL_MENU_EVENT;
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
