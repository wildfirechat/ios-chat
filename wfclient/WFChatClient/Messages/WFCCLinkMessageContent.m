//
//  WFCCTextMessageContent.m
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCLinkMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"
#import "WFCCDictionary.h"

@implementation WFCCLinkMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
    payload.searchableContent = self.title;
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    if (self.contentDigest) {
        [dataDict setObject:self.contentDigest forKey:@"d"];
    }
    if (self.url) {
        [dataDict setObject:self.url forKey:@"u"];
    }
    
    if (self.thumbnailUrl) {
        [dataDict setObject:self.thumbnailUrl forKey:@"t"];
    }
    
    payload.binaryContent = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                           options:kNilOptions
                                                                             error:nil];
    
    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];
    self.title = payload.searchableContent;
    
    NSError *__error = nil;
    WFCCDictionary *dictionary = [WFCCDictionary fromData:payload.binaryContent error:&__error];
    if (!__error) {
        self.contentDigest = dictionary[@"d"];
        self.url = dictionary[@"u"];
        self.thumbnailUrl = dictionary[@"t"];
    }
}

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_LINK;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

- (NSString *)digest:(WFCCMessage *)message {
  return [NSString stringWithFormat:@"[链接]%@", self.title];
}
@end
