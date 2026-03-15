//
//  ArchiveMessageResult.h
//  WFChatUIKit
//
//  Created by Rain on 11/3/2026.
//  Copyright © 2026 Tom Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WFCCMessage;
/**
 * 消息归档查询结果
 */
@interface ArchiveMessageResult : NSObject

/// 消息列表（WFCCMessage 对象）
@property (nonatomic, strong) NSArray<WFCCMessage *> *messages;

/// 是否还有更多消息
@property (nonatomic, assign) BOOL hasMore;

/// 下一页起始消息ID（用于翻页）
@property (nonatomic, assign) int64_t nextStartMid;

@end

NS_ASSUME_NONNULL_END
