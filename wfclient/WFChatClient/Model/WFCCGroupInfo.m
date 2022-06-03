//
//  WFCCGroupInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupInfo.h"

@implementation WFCCGroupInfo
- (NSString *)displayName {
    return self.remark.length?self.remark:self.name;
}
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"target"] = self.target;
    if(self.type)
        dict[@"type"] = @(self.type);
    
    if(self.name.length)
        dict[@"name"] = self.name;

    if(self.portrait.length)
        dict[@"portrait"] = self.portrait;

    if(self.memberCount)
        dict[@"memberCount"] = @(self.memberCount);

    if(self.owner.length)
        dict[@"owner"] = self.owner;

    if(self.extra.length)
        dict[@"extra"] = self.extra;

    if(self.remark.length)
        dict[@"remark"] = self.remark;

    if(self.mute)
        dict[@"mute"] = @(self.mute);

    if(self.joinType)
        dict[@"joinType"] = @(self.joinType);

    if(self.privateChat)
        dict[@"privateChat"] = @(self.privateChat);

    if(self.searchable)
        dict[@"searchable"] = @(self.searchable);

    if(self.historyMessage)
        dict[@"historyMessage"] = @(self.historyMessage);

    if(self.maxMemberCount)
        dict[@"maxMemberCount"] = @(self.maxMemberCount);

    if(self.updateTimestamp) {
        [self setDict:dict key:@"updateTimestamp" longlongValue:self.updateTimestamp];
    }
    
    return dict;
}
@end
