//
//  ArchivedMessage.m
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "ArchivedMessage.h"

// 辅助函数：将NSNull转换为nil
static id NilIfNull(id obj) {
    return [obj isKindOfClass:[NSNull class]] ? nil : obj;
}

@implementation ArchivedMessage

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    ArchivedMessage *message = [[ArchivedMessage alloc] init];
    message.mid = [NilIfNull(dict[@"mid"]) longLongValue];
    message.senderId = NilIfNull(dict[@"senderId"]) ?: @"";
    message.convType = [NilIfNull(dict[@"convType"]) intValue];
    message.convTarget = NilIfNull(dict[@"convTarget"]) ?: @"";
    message.convLine = [NilIfNull(dict[@"convLine"]) intValue];
    message.contentType = [NilIfNull(dict[@"contentType"]) intValue];
    
    // 解析 payload
    NSDictionary *payloadDict = NilIfNull(dict[@"payload"]);
    if (payloadDict) {
        message.payload = [ArchiveMessagePayload fromDictionary:payloadDict];
    }
    
    message.searchableKey = NilIfNull(dict[@"searchableKey"]);
    message.userId = NilIfNull(dict[@"userId"]) ?: @"";
    message.messageDt = NilIfNull(dict[@"messageDt"]) ?: @"";
    message.userHash = [NilIfNull(dict[@"userHash"]) intValue];
    
    return message;
}

- (NSDate *)localMessageDate {
    if (!self.messageDt.length) {
        return [NSDate date];
    }
    
    // ISO 8601 格式解析
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    NSDate *date = [formatter dateFromString:self.messageDt];
    
    if (!date) {
        // 尝试不带毫秒的格式
        formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        date = [formatter dateFromString:self.messageDt];
    }
    
    return date ?: [NSDate date];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"ArchivedMessage(mid=%lld, sender=%@, convType=%d, convTarget=%@, contentType=%d)",
            self.mid, self.senderId, self.convType, self.convTarget, self.contentType];
}

@end
