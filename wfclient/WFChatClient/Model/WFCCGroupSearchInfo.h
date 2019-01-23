//
//  WFCCGroupSearchInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCGroupInfo.h"

/**
 群组搜索信息
 */
@interface WFCCGroupSearchInfo : NSObject

/**
 命中的群组
 */
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;

/**
 命中的类型 0, 名字群组名字； 1，命中群成员名称；2，都命中
 */
@property (nonatomic, assign)int marchType;

/**
 命中群成员名称
 */
@property (nonatomic, strong)NSArray *marchedMemberNames;

/**
 搜索的关键字
 */
@property (nonatomic, strong)NSString *keyword;

@end
