//
//  WFCUPanFile.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanFile.h"
#import "WFCUPanDocUtils.h"

@implementation WFCUPanFile

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    WFCUPanFile *file = [[WFCUPanFile alloc] init];
    // 服务端 FileVO 主键是 id，部分接口/版本会回 fileId，三级回退。
    file.fileId = [dict[@"id"] integerValue] ?: [dict[@"fileId"] integerValue];
    file.spaceId = [dict[@"spaceId"] integerValue];
    file.parentId = [dict[@"parentId"] integerValue];
    file.name = dict[@"name"];
    file.size = [dict[@"size"] longLongValue];
    file.mimeType = dict[@"mimeType"];
    file.md5 = dict[@"md5"];
    file.storageUrl = dict[@"storageUrl"];
    file.childCount = [dict[@"childCount"] integerValue];
    file.creatorId = dict[@"creatorId"];
    file.creatorName = dict[@"creatorName"];
    file.createdAt = dict[@"createdAt"];
    file.updatedAt = dict[@"updatedAt"];
    file.permission = dict[@"permission"];
    file.openedAt = dict[@"openedAt"] ?: dict[@"sharedAt"];
    
    // 服务端 type 是 FOLDER/FILE 枚举，旧接口是数字 1=文件夹。
    id typeValue = dict[@"type"];
    BOOL isFolder = NO;
    if ([typeValue isKindOfClass:[NSString class]]) {
        isFolder = [typeValue caseInsensitiveCompare:@"FOLDER"] == NSOrderedSame;
    } else if ([typeValue respondsToSelector:@selector(integerValue)]) {
        isFolder = [typeValue integerValue] == 1;
    }
    file.type = isFolder ? WFCUPanFileTypeFolder : WFCUPanFileTypeFile;
    
    return file;
}

- (NSString *)extension {
    return [[self.name pathExtension] lowercaseString];
}

- (BOOL)isFolder {
    return self.type == WFCUPanFileTypeFolder;
}

- (BOOL)canOpenOnline {
    return !self.isFolder && [WFCUPanDocUtils isOnlineDocName:self.name];
}

- (NSString *)sizeText {
    int64_t size = self.size;
    if (size < 1024) {
        return [NSString stringWithFormat:@"%lld B", size];
    } else if (size < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", size / 1024.0];
    } else if (size < 1024LL * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", size / 1024.0 / 1024.0];
    }
    return [NSString stringWithFormat:@"%.1f GB", size / 1024.0 / 1024.0 / 1024.0];
}

@end
