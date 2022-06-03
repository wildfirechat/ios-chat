//
//  WFCCFileRecord.m
//  WFChatClient
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCFileRecord.h"

@implementation WFCCFileRecord
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"conversation"] = [self.conversation toJsonObj];
    [self setDict:dict key:@"messageUid" longlongValue:self.messageUid];
    dict[@"userId"]  = self.userId;
    dict[@"name"]  = self.name;
    dict[@"url"]  = self.url;
    dict[@"size"]  = @(self.size);
    dict[@"downloadCount"]  = @(self.downloadCount);
    [self setDict:dict key:@"timestamp" longlongValue:self.timestamp];
    
    return dict;
}
@end
