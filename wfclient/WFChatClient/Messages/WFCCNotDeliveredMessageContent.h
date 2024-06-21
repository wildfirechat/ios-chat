//
//  WFCCNotDeliveredMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"


/**
 没有送达消息
 */
@interface WFCCNotDeliveredMessageContent : WFCCNotificationMessageContent
/**
 请求的类型，1是发送消息，2撤回消息，3
 */
@property(nonatomic, assign)int type;
/**
 发送的消息ID
 */
@property(nonatomic, assign)int64_t messageUid;

/**
 是全部失败，还是部分失败
 */
@property(nonatomic, assign)BOOL allFailure;

/**
 当部分失败时，失败的用户id列表
 */
@property(nonatomic, strong)NSArray<NSString *> *userIds;

/**
 归属IM服务请求桥接服务出现的错误，有可能是桥接服务没有配置，或者不可用。
 */
@property(nonatomic, assign)int localImErrorCode;

/**
 归属桥接服务出现的错误
 */
@property(nonatomic, assign)int localBridgeErrorCode;

/**
 远端桥接服务出现的错误
 */
@property(nonatomic, assign)int remoteBridgeErrorCode;

/**
 远端IM服务出现的错误
 */
@property(nonatomic, assign)int remoteServerErrorCode;

/**
 错误提示信息
 */
@property(nonatomic, strong)NSString* errorMessage;
@end
