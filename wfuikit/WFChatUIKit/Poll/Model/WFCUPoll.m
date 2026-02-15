//
//  WFCUPoll.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPoll.h"

// 辅助函数：将NSNull转换为nil
static id NilIfNull(id obj) {
    return [obj isKindOfClass:[NSNull class]] ? nil : obj;
}

@implementation WFCUPollOption

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    WFCUPollOption *option = [[WFCUPollOption alloc] init];
    option.optionId = [NilIfNull(dict[@"id"]) longLongValue];
    option.optionText = NilIfNull(dict[@"optionText"]) ?: @"";
    option.sortOrder = [NilIfNull(dict[@"sortOrder"]) intValue];
    option.voteCount = [NilIfNull(dict[@"voteCount"]) intValue];
    option.votePercent = [NilIfNull(dict[@"votePercent"]) intValue];
    return option;
}

@end

@implementation WFCUPollVoterDetail

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    WFCUPollVoterDetail *detail = [[WFCUPollVoterDetail alloc] init];
    detail.optionId = [NilIfNull(dict[@"optionId"]) longLongValue];
    detail.optionText = NilIfNull(dict[@"optionText"]) ?: @"";
    detail.userId = NilIfNull(dict[@"userId"]) ?: @"";
    detail.userName = NilIfNull(dict[@"userName"]) ?: @"";
    detail.createdAt = [NilIfNull(dict[@"createdAt"]) longLongValue];
    return detail;
}

@end

@implementation WFCUPoll

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) return nil;
    
    WFCUPoll *poll = [[WFCUPoll alloc] init];
    poll.pollId = [NilIfNull(dict[@"id"]) longLongValue];
    poll.groupId = NilIfNull(dict[@"groupId"]) ?: @"";
    poll.creatorId = NilIfNull(dict[@"creatorId"]) ?: @"";
    poll.title = NilIfNull(dict[@"title"]) ?: @"";
    poll.desc = NilIfNull(dict[@"description"]);
    poll.visibility = [NilIfNull(dict[@"visibility"]) intValue];
    poll.type = [NilIfNull(dict[@"type"]) intValue];
    poll.maxSelect = [NilIfNull(dict[@"maxSelect"]) intValue];
    poll.anonymous = [NilIfNull(dict[@"anonymous"]) intValue];
    poll.status = [NilIfNull(dict[@"status"]) intValue];
    poll.endTime = [NilIfNull(dict[@"endTime"]) longLongValue];
    poll.showResult = [NilIfNull(dict[@"showResult"]) intValue];
    poll.createdAt = [NilIfNull(dict[@"createdAt"]) longLongValue];
    poll.updatedAt = [NilIfNull(dict[@"updatedAt"]) longLongValue];
    poll.hasVoted = [NilIfNull(dict[@"hasVoted"]) boolValue];
    poll.isCreator = [NilIfNull(dict[@"isCreator"]) boolValue];
    poll.totalVotes = [NilIfNull(dict[@"totalVotes"]) intValue];
    poll.voterCount = [NilIfNull(dict[@"voterCount"]) intValue];
    poll.deleted = [NilIfNull(dict[@"deleted"]) boolValue];
    
    // 选项
    NSMutableArray *options = [NSMutableArray array];
    NSArray *optionDicts = NilIfNull(dict[@"options"]);
    if ([optionDicts isKindOfClass:[NSArray class]]) {
        for (NSDictionary *optionDict in optionDicts) {
            WFCUPollOption *option = [WFCUPollOption fromDictionary:optionDict];
            if (option) [options addObject:option];
        }
    }
    poll.options = options;
    
    // 我选的选项
    NSArray *myOptionIds = NilIfNull(dict[@"myOptionIds"]);
    if ([myOptionIds isKindOfClass:[NSArray class]]) {
        poll.myOptionIds = myOptionIds;
    }
    
    // 投票人详情
    NSMutableArray *voterDetails = [NSMutableArray array];
    NSArray *detailDicts = NilIfNull(dict[@"voterDetails"]);
    if ([detailDicts isKindOfClass:[NSArray class]]) {
        for (NSDictionary *detailDict in detailDicts) {
            WFCUPollVoterDetail *detail = [WFCUPollVoterDetail fromDictionary:detailDict];
            if (detail) [voterDetails addObject:detail];
        }
    }
    if (voterDetails.count > 0) {
        poll.voterDetails = voterDetails;
    }
    
    return poll;
}

- (BOOL)shouldShowResult {
    // 投票已结束，所有人可见
    if (self.status == 1) return YES;
    // 已投票者可见
    if (self.hasVoted) return YES;
    return NO;
}

- (BOOL)isExpired {
    if (self.endTime > 0) {
        return self.endTime < [[NSDate date] timeIntervalSince1970] * 1000;
    }
    return NO;
}

- (NSString *)remainingTimeText {
    // 投票已结束（手动关闭）
    if (self.status == 1) return WFCString(@"PollStatusEnded");
    
    if (self.endTime <= 0) return nil;
    
    long long now = [[NSDate date] timeIntervalSince1970] * 1000;
    long long remaining = self.endTime - now;
    
    if (remaining <= 0) return WFCString(@"PollExpired");
    
    // 转换为可读格式
    long long minutes = remaining / 60000;
    long long hours = minutes / 60;
    long long days = hours / 24;
    
    if (days > 0) {
        return [NSString stringWithFormat:WFCString(@"RemainingDays"), (int)days];
    } else if (hours > 0) {
        return [NSString stringWithFormat:WFCString(@"RemainingHours"), (int)hours];
    } else {
        return [NSString stringWithFormat:WFCString(@"RemainingMinutes"), (int)minutes];
    }
}

@end
