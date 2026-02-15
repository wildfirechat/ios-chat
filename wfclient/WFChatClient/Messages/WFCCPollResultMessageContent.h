//
//  WFCCPollResultMessageContent.h
//  WFChatClient
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票结果消息内容类型（投票结束时发送）
 * MessageContentType: 19
 */
@interface WFCCPollResultMessageContent : WFCCMessageContent

/// 投票ID
@property (nonatomic, strong) NSString *pollId;

/// 群ID
@property (nonatomic, strong) NSString *groupId;

/// 创建者ID
@property (nonatomic, strong) NSString *creatorId;

/// 标题
@property (nonatomic, strong) NSString *title;

/// 总票数
@property (nonatomic, assign) int totalVotes;

/// 投票人数（去重后的实际人数）
@property (nonatomic, assign) int voterCount;

/// 获胜选项ID列表（可能有多个平票）
@property (nonatomic, strong) NSArray<NSString *> *winningOptionIds;

/// 获胜选项文本
@property (nonatomic, strong) NSArray<NSString *> *winningOptionTexts;

/// 结束时间
@property (nonatomic, assign) long long endedAt;

@end

NS_ASSUME_NONNULL_END
