//
//  WFCCCallAddParticipantMessageContent.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCChatClient.h>
#import <Foundation/Foundation.h>

/**
通话添加参与者消息
*/
@interface WFCCCallAddParticipantMessageContent : WFCCNotificationMessageContent

/**
通话ID
*/
@property(nonatomic, strong)NSString *callId;

/**
发起者
*/
@property(nonatomic, strong)NSString *initiator;

/**
PIN码
*/
@property(nonatomic, strong)NSString *pin;

/**
参与者ID列表
*/
@property(nonatomic, strong)NSArray<NSString *> *participants;

/**
现有参与者列表，格式示例: [{"userId":"xxxx","acceptTime":13123123123,"joinTime":13123123123,"videoMuted":false}]
*/
@property(nonatomic, strong)NSArray<NSDictionary *> *existParticipants;

/**
是否仅音频
*/
@property(nonatomic, assign)BOOL audioOnly;

/**
是否自动接听
*/
@property(nonatomic, assign)BOOL autoAnswer;

/**
指定对方客户端ID
*/
@property(nonatomic, strong)NSString *clientId;
@end
