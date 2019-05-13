//
//  WFCCMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/15.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"
#import "Common.h"

@implementation WFCCMessagePayload
@end

@implementation WFCCMediaMessagePayload
@end

@implementation WFCCMessageContent
+ (void)load {
    
}
- (WFCCMessagePayload *)encode {
    return nil;
}
- (void)decode:(WFCCMessagePayload *)payload {
    
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
