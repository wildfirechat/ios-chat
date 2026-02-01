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
聊天室成员信息
*/
@interface WFCCChatroomMemberInfo : WFCCJsonSerializer

/**
成员数量
*/
@property(nonatomic, assign)int memberCount;

/**
成员ID列表
*/
@property(nonatomic, strong)NSArray<NSString *> *members;
@end
