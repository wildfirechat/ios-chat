//
//  WFCUArchiveService.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatClient/WFCCMessage.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 消息备份服务协议
 * 用于从备份服务获取历史消息
 */
@protocol WFCUArchiveService <NSObject>

#pragma mark - 获取归档消息

/**
 * 获取某个会话的历史消息列表
 *
 * @param conversationType 会话类型：0单聊, 1群组, 2聊天室, 3频道
 * @param convTarget 会话目标（用户ID或群组ID）
 * @param convLine 会话线路，默认0
 * @param startMid 起始消息ID，第一次传0或-1
 * @param before YES=查询更早的消息（向前翻页），NO=查询更新的消息
 * @param limit 返回条数，最大100
 * @param successBlock 成功回调，返回消息列表和分页信息（消息为 WFCCMessage 类型）
 * @param errorBlock 失败回调
 */
- (void)getArchivedMessages:(int)conversationType
                 convTarget:(NSString *)convTarget
                   convLine:(int)convLine
                   startMid:(int64_t)startMid
                     before:(BOOL)before
                      limit:(int)limit
                    success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                      error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 便捷方法：获取某个会话的历史消息（使用默认线路0）
 */
- (void)getArchivedMessages:(int)conversationType
                 convTarget:(NSString *)convTarget
                   startMid:(int64_t)startMid
                     before:(BOOL)before
                      limit:(int)limit
                    success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                      error:(void(^)(int errorCode, NSString *message))errorBlock;

#pragma mark - 搜索归档消息

/**
 * 根据关键字搜索归档消息
 *
 * @param keyword 搜索关键字（长度建议 >= 3）
 * @param conversationType 会话类型筛选，可选
 * @param convTarget 会话目标筛选，可选
 * @param convLine 会话线路筛选，可选
 * @param startMid 起始消息ID，可选
 * @param before 翻页方向，默认YES
 * @param limit 返回条数，最大100
 * @param successBlock 成功回调（消息为 WFCCMessage 类型）
 * @param errorBlock 失败回调
 */
- (void)searchArchivedMessages:(NSString *)keyword
              conversationType:(nullable NSNumber *)conversationType
                    convTarget:(nullable NSString *)convTarget
                      convLine:(nullable NSNumber *)convLine
                      startMid:(int64_t)startMid
                        before:(BOOL)before
                         limit:(int)limit
                       success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 便捷方法：搜索所有归档消息
 */
- (void)searchArchivedMessages:(NSString *)keyword
                         limit:(int)limit
                       success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
