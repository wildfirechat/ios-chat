//
//  WFCCGroupSearchInfo.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCGroupInfo.h"
#import "WFCCJsonSerializer.h"

/**
 搜索群组匹配类型mask

 - GroupSearchMarchTypeMask_Group_Name: 匹配群组名称
 - GroupSearchMarchTypeMask_Member_Name: 匹配群成员昵称
 - GroupSearchMarchTypeMask_Member_Alias:  匹配群成员群昵称
 - GroupSearchMarchTypeMask_Group_Remark: 匹配群组remark
 */
typedef NS_ENUM(NSInteger, WFCCGroupSearchMarchTypeMask) {
    GroupSearchMarchTypeMask_Group_Name = 0x01,
    GroupSearchMarchTypeMask_Member_Name = 0x02,
    GroupSearchMarchTypeMask_Member_Alias = 0x04,
    GroupSearchMarchTypeMask_Group_Remark = 0x08
};

/**
 群组搜索信息
 */
@interface WFCCGroupSearchInfo : WFCCJsonSerializer

/**
 命中的群组
 */
@property (nonatomic, strong)WFCCGroupInfo *groupInfo;

/**
 命中的类型，请参考WFCCGroupSearchMarchTypeMask
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
