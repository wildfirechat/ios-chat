//
//  WFCCGroupMember.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/30.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 群成员类型

 - Member_Type_Normal: 普通成员
 - Member_Type_Manager: 管理员
 - Member_Type_Owner: 群主
 */
typedef NS_ENUM(NSInteger, WFCCGroupMemberType) {
    Member_Type_Normal = 0,
    Member_Type_Manager,
    Member_Type_Owner,
} ;

/**
 群成员信息
 */
@interface WFCCGroupMember : NSObject

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
 群成员类型
 */
@property(nonatomic, assign)WFCCGroupMemberType type;

@end
