//
//  WFCCThingsData1Content.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCThingsData1Content.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCThingsData1Content
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
    return THINGS_CONTENT_TYPE_DATA1;
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
