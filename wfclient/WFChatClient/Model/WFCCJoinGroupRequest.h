//
//  WFCCFriendRequest.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"
/**
 加群请求
 */
@interface WFCCJoinGroupRequest : WFCCJsonSerializer

/**
 要加入的群组
 */
@property(nonatomic, strong)NSString *groupId;

/**
 要加入的成员
 */
@property(nonatomic, strong)NSString *memberId;

/**
 发起邀请的用户ID
 */
@property(nonatomic, strong)NSString *requestUserId;

/**
 批准加入的用户ID
 */
@property(nonatomic, strong)NSString *acceptUserId;

/**
 请求说明
 */
@property(nonatomic, strong)NSString *reason;

/**
 请求扩展信息
 */
@property(nonatomic, strong)NSString *extra;

/**
 接受状态
 */
@property(nonatomic, assign)int status;

/**
 已读
 */
@property(nonatomic, assign)int readStatus;

/**
 发起时间
 */
@property(nonatomic, assign)long long timestamp;

@end
