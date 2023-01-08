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

+(instancetype)singleConversation:(NSString *)target {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = Single_Type;
    conversation.target = target;
    conversation.line = 0;
    return conversation;
}

+(instancetype)groupConversation:(NSString *)target {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = Group_Type;
    conversation.target = target;
    conversation.line = 0;
    return conversation;
}

- (instancetype)duplicate {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = self.type;
    conversation.target = self.target;
    conversation.line = self.line;
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

- (NSUInteger)hash {
    return self.target.hash;
}

-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"type"] = @(self.type);
    dict[@"target"] = self.target;
    dict[@"line"] = @(self.line);
    return dict;
}

#pragma mark - NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = self.type;
    conversation.target = self.target;
    conversation.line = self.line;
    return conversation;
}
@end
