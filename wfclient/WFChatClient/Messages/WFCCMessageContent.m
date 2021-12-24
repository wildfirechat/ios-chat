//
//  WFCCMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/15.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"
#import "WFCCMediaMessageContent.h"
#import "Common.h"

@implementation WFCCMessagePayload
@end

@implementation WFCCMediaMessagePayload
@end

@implementation WFCCMessageContent
+ (void)load {
    
}
- (WFCCMessagePayload *)encode {
    if([self isKindOfClass:[WFCCMediaMessageContent class]]) {
        WFCCMediaMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];
        payload.extra = self.extra;
        payload.contentType = [self.class getContentType];
        return payload;
    } else {
        WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
        payload.extra = self.extra;
        payload.contentType = [self.class getContentType];
        return payload;
    }
}
- (void)decode:(WFCCMessagePayload *)payload {
    self.extra = payload.extra;
}
+ (int)getContentType {
    return 0;
}
+ (int)getContentFlags {
    return 0;
}
- (NSString *)digest:(WFCCMessage *)message {
  return @"Unimplement digest function";
}
@end
