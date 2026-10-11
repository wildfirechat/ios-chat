//
//  WFCUPanSharedDoc.h
//  WFChatUIKit
//
//  「共享给我」的在线文档（对齐 wf-pan-server /api/v1/shares/with-me）。
//

#import <Foundation/Foundation.h>
#import "WFCUPanFile.h"

NS_ASSUME_NONNULL_BEGIN

/// 一条分享来源（同一文件可能被多人/多群共享）
@interface WFCUPanShareSource : NSObject

/// GROUP / USER
@property (nonatomic, copy, nullable) NSString *targetType;
@property (nonatomic, copy, nullable) NSString *targetId;
@property (nonatomic, copy, nullable) NSString *targetName;
/// 分享人名称
@property (nonatomic, copy, nullable) NSString *createdByName;
@property (nonatomic, copy, nullable) NSString *createdAt;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

/// 共享给我的文档：文件 + 分享元信息
@interface WFCUPanSharedDoc : NSObject

@property (nonatomic, strong) WFCUPanFile *file;
/// VIEW / EDIT
@property (nonatomic, copy, nullable) NSString *permission;
/// 分享时间
@property (nonatomic, copy, nullable) NSString *sharedAt;
@property (nonatomic, strong) NSArray<WFCUPanShareSource *> *sources;

@property (nonatomic, assign, readonly) BOOL canEdit;

+ (nullable instancetype)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
