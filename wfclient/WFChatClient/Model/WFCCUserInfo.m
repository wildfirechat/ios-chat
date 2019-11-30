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
@end
