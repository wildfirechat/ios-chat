//
//  WFCUPoll.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票选项
 */
@interface WFCUPollOption : NSObject

@property (nonatomic, assign) long long optionId;
@property (nonatomic, strong) NSString *optionText;
@property (nonatomic, assign) int sortOrder;

// 投票后可见
@property (nonatomic, assign) int voteCount;
@property (nonatomic, assign) int votePercent;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

/**
 * 投票人详情
 */
@interface WFCUPollVoterDetail : NSObject

@property (nonatomic, assign) long long optionId;
@property (nonatomic, strong) NSString *optionText;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, assign) long long createdAt;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

/**
 * 投票模型
 */
@interface WFCUPoll : NSObject

@property (nonatomic, assign) long long pollId;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, strong) NSString *creatorId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong, nullable) NSString *desc;
@property (nonatomic, assign) int visibility;      // 1=仅群内, 2=公开
@property (nonatomic, assign) int type;            // 1=单选, 2=多选
@property (nonatomic, assign) int maxSelect;       // 多选时最多选几项
@property (nonatomic, assign) int anonymous;       // 0=实名, 1=匿名
@property (nonatomic, assign) int status;          // 0=进行中, 1=已结束
@property (nonatomic, assign) long long endTime;
@property (nonatomic, assign) int showResult;      // 0=投票前隐藏, 1=始终显示
@property (nonatomic, assign) long long createdAt;
@property (nonatomic, assign) long long updatedAt;

// 当前用户相关
@property (nonatomic, assign) BOOL hasVoted;
@property (nonatomic, assign) BOOL isCreator;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *myOptionIds;

// 状态标记
@property (nonatomic, assign) BOOL deleted;  // 是否已删除

// 统计
@property (nonatomic, assign) int totalVotes;     // 总票数（多选时可能大于人数）
@property (nonatomic, assign) int voterCount;     // 投票人数（去重后的用户数）

// 选项列表
@property (nonatomic, strong) NSArray<WFCUPollOption *> *options;

// 投票人详情（仅实名投票且是发起者）
@property (nonatomic, strong, nullable) NSArray<WFCUPollVoterDetail *> *voterDetails;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

/// 是否显示结果
- (BOOL)shouldShowResult;

/// 是否已过期
- (BOOL)isExpired;

/// 剩余时间文本（如"还剩2天"）
- (nullable NSString *)remainingTimeText;

@end

NS_ASSUME_NONNULL_END
