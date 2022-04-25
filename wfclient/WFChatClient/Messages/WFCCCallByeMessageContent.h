//
//  WFCCCallByeMessageContent.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <WFChatClient/WFCChatClient.h>
@interface WFCCCallByeMessageContent : WFCCMessageContent
@property(nonatomic, strong)NSString *callId;
@property(nonatomic, assign)int/*WFAVCallEndReason*/ endReason;
@property(nonatomic, assign)long long inviteMsgUid;
@end
