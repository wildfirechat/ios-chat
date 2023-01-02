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
@class WFCUOrganizationEx;
@class WFCUEmployeeEx;

//根节点更新完成
extern NSString *kRootOrganizationUpdated;
//我的组织关系更新完成
extern NSString *kMyOrganizationUpdated;
//组织信息更新完成
extern NSString *kOrganizationUpdated;
//组织层级信息更新完成，包括组织信息，子组织信息，当前层级员工信息
extern NSString *kOrganizationExUpdated;
//员工信息更新完成
extern NSString *kEmployeeUpdated;
//员工附加信息更新完成，包括员工信息及员工的关系
extern NSString *kEmployeeExUpdated;
//关系信息更新完成
extern NSString *kOrgRelationUpdated;

@interface WFCUOrganizationCache : NSObject
+ (WFCUOrganizationCache *)sharedCache;

@property(nonatomic, strong)NSArray<NSNumber *> *rootOrganizationIds;
@property(nonatomic, strong)NSArray<NSNumber *> *bottomOrganizationIds;

- (void)loadMyOrganizationInfos;
- (void)clearCaches;

- (void)getRelationship:(NSString *)employeeId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *employeeId, NSArray<WFCUOrgRelationship *> *rss))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (NSArray<WFCUOrgRelationship *> *)getRelationship:(NSString *)employeeId refresh:(BOOL)refresh;
- (WFCUEmployee *)getEmployee:(NSString *)employeeId refresh:(BOOL)refresh;
- (WFCUEmployeeEx *)getEmployeeEx:(NSString *)employeeId refresh:(BOOL)refresh;
- (WFCUOrganization *)getOrganization:(NSInteger)orgnaizationId refresh:(BOOL)refresh;


- (void)getOrganizationEx:(NSInteger)organizationId
                  refresh:(BOOL)refresh
                  success:(void(^)(NSInteger organizationId, WFCUOrganizationEx *ex))successBlock
                    error:(void(^)(int error_code))errorBlock;

- (WFCUOrganizationEx *)getOrganizationEx:(NSInteger)organizationId refresh:(BOOL)refresh;
@end

NS_ASSUME_NONNULL_END
