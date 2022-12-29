//
//  WFCUEmployeeEx.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/29.
//  Copyright © 2022 Wildfire Chat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WFCUEmployee;
@class WFCUOrgRelationship;
NS_ASSUME_NONNULL_BEGIN

@interface WFCUEmployeeEx : NSObject
@property(nonatomic, strong)NSString *employeeId;
@property(nonatomic, strong)WFCUEmployee *employee;
@property(nonatomic, strong)NSArray<WFCUOrgRelationship *> *relationships;
@end

NS_ASSUME_NONNULL_END
