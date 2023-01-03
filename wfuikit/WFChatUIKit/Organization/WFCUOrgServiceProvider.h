//
//  WFCUAppService.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCUOrganization;
@class WFCUEmployee;
@class WFCUOrgRelationship;
@class WFCUOrganizationEx;
@class WFCUEmployeeEx;

@protocol WFCUOrgServiceProvider <NSObject>
- (void)getRelationship:(NSString *)employeeId
                success:(void(^)(NSArray<WFCUOrgRelationship *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getRootOrganization:(void(^)(NSArray<WFCUOrganization *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganizationEx:(NSInteger)organizationId
                    success:(void(^)(WFCUOrganizationEx *path))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganizations:(NSArray<NSNumber *> *)organizationIds
                 success:(void(^)(NSArray<WFCUOrganization *> *organizations))successBlock
                   error:(void(^)(int error_code))errorBlock;

- (void)getBatchOrgEmployees:(NSArray<NSNumber *> *)orgIds
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrgEmployees:(NSInteger)orgId
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getEmployee:(NSString *)employeeId
            success:(void(^)(WFCUEmployee *employee))successBlock
              error:(void(^)(int error_code))errorBlock;


- (void)getEmployeeEx:(NSString *)employeeId
              success:(void(^)(WFCUEmployeeEx *employeeEx))successBlock
                error:(void(^)(int error_code))errorBlock;

- (void)searchEmployee:(NSInteger)organizationId
               keyword:(NSString *)keyword
               success:(void(^)(NSArray<WFCUEmployee *> *employees))successBlock
                 error:(void(^)(int error_code))errorBlock;
@end

NS_ASSUME_NONNULL_END
