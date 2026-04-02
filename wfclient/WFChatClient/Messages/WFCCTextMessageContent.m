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
#import "WFCCDictionary.h"
#import "WFCCUtilities.h"

@implementation WFCCTextMessageContent
- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];
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
        WFCCDictionary *dictionary = [WFCCDictionary fromData:payload.binaryContent error:&__error];
        if (!__error) {
            NSDictionary *quoteDict = dictionary[@"quote"];
            if (quoteDict) {
                self.quoteInfo = [[WFCCQuoteInfo alloc] init];
                [self.quoteInfo decode:quoteDict];
            }
        }
    }
    
    // 表情反应从 content 字段解析（服务端存储在 MessagePayload.content）
    NSString *jsonString = payload.content;
    if (jsonString.length) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSError *__error = nil;
            WFCCDictionary *dictionary = [WFCCDictionary fromData:jsonData error:&__error];
            if (!__error) {
                NSArray *reactionsArray = dictionary[@"r"];
                if (reactionsArray.count) {
                    NSMutableArray *reactions = [NSMutableArray array];
                    for (NSDictionary *shortDict in reactionsArray) {
                        NSMutableDictionary *reaction = [NSMutableDictionary dictionary];
                        reaction[@"emoji"] = shortDict[@"e"];
                        reaction[@"users"] = shortDict[@"u"];
                        [reactions addObject:reaction];
                    }
                    self.reactions = reactions;
                }
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
    // 将 Markdown 转换为纯文本用于显示摘要
    return [WFCCUtilities plainTextFromMarkdown:self.text];
}
@end
