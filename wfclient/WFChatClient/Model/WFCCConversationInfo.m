//
//  WFCCConversationInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/29.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCConversationInfo.h"

@implementation WFCCConversationInfo
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"conversation"] = [self.conversation toJsonObj];
    dict[@"lastMessage"] = [self.lastMessage toJsonObj];
    dict[@"draft"] = self.draft;
    [self setDict:dict key:@"timestamp" longlongValue:self.timestamp];
    dict[@"unreadCount"] = [self.unreadCount toJsonObj];
    dict[@"isTop"] = @(self.isTop);
    dict[@"isSilent"] = @(self.isSilent);
    
    return dict;
}
@end
