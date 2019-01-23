//
//  WFCCGroupInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 群类型

 - GroupType_Normal: 管理员和群主才能加人和退群，修改群信息
 - GroupType_Free: 所有人都能加人、退群和修改群信息
 - GroupType_Restricted: 普通成员只能退群，不能加人和修改群信息
 */
typedef NS_ENUM(NSInteger, WFCCGroupType) {
    GroupType_Normal = 0,
    GroupType_Free = 1,
    GroupType_Restricted = 2,
} ;

/**
 群信息
 */
@interface WFCCGroupInfo : NSObject

/**
 群类型
 */
@property (nonatomic, assign)WFCCGroupType type;

/**
 群ID
 */
@property (nonatomic, strong)NSString *target;

/**
 群名
 */
@property (nonatomic, strong)NSString *name;

/**
 群头像
 */
@property (nonatomic, strong)NSString *portrait;

/**
 成员数
 */
@property (nonatomic, assign)NSUInteger memberCount;

/**
 群主
 */
@property (nonatomic, strong)NSString *owner;

/**
 扩展信息
 */
@property (nonatomic, strong)NSData *extra;

@end
