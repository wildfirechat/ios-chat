//
//  WFCUCollection.m
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCollection.h"

// 辅助函数：将NSNull转换为nil
static id NilIfNull(id obj) {
    return [obj isKindOfClass:[NSNull class]] ? nil : obj;
}

@implementation WFCUCollectionEntry

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    WFCUCollectionEntry *entry = [[WFCUCollectionEntry alloc] init];
    entry.entryId = [dict[@"id"] longValue];
    entry.collectionId = [dict[@"collectionId"] longValue];
    entry.userId = NilIfNull(dict[@"userId"]) ?: @"";
    entry.content = NilIfNull(dict[@"content"]) ?: @"";
    entry.createdAt = [dict[@"createdAt"] longValue];
    entry.updatedAt = [dict[@"updatedAt"] longValue];
    entry.deleted = [dict[@"deleted"] intValue];

    return entry;
}

@end

@implementation WFCUCollection

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    WFCUCollection *collection = [[WFCUCollection alloc] init];
    collection.collectionId = [dict[@"id"] longValue];
    collection.groupId = NilIfNull(dict[@"groupId"]) ?: @"";
    collection.creatorId = NilIfNull(dict[@"creatorId"]) ?: @"";
    collection.title = NilIfNull(dict[@"title"]) ?: @"";
    collection.desc = NilIfNull(dict[@"description"]);
    collection.template = NilIfNull(dict[@"template"]);
    collection.expireType = [dict[@"expireType"] intValue];
    collection.expireAt = [dict[@"expireAt"] longValue];
    collection.maxParticipants = [dict[@"maxParticipants"] intValue];
    collection.status = [dict[@"status"] intValue];
    collection.createdAt = [dict[@"createdAt"] longValue];
    collection.updatedAt = [dict[@"updatedAt"] longValue];
    collection.participantCount = [dict[@"participantCount"] intValue];

    // Parse entries
    NSArray *entriesDict = dict[@"entries"];
    if (entriesDict && [entriesDict isKindOfClass:[NSArray class]]) {
        NSMutableArray *entries = [NSMutableArray arrayWithCapacity:entriesDict.count];
        for (NSDictionary *entryDict in entriesDict) {
            WFCUCollectionEntry *entry = [WFCUCollectionEntry fromDictionary:entryDict];
            if (entry) {
                [entries addObject:entry];
            }
        }
        collection.entries = entries;
    } else {
        collection.entries = @[];
    }

    return collection;
}

@end
