//
//  WFCUPanFile.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, WFCUPanFileType) {
    WFCUPanFileTypeFile,
    WFCUPanFileTypeFolder
};

@interface WFCUPanFile : NSObject

@property (nonatomic, assign) NSInteger fileId;
@property (nonatomic, assign) NSInteger spaceId;
@property (nonatomic, assign) NSInteger parentId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) WFCUPanFileType type;
@property (nonatomic, assign) int64_t size;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSString *storageUrl;
@property (nonatomic, assign) NSInteger childCount;
@property (nonatomic, copy) NSString *creatorId;
@property (nonatomic, copy) NSString *creatorName;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, copy) NSString *updatedAt;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
