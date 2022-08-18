//
//  WFCCChannelMenu.m
//  WFChatClient
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCCChannelMenu.h"

@implementation WFCCChannelMenu
- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"type"] = self.type;
    dict[@"name"] = self.name;
    if(self.menuId.length) dict[@"menuId"] = self.menuId;
    if(self.key.length) dict[@"key"] = self.key;
    if(self.url.length) dict[@"url"] = self.url;
    if(self.mediaId.length) dict[@"mediaId"] = self.mediaId;
    if(self.articleId.length) dict[@"articleId"] = self.articleId;
    if(self.appId.length) dict[@"appId"] = self.appId;
    if(self.appPage.length) dict[@"appPage"] = self.appPage;
    if(self.extra.length) dict[@"extra"] = self.extra;
    if (self.subMenus.count) {
        NSMutableArray *subMenus = [[NSMutableArray alloc] init];
        [self.subMenus enumerateObjectsUsingBlock:^(WFCCChannelMenu * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id subs = [obj toJsonObj];
            [subMenus addObject:subs];
        }];
        dict[@"subMenus"] = subMenus;
    }

    return dict;
}
@end
