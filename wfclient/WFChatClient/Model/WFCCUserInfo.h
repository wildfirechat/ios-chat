//
//  WFCCUserInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 用户信息
 */
@interface WFCCUserInfo : NSObject

/**
 用户ID
 */
@property (nonatomic, strong)NSString *userId;

/**
 名称
 */
@property (nonatomic, strong)NSString *name;

/**
 显示的名称
 */
@property (nonatomic, strong)NSString *displayName;

/**
 性别
 */
@property (nonatomic, assign)int gender;

/**
 头像
 */
@property (nonatomic, strong)NSString *portrait;

/**
 手机号
 */
@property (nonatomic, strong)NSString *mobile;

/**
 邮箱
 */
@property (nonatomic, strong)NSString *email;

/**
 地址
 */
@property (nonatomic, strong)NSString *address;

/**
 公司信息
 */
@property (nonatomic, strong)NSString *company;

/**
 社交信息
 */
@property (nonatomic, strong)NSString *social;

/**
 扩展信息
 */
@property (nonatomic, strong)NSString *extra;

/**
 好友备注
 */
@property (nonatomic, strong)NSString *friendAlias;

/**
 群昵称
 */
@property (nonatomic, strong)NSString *groupAlias;

/**
 更新时间
 */
@property (nonatomic, assign)long long updateDt;

/**
 用户类型
 */
@property (nonatomic, assign) int type;

- (void)cloneFrom:(WFCCUserInfo *)other;

@end
