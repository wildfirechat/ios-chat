//
//  WFCUOrganizationCache.m
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import "WFCUOrganizationCache.h"
#import "WFCUEmployee.h"
#import "WFCUOrganization.h"
#import "WFCUOrgRelationship.h"

static WFCUOrganizationCache *sharedSingleton = nil;

@interface WFCUOrganizationCache ()
@property(nonatomic, strong)NSMutableDictionary<NSString *, WFCUEmployee *> *employeeDict;
@property(nonatomic, strong)NSMutableDictionary<NSNumber *, WFCUOrganization *> *organizationDict;
@property(nonatomic, strong)NSMutableDictionary<NSString *, NSArray<WFCUOrgRelationship *> *> *relationshipDict;
@end

@implementation WFCUOrganizationCache
+ (WFCUOrganizationCache *)sharedCache {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUOrganizationCache alloc] init];
                sharedSingleton.employeeDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.organizationDict = [[NSMutableDictionary alloc] init];
                sharedSingleton.relationshipDict = [[NSMutableDictionary alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)put:(NSString *)employeeId relationship:(NSArray<WFCUOrgRelationship *> *)relationships {
    self.relationshipDict[employeeId] = relationships;
}

- (NSArray<WFCUOrgRelationship *> *)getRelationship:(NSString *)employeeId {
    return self.relationshipDict[employeeId];
}

- (void)put:(NSString *)employeeId employee:(WFCUEmployee *)employee {
    self.employeeDict[employeeId] = employee;
}

- (WFCUEmployee *)getEmployee:(NSString *)employeeId {
    return self.employeeDict[employeeId];
}

- (void)put:(NSUInteger)orgnaizationId organization:(WFCUOrganization *)orgnaization {
    self.organizationDict[@(orgnaizationId)] = orgnaization;
}

- (WFCUOrganization *)getOrganization:(NSUInteger)orgnaizationId {
    return self.organizationDict[@(orgnaizationId)];
}
@end
