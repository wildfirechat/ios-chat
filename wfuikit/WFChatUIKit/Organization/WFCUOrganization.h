//
//  WFCUOrganization.h
//  WFChatUIKit
//
//  Created by Rain on 2022/12/25.
//  Copyright © 2022 WildfireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUOrganization : NSObject
@property(nonatomic, assign)NSInteger organizationId;
@property(nonatomic, assign)NSInteger parentId;
@property(nonatomic, strong)NSString *managerId;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *desc;
@property(nonatomic, strong)NSString *portraitUrl;
@property(nonatomic, strong)NSString *tel;
@property(nonatomic, strong)NSString *office;
@property(nonatomic, strong)NSString *groupId;
@property(nonatomic, assign)NSInteger memberCount;
@property(nonatomic, assign)NSInteger sort;
@property(nonatomic, assign)long long updateDt;
@property(nonatomic, assign)long long createDt;

+ (WFCUOrganization *)fromDict:(NSDictionary *)dict;
- (NSDictionary *)toDict;
@end

NS_ASSUME_NONNULL_END
