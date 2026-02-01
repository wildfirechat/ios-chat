//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCChannelMenu.h"
#import "WFCCJsonSerializer.h"

/**
频道信息
*/
@interface WFCCChannelInfo : WFCCJsonSerializer

/**
频道ID
*/
@property(nonatomic, strong)NSString *channelId;

/**
频道名称
*/
@property(nonatomic, strong)NSString *name;

/**
频道头像
*/
@property(nonatomic, strong)NSString *portrait;

/**
频道所有者
*/
@property(nonatomic, strong)NSString *owner;

/**
频道描述
*/
@property(nonatomic, strong)NSString *desc;

/**
扩展信息
*/
@property(nonatomic, strong)NSString *extra;

/**
密钥
*/
@property(nonatomic, strong)NSString *secret;

/**
回调地址
*/
@property(nonatomic, strong)NSString *callback;

/**
频道状态，参考https://docs.wildfirechat.net/base_knowledge/channel.html##频道状态
*/
@property(nonatomic, assign)int status;

/**
更新时间
*/
@property(nonatomic, assign)long long updateDt;

/**
频道菜单列表
*/
@property(nonatomic, strong)NSArray<WFCCChannelMenu *> *menus;
@end
