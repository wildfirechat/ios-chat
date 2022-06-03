//
//  WFCCGroupMember.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/30.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupMember.h"

@implementation WFCCGroupMember
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"groupId"] = self.groupId;
    dict[@"memberId"] = self.memberId;
    dict[@"alias"] = self.alias;
    dict[@"extra"] = self.extra;
    dict[@"type"] = @(self.type);
    dict[@"createTime"] = @(self.createTime);
    
    return dict;
}
@end
