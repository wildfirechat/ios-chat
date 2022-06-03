//
//  WFCCConversationSearchInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCConversationSearchInfo.h"

@implementation WFCCConversationSearchInfo
-(id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"conversation"] = [self.conversation toJsonObj];
    if(self.marchedMessage) {
        dict[@"marchedMessage"] = [self.marchedMessage toJsonObj];
    }
    dict[@"marchedCount"] = @(self.marchedCount);
    dict[@"keyword"] = self.keyword;
    return dict;
}
@end
