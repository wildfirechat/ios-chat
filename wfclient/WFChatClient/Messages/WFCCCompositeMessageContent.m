//
//  WFCCCompositeMessageContent.m
//  WFChatClient
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCCompositeMessageContent.h"
#import "Common.h"
#import "WFCCIMService.h"
#import "WFCCMessage.h"

@implementation WFCCCompositeMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    payload.content = self.targetName;

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    NSMutableArray *arrays = [[NSMutableArray alloc] init];
    for (WFCCMessage *msg in self.messages) {
        NSMutableDictionary *msgDict = [NSMutableDictionary dictionary];
        if (msg.messageUid) {
            [msgDict setValue:@(msg.messageUid) forKey:@"uid"];
        }
        [msgDict setValue:@(msg.conversation.type) forKey:@"type"];
        [msgDict setValue:msg.conversation.target forKey:@"target"];
        if (msg.conversation.line) {
            [msgDict setValue:@(msg.conversation.line) forKey:@"line"];
        }
        if (msg.fromUser) {
            [msgDict setValue:msg.fromUser forKey:@"from"];
        }
        if (msg.toUsers.count) {
            [msgDict setValue:msg.toUsers forKey:@"tos"];
        }
        if (msg.direction) {
            [msgDict setValue:@(msg.direction) forKey:@"direction"];
        }
        if (msg.status) {
            [msgDict setValue:@(msg.status) forKey:@"status"];
        }
        if (msg.serverTime) {
            [msgDict setValue:@(msg.serverTime) forKey:@"serverTime"];
        }
        WFCCMessagePayload *payload = [msg.content encode];
        if (payload.contentType) {
            [msgDict setValue:@(payload.contentType) forKey:@"ctype"];
        }
        if (payload.searchableContent.length) {
            [msgDict setObject:payload.searchableContent forKey:@"csc"];
        }
        if (payload.pushContent.length) {
            [msgDict setObject:payload.pushContent forKey:@"cpc"];
        }
        if (payload.pushData.length) {
            [msgDict setObject:payload.pushData forKey:@"cpd"];
        }
        if (payload.content.length) {
            [msgDict setObject:payload.content forKey:@"cc"];
        }
        if (payload.binaryContent.length) {
            [msgDict setObject:payload.binaryContent forKey:@"cbc"];
        }
        if (payload.mentionedType) {
            [msgDict setObject:@(payload.mentionedType) forKey:@"cmt"];
        }
        if (payload.mentionedTargets.count) {
            [msgDict setObject:payload.mentionedTargets forKey:@"cmts"];
        }
        if (payload.extra.length) {
            [msgDict setObject:payload.extra forKey:@"ce"];
        }

        [arrays addObject:msgDict];
    }
    [dataDict setObject:arrays forKey:@"ms"];
    

    payload.binaryContent = [NSKeyedArchiver archivedDataWithRootObject:dataDict];

    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.targetName = payload.content;

    NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:payload.binaryContent];
    
    NSMutableArray<WFCCMessage *> *messages = [[NSMutableArray alloc] init];
    if (dictionary && [dictionary[@"ms"] isKindOfClass:[NSArray class]]) {
        NSArray *arrays = (NSArray *)dictionary[@"ms"];
        for (NSDictionary *msgDict in arrays) {
            WFCCMessage *msg = [[WFCCMessage alloc] init];
            msg.messageUid = [msgDict[@"uid"] longLongValue];
            
            msg.conversation = [[WFCCConversation alloc] init];
            msg.conversation.type = [msgDict[@"type"] intValue];
            msg.conversation.target = msgDict[@"target"];
            msg.conversation.line = [msgDict[@"line"] intValue];
            
            msg.fromUser = msgDict[@"from"];
            msg.toUsers = msgDict[@"tos"];
            msg.direction = [msgDict[@"direction"] intValue];
            msg.status = [msgDict[@"status"] intValue];
            msg.serverTime = [msgDict[@"serverTime"] longLongValue];
            
            WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
            payload.contentType = [msgDict[@"ctype"] intValue];
            payload.searchableContent = msgDict[@"csc"];
            payload.pushContent = msgDict[@"cpc"];
            payload.pushData = msgDict[@"cpd"];
            payload.content = msgDict[@"cc"];
            payload.binaryContent = msgDict[@"cbc"];
            payload.mentionedType = [msgDict[@"cmt"] intValue];
            payload.mentionedTargets = msgDict[@"cmts"];
            payload.extra = msgDict[@"ce"];
            
            msg.content = [[WFCCIMService sharedWFCIMService] messageContentFromPayload:payload];
            [messages addObject:msg];
        }
        self.messages = [messages copy];
    }
    
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_COMPOSITE_MESSAGE;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}



+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    return @"[聊天记录]";
}
@end
