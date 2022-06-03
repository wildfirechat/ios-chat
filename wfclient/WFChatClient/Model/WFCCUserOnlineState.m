//
//  WFCCUserOnlineState.m
//  WFChatClient
//
//  Created by heavyrain on 2022/2/17.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCCUserOnlineState.h"


@implementation WFCCClientState
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"platform"] = @(self.platform);
    dict[@"state"] = @(self.state);
    dict[@"lastSeen"] = @(self.lastSeen);
    return dict;
}
@end

@implementation WFCCUserCustomState
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"text"] = self.text;
    dict[@"state"] = @(self.state);
    return dict;
}
@end

@implementation WFCCUserOnlineState
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"userId"] = self.userId;
    dict[@"customState"] = [self.customState toJsonObj];
    __block NSMutableArray *arr = [[NSMutableArray alloc] init];
    [self.clientStates enumerateObjectsUsingBlock:^(WFCCClientState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [arr addObject:[obj toJsonObj]];
    }];
    dict[@"clientStates"] = arr;
    return dict;
}
@end
