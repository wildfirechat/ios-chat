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
    self.groupAlias = other.groupAlias;
    self.friendAlias = other.friendAlias;
    self.portrait = other.portrait;
    self.gender = other.gender;
    self.mobile = other.mobile;
    self.email = other.email;
    self.address = other.address;
    self.company = other.company;
    self.social = other.social;
    self.extra = other.extra;
    self.updateDt = other.updateDt;
    self.type = other.type;
    self.deleted = other.deleted;
}

- (id)toJsonObj {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"uid"] = self.userId;
    dict[@"name"] = self.name;
    dict[@"displayName"] = self.displayName;
    dict[@"groupAlias"] = self.groupAlias;
    dict[@"friendAlias"] = self.friendAlias;
    dict[@"portrait"] = self.portrait;
    dict[@"gender"] = @(self.gender);
    dict[@"type"] = @(self.type);
    dict[@"mobile"] = self.mobile;
    dict[@"email"] = self.email;
    dict[@"address"] = self.address;
    dict[@"company"] = self.company;
    dict[@"social"] = self.social;
    dict[@"extra"] = self.extra;
    dict[@"updateDt"] = @(self.updateDt);
    dict[@"deleted"] = @(self.deleted);
    return dict;
}
@end
