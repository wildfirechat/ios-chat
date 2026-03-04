//
//  WFCUPanFile.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanFile.h"

@implementation WFCUPanFile

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    WFCUPanFile *file = [[WFCUPanFile alloc] init];
    file.fileId = [dict[@"id"] integerValue];
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
    
    NSString *typeStr = dict[@"type"];
    if ([typeStr isEqualToString:@"FOLDER"]) {
        file.type = WFCUPanFileTypeFolder;
    } else {
        file.type = WFCUPanFileTypeFile;
    }
    
    return file;
}

@end
