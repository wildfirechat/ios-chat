//
//  WFCCCollectionMessageContent.h
//  WFChatClient
//
//  Created by WFChat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 接龙参与条目
 */
@interface WFCCCollectionEntry : NSObject

/**
 用户ID
 */
@property (nonatomic, strong) NSString *userId;

/**
 参与内容
 */
@property (nonatomic, strong) NSString *content;

/**
 参与时间（毫秒时间戳）
 */
@property (nonatomic, assign) long long createdAt;

/**
 从字典创建
 */
+ (instancetype)fromDictionary:(NSDictionary *)dict;

/**
 转换为字典
 */
- (NSDictionary *)toDictionary;

@end

/**
 接龙消息内容
 */
@interface WFCCCollectionMessageContent : WFCCMessageContent

/**
 接龙ID
 */
@property (nonatomic, strong) NSString *collectionId;

/**
 群ID
 */
@property (nonatomic, strong) NSString *groupId;

/**
 创建者ID
 */
@property (nonatomic, strong) NSString *creatorId;

/**
 标题（用于搜索）
 */
@property (nonatomic, strong) NSString *title;

/**
 描述
 */
@property (nonatomic, strong) NSString *desc;

/**
 格式模板
 */
@property (nonatomic, strong) NSString *template;

/**
 过期类型：0=无限期 1=有限期
 */
@property (nonatomic, assign) int expireType;

/**
 过期时间（毫秒时间戳）
 */
@property (nonatomic, assign) long long expireAt;

/**
 人数上限
 */
@property (nonatomic, assign) int maxParticipants;

/**
 状态：0=进行中 1=已结束 2=已取消
 */
@property (nonatomic, assign) int status;

/**
 参与列表
 */
@property (nonatomic, strong) NSArray<WFCCCollectionEntry *> *entries;

/**
 参与人数（entries的count，方便使用）
 */
@property (nonatomic, assign, readonly) int participantCount;

/**
 创建时间（毫秒时间戳）
 */
@property (nonatomic, assign) long long createdAt;

/**
 更新时间（毫秒时间戳）
 */
@property (nonatomic, assign) long long updatedAt;

/**
 构造方法

 @param title 标题
 @param desc 描述
 @return 接龙消息内容
 */
+ (instancetype)contentWithTitle:(NSString *)title desc:(NSString *)desc;

/**
 添加/更新参与记录

 @param userId 用户ID
 @param content 参与内容
 */
- (void)addOrUpdateEntryWithUserId:(NSString *)userId content:(NSString *)content;

/**
 删除参与记录

 @param userId 用户ID
 */
- (void)removeEntryWithUserId:(NSString *)userId;

/**
 获取用户的参与记录

 @param userId 用户ID
 @return 参与条目
 */
- (WFCCCollectionEntry *)entryForUserId:(NSString *)userId;

/**
 检查用户是否已参与

 @param userId 用户ID
 @return YES表示已参与
 */
- (BOOL)hasUserJoined:(NSString *)userId;

@end
