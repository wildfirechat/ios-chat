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
    payload.content = self.userId;

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
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                            options:kNilOptions
                                                              error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.userId = payload.content;
    
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                               options:kNilOptions
                                                                 error:&__error];
    if (!__error) {
        self.name = dictionary[@"n"];
        self.displayName = dictionary[@"d"];
        self.portrait = dictionary[@"p"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_CARD;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (instancetype)cardWithUserId:(NSString *)userId {
    WFCCCardMessageContent *content = [[WFCCCardMessageContent alloc] init];
    content.userId = userId;
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    content.name = userInfo.name;
    content.displayName = userInfo.displayName;
    content.portrait = userInfo.portrait;
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
