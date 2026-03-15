//
//  ArchiveMessagePayload.m
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "ArchiveMessagePayload.h"
#import <WFChatClient/WFCChatClient.h>

// 辅助函数：将NSNull转换为nil
static id NilIfNull(id obj) {
    return [obj isKindOfClass:[NSNull class]] ? nil : obj;
}

@implementation ArchiveMessagePayload

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    ArchiveMessagePayload *payload = [[ArchiveMessagePayload alloc] init];
    payload.type = [NilIfNull(dict[@"type"]) intValue];
    payload.content = NilIfNull(dict[@"content"]);
    payload.searchableContent = NilIfNull(dict[@"searchableContent"]);
    payload.pushContent = NilIfNull(dict[@"pushContent"]);
    payload.pushData = NilIfNull(dict[@"pushData"]);
    payload.mentionedType = [NilIfNull(dict[@"mentionedType"]) intValue];
    payload.mentionedTargets = NilIfNull(dict[@"mentionedTargets"]);
    payload.remoteMediaUrl = NilIfNull(dict[@"remoteMediaUrl"]);
    payload.extra = NilIfNull(dict[@"extra"]);
    payload.binaryContent = NilIfNull(dict[@"binaryContent"]);
    payload.subType = [NilIfNull(dict[@"subType"]) intValue];
    
    return payload;
}

- (WFCCMessagePayload *)toSDKPayload:(int)contentType {
    WFCCMediaMessagePayload *sdkPayload = [[WFCCMediaMessagePayload alloc] init];
    
    sdkPayload.contentType = contentType;
    sdkPayload.searchableContent = self.searchableContent;
    sdkPayload.pushContent = self.pushContent;
    sdkPayload.pushData = self.pushData;
    sdkPayload.content = self.content;
    sdkPayload.mentionedType = self.mentionedType;
    sdkPayload.mentionedTargets = self.mentionedTargets;
    sdkPayload.remoteMediaUrl = self.remoteMediaUrl;
    sdkPayload.extra = self.extra;
    
    // 如果有 binaryContent（Base64），转换为 NSData
    if (self.binaryContent.length > 0) {
        sdkPayload.binaryContent = [[NSData alloc] initWithBase64EncodedString:self.binaryContent
                                                                        options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    
    return sdkPayload;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ArchiveMessagePayload(type=%d, content=%@)", self.type, self.content];
}

@end
