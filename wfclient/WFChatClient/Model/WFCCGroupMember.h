//
//  WFCCGroupMember.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/30.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

/**
 群成员类型

 - Member_Type_Normal: 普通成员
 - Member_Type_Manager: 管理员
 - Member_Type_Owner: 群主
 - Member_Type_Muted: 被禁言
 - Member_Type_Deleted: 已删除成员，仅在群成员变动回调中存在。
 - Member_Type_Allowed: 被允许发言
 */
typedef NS_ENUM(NSInteger, WFCCGroupMemberType) {
    Member_Type_Normal = 0,
    Member_Type_Manager,
    Member_Type_Owner,
    Member_Type_Muted,
    Member_Type_Deleted,
    Member_Type_Allowed = 5
} ;

/**
 群成员信息
 */
@interface WFCCGroupMember : WFCCJsonSerializer

/**
 群ID
 */
@property(nonatomic, strong)NSString *groupId;

/**
 群成员ID
 */
@property(nonatomic, strong)NSString *memberId;

/**
 群昵称
 */
@property(nonatomic, strong)NSString *alias;

/**
 群成员扩展信息
 */
@property(nonatomic, strong)NSString *extra;

/**
 群成员类型
 */
@property(nonatomic, assign)WFCCGroupMemberType type;

/**
 群成员加入时间戳
*/
@property(nonatomic, assign)long long createTime;

@end
