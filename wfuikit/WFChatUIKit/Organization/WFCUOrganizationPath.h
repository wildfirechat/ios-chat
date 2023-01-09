//
//  WFCUOrganizationPath.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/29.
//  Copyright © 2022 Wildfire Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WFCUOrganization;
@class WFCUEmployee;

NS_ASSUME_NONNULL_BEGIN

@interface WFCUOrganizationEx : NSObject
@property (nonatomic, assign)NSInteger organizationId;
@property(nonatomic, strong)WFCUOrganization *organization;
@property(nonatomic, strong)NSArray<WFCUOrganization *> *subOrganizations;
@property(nonatomic, strong)NSArray<WFCUEmployee *> *employees;
@end

NS_ASSUME_NONNULL_END
