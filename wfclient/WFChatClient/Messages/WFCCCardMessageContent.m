//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCCardMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCCardMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    payload.content = self.targetId;

    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.name) {
        [dataDict setObject:self.name forKey:@"n"];
    }
    if (self.displayName) {
        [dataDict setObject:self.displayName forKey:@"d"];
    }
    
    if (self.portrait) {
        [dataDict setObject:self.portrait forKey:@"p"];
    }
    if (self.type) {
        [dataDict setObject:@(self.type) forKey:@"t"];
    }
    if(self.fromUser) {
        [dataDict setObject:self.fromUser forKey:@"f"];
    }
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.targetId = payload.content;
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.name = dictionary[@"n"];
        self.displayName = dictionary[@"d"];
        self.portrait = dictionary[@"p"];
        self.type = [dictionary[@"t"] intValue];
        self.fromUser = dictionary[@"f"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CARD;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (instancetype)cardWithTarget:(NSString *)targetId type:(WFCCCardType)type from:(NSString *)fromUser {
    WFCCCardMessageContent *content = [[WFCCCardMessageContent alloc] init];
    content.targetId = targetId;
    content.type = type;
    content.fromUser = fromUser;
    if (type == 0) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:targetId refresh:NO];
        content.name = userInfo.name;
        content.displayName = userInfo.displayName;
        content.portrait = userInfo.portrait;
    } else if(type == 1) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:targetId refresh:NO];
        content.name = groupInfo.name;
        content.displayName = groupInfo.name;
        content.portrait = groupInfo.portrait;
    } else if(type == 3) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:targetId refresh:NO];
        content.name = channelInfo.name;
        content.displayName = channelInfo.name;
        content.portrait = channelInfo.portrait;
    }
    
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
    if (self.displayName.length) {
        return [NSString stringWithFormat:@"[名片]:%@", self.displayName];
    }
    return @"[名片]";
}
@end
