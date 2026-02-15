//
//  WFCCPollResultMessageContent.m
//  WFChatClient
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCPollResultMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"

@implementation WFCCPollResultMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.searchableContent = [NSString stringWithFormat:@"投票结果: %@", self.title];
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    dataDict[@"pollId"] = self.pollId ?: @"";
    dataDict[@"groupId"] = self.groupId ?: @"";
    dataDict[@"creatorId"] = self.creatorId ?: @"";
    dataDict[@"title"] = self.title ?: @"";
    dataDict[@"totalVotes"] = @(self.totalVotes);
    dataDict[@"voterCount"] = @(self.voterCount);
    dataDict[@"winningOptionIds"] = self.winningOptionIds ?: @[];
    dataDict[@"winningOptionTexts"] = self.winningOptionTexts ?: @[];
    dataDict[@"endedAt"] = @(self.endedAt);
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict options:0 error:&error];
    if (!error) {
        payload.binaryContent = jsonData;
    }
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:payload.binaryContent options:0 error:&error];
    
    if (!error && [dict isKindOfClass:[NSDictionary class]]) {
        self.pollId = dict[@"pollId"];
        self.groupId = dict[@"groupId"];
        self.creatorId = dict[@"creatorId"];
        self.title = dict[@"title"];
        self.totalVotes = [dict[@"totalVotes"] intValue];
        self.voterCount = [dict[@"voterCount"] intValue];
        self.winningOptionIds = dict[@"winningOptionIds"];
        self.winningOptionTexts = dict[@"winningOptionTexts"];
        self.endedAt = [dict[@"endedAt"] longLongValue];
    }
}

+ (int)getContentType {
    return 19; // 投票结果消息类型
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

- (NSString *)digest:(WFCCMessage *)message {
    return [NSString stringWithFormat:@"[投票结果] %@", self.title];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end
