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

 - GroupType_Normal: 管理员和群主才能加人和退群，修改群信息。
 - GroupType_Free: 所有人都能加人、退群和修改群信息
 - GroupType_Restricted: 带有群管理功能
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
@property (nonatomic, strong)NSString *extra;

/**
 群禁言状态，0 关闭群禁言；1 开启群禁言
 */
@property (nonatomic, assign)int mute;

/**
 加群申请状态，0 不限制加入（用户可以自己加群或被普通群成员拉入）；1 普通群成员可以拉人进群；2 只有群管理才能拉人
 */
@property (nonatomic, assign)int joinType;

/**
 群成员私聊状态，0 允许私聊；1 不允许私聊
 */
@property (nonatomic, assign)int privateChat;

/**
 群搜索状态，0 群可以被搜索到；1 群不会被搜索到
 */
@property (nonatomic, assign)int searchable;

/**
 群成员是否可以加载加入之前的历史消息，0不可以；1可以
 */
@property (nonatomic, assign)int historyMessage;

/**
 群的最大成员数，可以通过server api来修改
 */
@property (nonatomic, assign)int maxMemberCount;

/**
 群的最后更新日期
 */
@property (nonatomic, assign)long long updateTimestamp;

@end
