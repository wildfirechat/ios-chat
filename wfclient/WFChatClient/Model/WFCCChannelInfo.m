//
//  WFCCChatroomInfo.m
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCCChannelInfo.h"

@implementation WFCCChannelInfo
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"channelId"] = self.channelId;
    dict[@"name"] = self.name;
    dict[@"portrait"] = self.portrait;
    dict[@"owner"] = self.owner;
    dict[@"desc"] = self.desc;
    dict[@"extra"] = self.extra;
    dict[@"secret"] = self.secret;
    dict[@"callback"] = self.callback;

    dict[@"status"] = @(self.status);
    [self setDict:dict key:@"updateDt" longlongValue:self.updateDt];
    
    if (self.menus.count) {
        NSMutableArray *subMenus = [[NSMutableArray alloc] init];
        [self.menus enumerateObjectsUsingBlock:^(WFCCChannelMenu * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id subs = [obj toJsonObj];
            [subMenus addObject:subs];
        }];
        dict[@"menus"] = subMenus;
    }
    
    return dict;
}


@end
