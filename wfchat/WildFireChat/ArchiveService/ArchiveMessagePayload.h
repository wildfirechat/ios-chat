//
//  ArchiveMessagePayload.h
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WFCCMessagePayload;
/**
 * 消息内容 Payload
 * 对应服务端 API 返回的 payload 结构（已解析的消息内容）
 */
@interface ArchiveMessagePayload : NSObject

/// 消息类型
@property (nonatomic, assign) int type;

/// 消息文本内容（如文本消息的实际内容、位置标题、链接标题等）
@property (nonatomic, strong, nullable) NSString *content;

/// 可搜索内容
@property (nonatomic, strong, nullable) NSString *searchableContent;

/// 推送内容
@property (nonatomic, strong, nullable) NSString *pushContent;

/// 推送数据
@property (nonatomic, strong, nullable) NSString *pushData;

/// @类型：0-不提醒，1-所有人，2-部分人
@property (nonatomic, assign) int mentionedType;

/// @的目标用户ID列表
@property (nonatomic, strong, nullable) NSArray<NSString *> *mentionedTargets;

/// 媒体文件远程URL（图片、语音、文件、视频等）
@property (nonatomic, strong, nullable) NSString *remoteMediaUrl;

/// 扩展字段（JSON格式，包含类型特定的额外信息）
@property (nonatomic, strong, nullable) NSString *extra;

/// 原始Base64数据（解析失败时保留）
@property (nonatomic, strong, nullable) NSString *binaryContent;

/// 子类型（如Typing消息的类型）
@property (nonatomic, assign) int subType;

#pragma mark - 便捷方法

/**
 * 从字典创建 payload 对象
 */
+ (nullable instancetype)fromDictionary:(NSDictionary *)dict;

/**
 * 将 payload 转换为 WFCCMessagePayload（SDK 使用的格式）
 * @param contentType 消息内容类型
 */
- (WFCCMessagePayload *)toSDKPayload:(int)contentType;

@end

NS_ASSUME_NONNULL_END
