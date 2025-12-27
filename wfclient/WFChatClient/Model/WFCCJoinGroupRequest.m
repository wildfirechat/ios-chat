//
//  WFCCFriendRequest.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCJoinGroupRequest.h"

@implementation WFCCJoinGroupRequest
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"groupId"] = self.groupId;
    dict[@"memberId"] = self.memberId;
    dict[@"requestUserId"] = self.requestUserId;
    
    if(self.acceptUserId.length)
        dict[@"acceptUserId"] = self.acceptUserId;
    
    if(self.reason.length)
        dict[@"reason"] = self.reason;
    
    if(self.extra.length)
        dict[@"extra"] = self.extra;
    
    dict[@"status"] = @(self.status);
    dict[@"readStatus"] = @(self.readStatus);
    [self setDict:dict key:@"timestamp" longlongValue:self.timestamp];
    return dict;
}
@end
