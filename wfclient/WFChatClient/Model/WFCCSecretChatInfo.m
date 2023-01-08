//
//  WFCCFriend.m
//  WFChatClient
//
//  Created by heavyrain on 2021/5/16.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import "WFCCSecretChatInfo.h"

@implementation WFCCSecretChatInfo
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"targetId"] = self.targetId;
    dict[@"userId"] = self.userId;
    dict[@"state"] = @(self.state);
    dict[@"burnTime"] = @(self.burnTime);
    [self setDict:dict key:@"createTime" longlongValue:self.createTime];
    return dict;
}
@end
