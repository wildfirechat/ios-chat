//
//  WFCUOrganizationCache.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUOrganization;
@class WFCUEmployee;
@class WFCUOrgRelationship;

@interface WFCUOrganizationCache : NSObject
+ (WFCUOrganizationCache *)sharedCache;

@property(nonatomic, strong)NSArray<NSNumber *> *rootOrganizationIds;
@property(nonatomic, strong)NSArray<NSNumber *> *bottomOrganizationIds;

- (NSArray<WFCUOrgRelationship *> *)getRelationship:(NSString *)employeeId;
- (void)put:(NSString *)employeeId relationship:(NSArray<WFCUOrgRelationship *> *)relationships;

- (WFCUEmployee *)getEmployee:(NSString *)employeeId;
- (void)put:(NSString *)employeeId employee:(WFCUEmployee *)employee;

- (WFCUOrganization *)getOrganization:(NSUInteger)orgnaizationId;
- (void)put:(NSUInteger)orgnaizationId organization:(WFCUOrganization *)orgnaization;
@end

NS_ASSUME_NONNULL_END
