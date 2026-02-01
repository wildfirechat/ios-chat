//
//  WFCCUnreadCount.h
//  WFChatClient
//
//  Created by WF Chat on 2018/9/30.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
未读数统计
*/
@interface WFCCUnreadCount : WFCCJsonSerializer

/**
构造未读数统计

@param unread 未读数
@param mention @我数量
@param mentionAll @所有人数量
@return 未读数统计实例
*/
+(instancetype)countOf:(int)unread mention:(int)mention mentionAll:(int)mentionAll;

/**
未读数
*/
@property(nonatomic, assign)int unread;

/**
@我数量
*/
@property(nonatomic, assign)int unreadMention;

/**
@所有人数量
*/
@property(nonatomic, assign)int unreadMentionAll;
@end

NS_ASSUME_NONNULL_END
