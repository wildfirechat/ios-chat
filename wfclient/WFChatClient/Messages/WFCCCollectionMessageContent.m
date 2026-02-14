//
//  WFCCCollectionMessageContent.m
//  WFChatClient
//
//  Created by WFChat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCCollectionMessageContent.h"
#import "WFCCIMService.h"
#import "Common.h"

// 消息类型定义为17
#define MESSAGE_CONTENT_TYPE_COLLECTION 17

#pragma mark - WFCCCollectionEntry Implementation

@implementation WFCCCollectionEntry

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    WFCCCollectionEntry *entry = [[WFCCCollectionEntry alloc] init];
    entry.userId = dict[@"userId"];
    entry.content = dict[@"content"];
    entry.createdAt = [dict[@"createdAt"] longLongValue];

    return entry;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.userId) {
        dict[@"userId"] = self.userId;
    }
    if (self.content) {
        dict[@"content"] = self.content;
    }
    dict[@"createdAt"] = @(self.createdAt);

    return dict;
}

@end

#pragma mark - WFCCCollectionMessageContent Implementation

@interface WFCCCollectionMessageContent ()
@property (nonatomic, assign) int participantCount;
@end

@implementation WFCCCollectionMessageContent

#pragma mark - Encode/Decode

- (WFCCMessagePayload *)encode {
    WFCCMessagePayload *payload = [super encode];

    // title 放到 searchableContent 中，用于搜索
    payload.searchableContent = self.title;

    // 其他数据放到 binaryContent 中，JSON 格式
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];

    if (self.collectionId) {
        dataDict[@"collectionId"] = self.collectionId;
    }
    if (self.groupId) {
        dataDict[@"groupId"] = self.groupId;
    }
    if (self.creatorId) {
        dataDict[@"creatorId"] = self.creatorId;
    }
    if (self.desc) {
        dataDict[@"desc"] = self.desc;
    }
    if (self.template) {
        dataDict[@"template"] = self.template;
    }

    dataDict[@"expireType"] = @(self.expireType);
    dataDict[@"expireAt"] = @(self.expireAt);
    dataDict[@"maxParticipants"] = @(self.maxParticipants);
    dataDict[@"status"] = @(self.status);
    dataDict[@"createdAt"] = @(self.createdAt);
    dataDict[@"updatedAt"] = @(self.updatedAt);

    // entries 数组
    if (self.entries && self.entries.count > 0) {
        NSMutableArray *entriesArray = [NSMutableArray array];
        for (WFCCCollectionEntry *entry in self.entries) {
            [entriesArray addObject:[entry toDictionary]];
        }
        dataDict[@"entries"] = entriesArray;
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dataDict
                                                       options:0
                                                         error:&error];
    if (!error && jsonData) {
        payload.binaryContent = jsonData;
    }

    return payload;
}

- (void)decode:(WFCCMessagePayload *)payload {
    [super decode:payload];

    // 从 searchableContent 获取 title
    self.title = payload.searchableContent;

    // 从 binaryContent 解析其他数据（服务端 base64edData 会自动解码为 binaryContent）
    if (payload.binaryContent && payload.binaryContent.length > 0) {
        NSError *error = nil;
        NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:payload.binaryContent
                                                                  options:0
                                                                    error:&error];
        if (!error && [dataDict isKindOfClass:[NSDictionary class]]) {
            self.collectionId = dataDict[@"collectionId"];
            self.groupId = dataDict[@"groupId"];
            self.creatorId = dataDict[@"creatorId"];
            self.desc = dataDict[@"desc"];
            self.template = dataDict[@"template"];
            self.expireType = [dataDict[@"expireType"] intValue];
            self.expireAt = [dataDict[@"expireAt"] longLongValue];
            self.maxParticipants = [dataDict[@"maxParticipants"] intValue];
            self.status = [dataDict[@"status"] intValue];
            self.createdAt = [dataDict[@"createdAt"] longLongValue];
            self.updatedAt = [dataDict[@"updatedAt"] longLongValue];

            // 解析 entries
            NSArray *entriesArray = dataDict[@"entries"];
            if (entriesArray && [entriesArray isKindOfClass:[NSArray class]]) {
                NSMutableArray *entries = [NSMutableArray array];
                for (NSDictionary *entryDict in entriesArray) {
                    WFCCCollectionEntry *entry = [WFCCCollectionEntry fromDictionary:entryDict];
                    if (entry) {
                        [entries addObject:entry];
                    }
                }
                self.entries = entries;
                self.participantCount = (int)entries.count;
            }
        }
    }
}

