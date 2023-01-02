//
//  WFCUOrganization.m
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import "WFCUOrganization.h"

@implementation WFCUOrganization
+ (WFCUOrganization *)fromDict:(NSDictionary *)dict {
    WFCUOrganization *org = [[WFCUOrganization alloc] init];
    org.organizationId = [dict[@"id"] intValue];
    org.parentId = [dict[@"parentId"] intValue];
    org.managerId = dict[@"managerId"];
    org.name = dict[@"name"];
    org.desc = dict[@"desc"];
    org.portraitUrl = dict[@"portraitUrl"];
    org.tel = dict[@"tel"];
    org.office = dict[@"office"];
    org.groupId = dict[@"groupId"];
    org.memberCount = [dict[@"memberCount"] intValue];
    org.sort = [dict[@"sort"] intValue];
    org.updateDt = [dict[@"updateDt"] longLongValue];
    org.createDt = [dict[@"createDt"] longLongValue];
    return org;
}

- (NSDictionary *)toDict {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"id"] = @(self.organizationId);
    dict[@"parentId"] = @(self.parentId);
    dict[@"managerId"] = self.managerId;
    dict[@"name"] = self.name;
    dict[@"desc"] = self.desc;
    dict[@"portraitUrl"] = self.portraitUrl;
    dict[@"tel"] = self.tel;
    dict[@"office"] = self.office;
    dict[@"groupId"] = self.groupId;
    dict[@"memberCount"] = @(self.memberCount);
    dict[@"sort"] = @(self.sort);
    dict[@"updateDt"] = @(self.updateDt);
    dict[@"createDt"] = @(self.createDt);
    return dict;
}
@end
