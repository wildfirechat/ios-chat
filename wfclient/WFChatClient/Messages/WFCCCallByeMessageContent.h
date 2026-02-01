//
//  WFCCCallByeMessageContent.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCChatClient.h>

/**
通话结束消息
*/
@interface WFCCCallByeMessageContent : WFCCMessageContent

/**
通话ID
*/
@property(nonatomic, strong)NSString *callId;

/**
结束原因（WFAVCallEndReason）
*/
@property(nonatomic, assign)int/*WFAVCallEndReason*/ endReason;

/**
邀请消息UID
*/
@property(nonatomic, assign)long long inviteMsgUid;
@end
