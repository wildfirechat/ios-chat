//
//  WFCCChatroomInfo.h
//  WFChatClient
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCJsonSerializer.h"

/**
聊天室信息
*/
@interface WFCCChatroomInfo : WFCCJsonSerializer

/**
聊天室ID
*/
@property(nonatomic, strong)NSString *chatroomId;

/**
聊天室标题
*/
@property(nonatomic, strong)NSString *title;

/**
聊天室描述
*/
@property(nonatomic, strong)NSString *desc;

/**
聊天室头像
*/
@property(nonatomic, strong)NSString *portrait;

/**
扩展信息
*/
@property(nonatomic, strong)NSString *extra;

/**
聊天室状态，0 normal; 1 not started; 2 end
*/
@property(nonatomic, assign)int state;

/**
成员数量
*/
@property(nonatomic, assign)int memberCount;

/**
创建时间
*/
@property(nonatomic, assign)long long createDt;

/**
更新时间
*/
@property(nonatomic, assign)long long updateDt;
@end
