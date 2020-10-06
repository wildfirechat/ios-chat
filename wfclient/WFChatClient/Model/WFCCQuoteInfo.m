//
//  WFCCQuoteInfo.m
//  WFChatClient
//
//  Created by dali on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCCQuoteInfo.h"
#import "WFCCUserInfo.h"
#import "WFCCMessage.h"
#import "WFCCIMService.h"


@implementation WFCCQuoteInfo
- (instancetype)initWithMessageUid:(long long)messageUid {
    self = [super init];
    if (self) {
        WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
        if (msg) {
            self.messageUid = messageUid;
            self.userId = msg.fromUser;
            WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.fromUser refresh:NO];
            self.userDisplayName = user.displayName;
            self.messageDigest = [msg.content digest:msg];
            if (self.messageDigest.length > 48) {
                self.messageDigest = [self.messageDigest substringToIndex:48];
            }
        } else {
            return nil;
        }
    }
    return self;
}

- (NSDictionary *)encode {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@(self.messageUid) forKey:@"u"];
    if (self.userId.length) {
        [dict setObject:self.userId forKey:@"i"];
    }
    if (self.userDisplayName.length) {
        [dict setObject:self.userDisplayName forKey:@"n"];
    }
    if (self.messageDigest.length) {
        [dict setObject:self.messageDigest forKey:@"d"];
    }
    return [dict copy];
}

- (void)decode:(NSDictionary *)dictData {
    self.messageUid = [dictData[@"u"] longLongValue];
    self.userId = dictData[@"i"];
    self.userDisplayName = dictData[@"n"];
    self.messageDigest = dictData[@"d"];
}
@end
