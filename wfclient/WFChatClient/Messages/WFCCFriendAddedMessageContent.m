//
//  WFCCFriendAddedMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCFriendAddedMessageContent.h"
#import "WFCCIMService.h"
#import "WFCCNetworkService.h"
#import "Common.h"

@implementation WFCCFriendAddedMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
}

+ (int)getContentType {
    return MESSAGE_FRIEND_ADDED_NOTIFICATION;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST;
}



+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)formatNotification:(WFCCMessage *)message {
    return WFCCString(@"FriendAddedTip");
}

- (NSString *)digest:(WFCCMessage *)message {
    return [self formatNotification:message];
}
@end
