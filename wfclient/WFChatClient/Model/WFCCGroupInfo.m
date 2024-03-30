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
    dict[@"type"] = @(self.type);
    
    if(self.name.length)
        dict[@"name"] = self.name;

    if(self.portrait.length)
        dict[@"portrait"] = self.portrait;

    dict[@"memberCount"] = @(self.memberCount);

    if(self.owner.length)
        dict[@"owner"] = self.owner;

    if(self.extra.length)
        dict[@"extra"] = self.extra;

    if(self.remark.length)
        dict[@"remark"] = self.remark;

    dict[@"mute"] = @(self.mute);
    dict[@"joinType"] = @(self.joinType);
    dict[@"privateChat"] = @(self.privateChat);
    dict[@"searchable"] = @(self.searchable);
    dict[@"historyMessage"] = @(self.historyMessage);
    dict[@"maxMemberCount"] = @(self.maxMemberCount);
    dict[@"superGroup"] = @(self.superGroup);
    dict[@"deleted"] = @(self.deleted);
    [self setDict:dict key:@"updateDt" longlongValue:self.updateDt];
    
    return dict;
}
@end
