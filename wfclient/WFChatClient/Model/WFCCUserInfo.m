//
//  WFCCUserInfo.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCUserInfo.h"
#import "WFCCUtilities.h"

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

- (NSString *)readableName {
    BOOL isExternal = [WFCCUtilities isExternalTarget:self.userId];
    NSString *name;
    if (self.friendAlias.length > 0) {
        name = self.friendAlias;
    } else if(self.groupAlias.length > 0) {
        name = self.groupAlias;
    } else if (self.displayName.length > 0) {
        name = self.displayName;
    } else {
        if(isExternal) {
            name = [WFCCUtilities getTargetWithoutDomain:self.userId];
        } else {
            name =  self.userId;
        }
    }
    if(isExternal) {
        NSString *domainId = [WFCCUtilities getExternalDomain:self.userId];
        WFCCDomainInfo *domainInfo = [[WFCCIMService sharedWFCIMService] getDomainInfo:domainId refresh:NO];
        if(domainInfo.name.length) {
            name = [NSString stringWithFormat:@"%@@%@", name, domainInfo.name];
        } else {
            name = [NSString stringWithFormat:@"%@@%@", name, domainId];
        }
    }
    
    return name;
}
@end
