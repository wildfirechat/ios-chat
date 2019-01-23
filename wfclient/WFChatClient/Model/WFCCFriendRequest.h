//
//  WFCCFriendRequest.h
//  WFChatClient
//
//  Created by heavyrain on 2017/10/17.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 好友请求
 */
@interface WFCCFriendRequest : NSObject

/**
 方向
 */
@property(nonatomic, assign)int direction;

/**
 ID
 */
@property(nonatomic, strong)NSString *target;

/**
 请求说明
 */
@property(nonatomic, strong)NSString *reason;

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
