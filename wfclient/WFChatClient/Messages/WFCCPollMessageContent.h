//
//  WFCCPollMessageContent.h
//  WFChatClient
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票消息内容类型
 * MessageContentType: 18
 */
@interface WFCCPollMessageContent : WFCCMessageContent

/// 投票ID
@property (nonatomic, strong) NSString *pollId;

/// 群ID
@property (nonatomic, strong) NSString *groupId;

/// 创建者ID
@property (nonatomic, strong) NSString *creatorId;

/// 标题
@property (nonatomic, strong) NSString *title;

/// 描述
@property (nonatomic, strong, nullable) NSString *desc;

/// 可见性：1=仅群内，2=公开
@property (nonatomic, assign) int visibility;

/// 类型：1=单选，2=多选
@property (nonatomic, assign) int type;

/// 是否匿名：0=实名，1=匿名
@property (nonatomic, assign) int anonymous;

/// 状态：0=进行中，1=已结束
@property (nonatomic, assign) int status;

/// 结束时间
@property (nonatomic, assign) long long endTime;

/// 总参与人数
@property (nonatomic, assign) int totalVotes;

@end

NS_ASSUME_NONNULL_END
