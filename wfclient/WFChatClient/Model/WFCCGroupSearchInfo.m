//
//  WFCCGroupSearchInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCGroupSearchInfo.h"

@implementation WFCCGroupSearchInfo
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    id groupDict = [self.groupInfo toJsonObj];
    dict[@"groupInfo"] = groupDict;
    dict[@"marchType"] = @(self.marchType);
    dict[@"keyword"] = self.keyword;
    if(self.marchedMemberNames.count)
        dict[@"marchedMemberNames"] = self.marchedMemberNames;
    return dict;
}
@end
