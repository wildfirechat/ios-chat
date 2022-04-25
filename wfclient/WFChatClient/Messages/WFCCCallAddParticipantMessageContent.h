//
//  WFCCCallAddParticipantMessageContent.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCChatClient.h>
#import <Foundation/Foundation.h>

@interface WFCCCallAddParticipantMessageContent : WFCCNotificationMessageContent
@property(nonatomic, strong)NSString *callId;
@property(nonatomic, strong)NSString *initiator;
@property(nonatomic, strong)NSString *pin;
@property(nonatomic, strong)NSArray<NSString *> *participants;
//[{"userId":"xxxx","acceptTime":13123123123,"joinTime":13123123123,"videoMuted":false}]
@property(nonatomic, strong)NSArray<NSDictionary *> *existParticipants;
@property(nonatomic, assign)BOOL audioOnly;
@end
