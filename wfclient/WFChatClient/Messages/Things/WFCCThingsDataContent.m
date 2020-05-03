//
//  WFCCThingsDataContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCThingsDataContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCThingsDataContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.binaryContent = self.data;
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.data = payload.binaryContent;
}

+ (int)getContentType {
    return THINGS_CONTENT_TYPE_DATA;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_NOT_PERSIST;
}



+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return nil;
}
@end
