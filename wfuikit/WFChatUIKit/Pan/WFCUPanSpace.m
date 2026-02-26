//
//  WFCUPanSpace.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanSpace.h"

@implementation WFCUPanSpace

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    WFCUPanSpace *space = [[WFCUPanSpace alloc] init];
    space.spaceId = [dict[@"id"] integerValue];
    space.ownerId = dict[@"ownerId"];
    space.name = dict[@"name"];
    space.totalQuota = [dict[@"totalQuota"] longLongValue];
    space.usedQuota = [dict[@"usedQuota"] longLongValue];
    space.fileCount = [dict[@"fileCount"] integerValue];
    space.folderCount = [dict[@"folderCount"] integerValue];
    space.autoInit = [dict[@"autoInit"] boolValue];
    space.createdAt = dict[@"createdAt"];
    space.canManage = [dict[@"canManage"] boolValue];
    
    NSString *typeStr = dict[@"spaceType"];
    if ([typeStr isEqualToString:@"GLOBAL_PUBLIC"]) {
        space.spaceType = WFCUPanSpaceTypeGlobalPublic;
    } else if ([typeStr isEqualToString:@"DEPT_PUBLIC"]) {
        space.spaceType = WFCUPanSpaceTypeDeptPublic;
    } else if ([typeStr isEqualToString:@"DEPT_PRIVATE"]) {
        space.spaceType = WFCUPanSpaceTypeDeptPrivate;
    } else if ([typeStr isEqualToString:@"USER_PUBLIC"]) {
        space.spaceType = WFCUPanSpaceTypeUserPublic;
    } else if ([typeStr isEqualToString:@"USER_PRIVATE"]) {
        space.spaceType = WFCUPanSpaceTypeUserPrivate;
    }
    
    return space;
}

@end
