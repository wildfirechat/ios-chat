//
//  WFCCMarkUnreadMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCStartSecretChatMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCStartSecretChatMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CREATE_SECRET_CHAT;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    WFCCSecretChatInfo *info = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:message.conversation.target];
    if (!info) {
        return WFCCString(@"SecretChatNotAvailable");
    }

    WFCCSecretChatState state = info.state;
    if(state == SecretChatState_Starting) {
        return WFCCString(@"SecretChatWaitingResponse");
    } else if(state == SecretChatState_Accepting) {
        return WFCCString(@"SecretChatEstablishing");
    } else if(state == SecretChatState_Established) {
        return WFCCString(@"SecretChatEstablished");
    } else if(state == SecretChatState_Canceled) {
        return WFCCString(@"SecretChatCanceled");
    } else {
        return WFCCString(@"SecretChatNotAvailable");
    }
}
@end
