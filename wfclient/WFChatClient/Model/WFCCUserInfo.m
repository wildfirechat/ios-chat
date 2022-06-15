//
//  WFCCUserInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCUserInfo.h"

@implementation WFCCUserInfo
- (void)cloneFrom:(WFCCUserInfo *)other {
    self.userId = other.userId;
    self.name = other.name;
    self.displayName = other.displayName;
    self.portrait = other.portrait;
    self.gender = other.gender;
    self.mobile = other.mobile;
    self.email = other.email;
    self.address = other.address;
    self.company = other.company;
    self.social = other.social;
    self.extra = other.extra;
    self.updateDt = other.updateDt;
    self.social = other.social;
    self.type = other.type;
    self.deleted = other.deleted;
}

- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"uid"] = self.userId;
    dict[@"name"] = self.name;
    dict[@"displayName"] = self.displayName;
    dict[@"portrait"] = self.portrait;
    dict[@"gender"] = @(self.gender);
    if(self.mobile.length)
        dict[@"mobile"] = self.mobile;
    if(self.email.length)
        dict[@"email"] = self.email;
    if(self.address.length)
        dict[@"address"] = self.address;
    if(self.company.length)
        dict[@"company"] = self.company;
    if(self.social.length)
        dict[@"social"] = self.social;
    if(self.extra.length)
        dict[@"extra"] = self.extra;
    if(self.social.length)
        dict[@"social"] = self.social;
    dict[@"updateDt"] = @(self.updateDt);
    dict[@"deleted"] = @(self.deleted);
    return dict;
}
@end
