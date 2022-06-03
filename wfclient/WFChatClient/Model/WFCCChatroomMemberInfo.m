//
//  WFCCChatroomInfo.m
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCCChatroomMemberInfo.h"

@implementation WFCCChatroomMemberInfo

-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"memberCount"] = @(self.memberCount);
    dict[@"members"] = self.members;
    return dict;
}

@end