#pragma mark - Message Type

+ (int)getContentType {
    return MESSAGE_CONTENT_TYPE_COLLECTION;
}

+ (int)getContentFlags {
    return WFCCPersistFlag_PERSIST_AND_COUNT;
}

#pragma mark - Factory Method

+ (instancetype)contentWithTitle:(NSString *)title desc:(NSString *)desc {
    WFCCCollectionMessageContent *content = [[WFCCCollectionMessageContent alloc] init];
    content.title = title;
    content.desc = desc;
    content.status = 0;  // 进行中
    content.expireType = 0;  // 默认无限期
    content.entries = @[];
    content.participantCount = 0;
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    content.createdAt = now;
    content.updatedAt = now;
    return content;
}

#pragma mark - Entry Management

- (void)addOrUpdateEntryWithUserId:(NSString *)userId content:(NSString *)content {
    if (!userId || !content) {
        return;
    }

    NSMutableArray *mutableEntries = [NSMutableArray arrayWithArray:self.entries ?: @[]];

    // 查找是否已存在
    WFCCCollectionEntry *existingEntry = nil;
    NSInteger existingIndex = NSNotFound;
    for (NSInteger i = 0; i < mutableEntries.count; i++) {
        WFCCCollectionEntry *entry = mutableEntries[i];
        if ([entry.userId isEqualToString:userId]) {
            existingEntry = entry;
            existingIndex = i;
            break;
        }
    }

    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);

    if (existingEntry) {
        // 更新
        existingEntry.content = content;
        existingEntry.createdAt = now;
    } else {
        // 新增
        WFCCCollectionEntry *newEntry = [[WFCCCollectionEntry alloc] init];
        newEntry.userId = userId;
        newEntry.content = content;
        newEntry.createdAt = now;
        [mutableEntries addObject:newEntry];
    }

    self.entries = mutableEntries;
    self.participantCount = (int)mutableEntries.count;
    self.updatedAt = now;
}

- (void)removeEntryWithUserId:(NSString *)userId {
    if (!userId || self.entries.count == 0) {
        return;
    }

    NSMutableArray *mutableEntries = [NSMutableArray arrayWithArray:self.entries];
    NSInteger indexToRemove = NSNotFound;

    for (NSInteger i = 0; i < mutableEntries.count; i++) {
        WFCCCollectionEntry *entry = mutableEntries[i];
        if ([entry.userId isEqualToString:userId]) {
            indexToRemove = i;
            break;
        }
    }

    if (indexToRemove != NSNotFound) {
        [mutableEntries removeObjectAtIndex:indexToRemove];
        self.entries = mutableEntries;
        self.participantCount = (int)mutableEntries.count;
        self.updatedAt = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    }
}

- (WFCCCollectionEntry *)entryForUserId:(NSString *)userId {
    if (!userId || self.entries.count == 0) {
        return nil;
    }

    for (WFCCCollectionEntry *entry in self.entries) {
        if ([entry.userId isEqualToString:userId]) {
            return entry;
        }
    }

    return nil;
}

- (BOOL)hasUserJoined:(NSString *)userId {
    return [self entryForUserId:userId] != nil;
}

#pragma mark - Digest

- (NSString *)digest:(WFCCMessage *)message {
    if (self.title.length > 0) {
        return [NSString stringWithFormat:@"[接龙] %@", self.title];
    }
    return @"[接龙]";
}

#pragma mark - Registration

+ (void)load {
    [[WFCCIMService sharedWFCIMService] registerMessageContent:self];
}

@end
