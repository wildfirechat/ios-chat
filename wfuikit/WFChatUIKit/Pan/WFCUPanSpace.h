//
//  WFCUPanSpace.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WFCUPanSpaceType) {
    WFCUPanSpaceTypeGlobalPublic,
    WFCUPanSpaceTypeUserPublic,
    WFCUPanSpaceTypeUserPrivate
};

@interface WFCUPanSpace : NSObject

@property (nonatomic, assign) NSInteger spaceId;
@property (nonatomic, assign) WFCUPanSpaceType spaceType;
@property (nonatomic, copy) NSString *ownerId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int64_t totalQuota;
@property (nonatomic, assign) int64_t usedQuota;
@property (nonatomic, assign) NSInteger fileCount;
@property (nonatomic, assign) NSInteger folderCount;
@property (nonatomic, assign) BOOL autoInit;
@property (nonatomic, copy) NSString *createdAt;
@property (nonatomic, assign) BOOL canManage;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
