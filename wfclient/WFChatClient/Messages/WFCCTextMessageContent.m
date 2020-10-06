//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCTextMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"


@implementation WFCCTextMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.contentType = [self.class getContentType];
    payload.searchableContent = self.text;
    payload.mentionedType = self.mentionedType;
    payload.mentionedTargets = self.mentionedTargets;
    if (self.quoteInfo) {
        NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
        [dataDict setObject:[self.quoteInfo encode] forKey:@"quote"];
        payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                               options:kNilOptions
                                                                                 error:nil];
    }
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.text = payload.searchableContent;
    self.mentionedType = payload.mentionedType;
    self.mentionedTargets = payload.mentionedTargets;
    if (payload.binaryContent.length) {
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                   options:kNilOptions
                                                                     error:&__error];
        if (!__error) {
            NSDictionary *quoteDict = dictionary[@"quote"];
            if (quoteDict) {
                self.quoteInfo = [[WFCCQuoteInfo alloc] init];
                [self.quoteInfo decode:quoteDict];
            }
        }
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_TEXT;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}


+ (instancetype)contentWith:(NSString *)text {
    WFCCTextMessageContent *content = [[WFCCTextMessageContent alloc] init];
    content.text = text;
    return content;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return self.text;
}
@end
