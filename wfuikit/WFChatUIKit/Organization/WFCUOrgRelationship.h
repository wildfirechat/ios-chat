//
//  WFCUOrgRelationship.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUOrgRelationship : NSObject
@property(nonatomic, strong)NSString *employeeId;
@property(nonatomic, assign)NSInteger organizationId;
@property(nonatomic, assign)NSInteger depth;
@property(nonatomic, assign)BOOL bottom;
@property(nonatomic, assign)NSInteger parentOrganizationId;
@end

NS_ASSUME_NONNULL_END
