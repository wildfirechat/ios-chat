//
//  WFCCFriend.m
//  WFChatClient
//
//  Created by heavyrain on 2021/5/16.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import "WFCCFriend.h"

@implementation WFCCFriend
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"userId"] = self.userId;
    dict[@"alias"] = self.alias;
    dict[@"extra"] = self.extra;
    [self setDict:dict key:@"timestamp" longlongValue:self.timestamp];
    return dict;
}
@end
