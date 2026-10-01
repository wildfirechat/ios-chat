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

/// 文档接口（recent/with-me）附带：VIEW / EDIT
@property (nonatomic, copy, nullable) NSString *permission;
/// 文档接口（recent/with-me）附带：打开/分享时间
@property (nonatomic, copy, nullable) NSString *openedAt;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

/// 小写扩展名（不含点）
- (NSString *)extension;
- (BOOL)isFolder;
/// 是否可以用在线文档打开（不是文件夹且扩展名属于 Word/Excel/PPT/PDF 组）
- (BOOL)canOpenOnline;
/// 人类可读的大小，如 1.2 MB
- (NSString *)sizeText;

@end

NS_ASSUME_NONNULL_END
