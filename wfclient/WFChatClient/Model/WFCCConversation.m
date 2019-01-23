//
//  WFCCConversation.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCConversation.h"

@implementation WFCCConversation
+(instancetype)conversationWithType:(WFCCConversationType)type target:(NSString *)target line:(int)line {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = type;
    conversation.target = target;
    conversation.line = line;
    return conversation;
}
- (BOOL)isEqual:(id)object {
    if ([object isMemberOfClass:[WFCCConversation class]]) {
        WFCCConversation *o = (WFCCConversation *)object;
        if (self.type == o.type && [self.target isEqual:o.target] && self.line == o.line) {
            return YES;
        }
    }
    return NO;
}
@end
