//
//  WFCCUserInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"
/**
 用户信息
 */
@interface WFCCUserInfo : WFCCJsonSerializer

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

/**
 是否被删除用户
 */
@property (nonatomic, assign) int deleted;


/**
 辅助方法，返回可读的名称，如果有备注返回备注，如果有群昵称，显示群昵称，如果都没有返回用户昵称。
 */
@property(nonatomic, readonly)NSString *readableName;

- (void)cloneFrom:(WFCCUserInfo *)other;

@end
