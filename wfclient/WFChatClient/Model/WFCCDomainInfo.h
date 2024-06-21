//
//  WFCCDomainInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

/**
 域信息
 */
@interface WFCCDomainInfo : WFCCJsonSerializer

/**
 域ID
 */
@property (nonatomic, strong)NSString *domainId;

/**
 域的名称
 */
@property (nonatomic, strong)NSString *name;

/**
 域的描述
 */
@property (nonatomic, strong)NSString *desc;

/**
 域的邮件地址
 */
@property (nonatomic, strong)NSString *email;

/**
 域的电话
 */
@property (nonatomic, strong)NSString *tel;

/**
 域的地址
 */
@property (nonatomic, strong)NSString *address;

/**
 群的额外信息
 */
@property (nonatomic, strong)NSString *extra;

/**
 域的最后更新日期
 */
@property (nonatomic, assign)long long updateDt;
@end
