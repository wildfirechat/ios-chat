//
//  WFCUPollService.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUPoll.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 投票服务协议
 */
@protocol WFCUPollService <NSObject>

#pragma mark - 创建投票

/**
 * 创建投票
 */
- (void)createPoll:(NSString *)groupId
             title:(NSString *)title
       description:(nullable NSString *)description
           options:(NSArray<NSString *> *)options
        visibility:(int)visibility     // 1=仅群内, 2=公开
              type:(int)type           // 1=单选, 2=多选
         maxSelect:(int)maxSelect
         anonymous:(int)anonymous     // 0=实名, 1=匿名
          endTime:(long long)endTime
        showResult:(int)showResult
           success:(void(^)(WFCUPoll *poll))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 获取投票

/**
 * 获取投票详情
 */
- (void)getPoll:(long long)pollId
        success:(void(^)(WFCUPoll *poll))successBlock
          error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 参与投票

/**
 * 参与投票
 */
- (void)vote:(long long)pollId
     optionIds:(NSArray<NSNumber *> *)optionIds
       success:(void(^)(void))successBlock
         error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 结束投票

/**
 * 结束投票（仅发起者）
 */
- (void)closePoll:(long long)pollId
          success:(void(^)(void))successBlock
            error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 删除投票

/**
 * 删除投票（仅发起者）
 */
- (void)deletePoll:(long long)pollId
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 导出明细

/**
 * 导出投票明细（仅发起者，实名投票）
 */
- (void)exportPollDetails:(long long)pollId
                  success:(void(^)(NSArray<WFCUPollVoterDetail *> *details))successBlock
                    error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 我的投票列表

/**
 * 获取我的投票列表（创建的 + 参与的）
 */
- (void)getMyPollsWithSuccess:(void(^)(NSArray<WFCUPoll *> *polls))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
