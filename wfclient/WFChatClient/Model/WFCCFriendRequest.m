//
//  WFCCFriendRequest.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCFriendRequest.h"

@implementation WFCCFriendRequest
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"direction"] = @(self.direction);
    dict[@"target"] = self.target;
    
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
