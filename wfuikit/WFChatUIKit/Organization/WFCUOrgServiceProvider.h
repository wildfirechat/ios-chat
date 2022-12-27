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
@protocol WFCUOrgServiceProvider <NSObject>
- (void)getRelationship:(NSString *)employeeId
                success:(void(^)(NSArray<WFCUOrgRelationship *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getRootOrganization:(void(^)(NSArray<WFCUOrganization *> *))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganization:(int)organizationId
                success:(void(^)(WFCUOrganization *organization, NSArray<WFCUOrganization *> *subOrganization, NSArray<WFCUEmployee *> *employees))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getOrganizations:(NSArray<NSNumber *> *)organizationIds
                 success:(void(^)(NSArray<WFCUOrganization *> *organizations))successBlock
                   error:(void(^)(int error_code))errorBlock;
@end

NS_ASSUME_NONNULL_END
