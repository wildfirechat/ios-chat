//
//  WFCCChannelMenu.h
//  WFChatClient
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
频道菜单项
*/
@interface WFCCChannelMenu : WFCCJsonSerializer

/**
菜单ID
*/
@property(nonatomic, strong)NSString *menuId;

/**
菜单类型
*/
@property(nonatomic, strong)NSString *type;

/**
菜单名称
*/
@property(nonatomic, strong)NSString *name;

/**
菜单键值
*/
@property(nonatomic, strong)NSString *key;

/**
菜单URL
*/
@property(nonatomic, strong)NSString *url;

/**
媒体ID
*/
@property(nonatomic, strong)NSString *mediaId;

/**
文章ID
*/
@property(nonatomic, strong)NSString *articleId;

/**
应用ID
*/
@property(nonatomic, strong)NSString *appId;

/**
应用页面
*/
@property(nonatomic, strong)NSString *appPage;

/**
扩展信息
*/
@property(nonatomic, strong)NSString *extra;

/**
子菜单列表
*/
@property(nonatomic, strong)NSArray<WFCCChannelMenu *> *subMenus;
@end

NS_ASSUME_NONNULL_END
