//
//  WFCUCollection.h
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUCollectionEntry : NSObject
@property(nonatomic, assign)long entryId;
@property(nonatomic, assign)long collectionId;
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)NSString *content;
@property(nonatomic, assign)long createdAt;
@property(nonatomic, assign)long updatedAt;
@property(nonatomic, assign)int deleted;

+ (instancetype)fromDictionary:(NSDictionary *)dict;
@end

@interface WFCUCollection : NSObject
@property(nonatomic, assign)long collectionId;
@property(nonatomic, strong)NSString *groupId;
@property(nonatomic, strong)NSString *creatorId;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, strong, nullable)NSString *desc;
@property(nonatomic, strong, nullable)NSString *template;
@property(nonatomic, assign)int expireType; // 0=无限期, 1=有限期
@property(nonatomic, assign)long expireAt;
@property(nonatomic, assign)int maxParticipants;
@property(nonatomic, assign)int status; // 0=进行中, 1=已关闭, 2=已取消
@property(nonatomic, assign)long createdAt;
@property(nonatomic, assign)long updatedAt;
@property(nonatomic, strong)NSArray<WFCUCollectionEntry *> *entries;
@property(nonatomic, assign)int participantCount;

+ (instancetype)fromDictionary:(NSDictionary *)dict;
@end

NS_ASSUME_NONNULL_END
