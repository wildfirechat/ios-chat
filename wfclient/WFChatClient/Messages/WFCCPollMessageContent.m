//
//  WFCCPollMessageContent.m
//  WFChatClient
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCPollMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"

@implementation WFCCPollMessageContent

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [[WFCCMessagePayload alloc] init];
    payload.contentType = [self.class getContentType];
    payload.searchableContent = self.title;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    dataDict[@"pollId"] = self.pollId ?: @"";
    dataDict[@"groupId"] = self.groupId ?: @"";
    dataDict[@"creatorId"] = self.creatorId ?: @"";
    dataDict[@"title"] = self.title ?: @"";
    if (self.desc) {
        dataDict[@"desc"] = self.desc;
    }
    dataDict[@"visibility"] = @(self.visibility);
    dataDict[@"type"] = @(self.type);
    dataDict[@"anonymous"] = @(self.anonymous);
    dataDict[@"status"] = @(self.status);
    dataDict[@"endTime"] = @(self.endTime);
    dataDict[@"totalVotes"] = @(self.totalVotes);
    
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
        self.desc = dict[@"desc"];
        self.visibility = [dict[@"visibility"] intValue];
        self.type = [dict[@"type"] intValue];
        self.anonymous = [dict[@"anonymous"] intValue];
        self.status = [dict[@"status"] intValue];
        self.endTime = [dict[@"endTime"] longLongValue];
        self.totalVotes = [dict[@"totalVotes"] intValue];
    }
}

+ (int)getContentType {
    return 18; // 投票消息类型
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

- (NSString *)digest:(WFCCMessage *)message {
    return [NSString stringWithFormat:@"[投票] %@", self.title];
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end
