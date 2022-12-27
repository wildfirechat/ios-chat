//
//  WFCUEmployee.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface WFCUEmployee : NSObject
@property(nonatomic, strong)NSString *employeeId;
@property(nonatomic, assign)NSInteger organizationId;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, assign)NSInteger level;
@property(nonatomic, strong)NSString *mobile;
@property(nonatomic, strong)NSString *email;
@property(nonatomic, strong)NSString *ext;
@property(nonatomic, strong)NSString *office;
@property(nonatomic, strong)NSString *city;
@property(nonatomic, strong)NSString *portraitUrl;
@property(nonatomic, strong)NSString *jobNumber;
@property(nonatomic, strong)NSString *joinTime;
@property(nonatomic, assign)NSInteger type;
@property(nonatomic, assign)NSInteger gender;
@property(nonatomic, assign)NSInteger sort;
@property(nonatomic, assign)long long createDt;
@property(nonatomic, assign)long long updateDt;
@end

NS_ASSUME_NONNULL_END
