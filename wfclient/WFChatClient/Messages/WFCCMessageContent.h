//
//  WFCCMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/15.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 媒体类型

 - Media_Type_GENERAL: 一般
 - Media_Type_IMAGE: 图片
 - Media_Type_VOICE: 语音
 - Media_Type_VIDEO: 视频
 - Media_Type_File: 文件
 - Media_Type_PORTRAIT: 头像
 - Media_Type_FAVORITE: 收藏
 - Media_Type_STICKER：动态表情
 - Media_Type_MOMENTS：朋友圈
 */
typedef NS_ENUM(NSInteger, WFCCMediaType) {
    Media_Type_GENERAL = 0,
    Media_Type_IMAGE = 1,
    Media_Type_VOICE = 2,
    Media_Type_VIDEO = 3,
    Media_Type_FILE = 4,
    Media_Type_PORTRAIT = 5,
    Media_Type_FAVORITE = 6,
    Media_Type_STICKER = 7,
    Media_Type_MOMENTS = 8
};


/**
 消息存储类型
 
 - NOT_PERSIST: 本地不存储
 - PERSIST: 本地存储
 - PERSIST_AND_COUNT: 本地存储，并计入未读计数
 - TRANSPARENT: 透传消息，不多端同步，如果对端不在线，消息会丢弃
 */
typedef NS_ENUM(NSInteger, WFCCPersistFlag) {
    WFCCPersistFlag_NOT_PERSIST = 0,
    WFCCPersistFlag_PERSIST = 1,
    WFCCPersistFlag_PERSIST_AND_COUNT = 3,
    WFCCPersistFlag_TRANSPARENT = 4,
};

/**
 普通消息的持久化内容
 */
@interface WFCCMessagePayload : NSObject

/**
 消息类型
 */
@property (nonatomic, assign)int contentType;

/**
 搜索内容
 */
@property (nonatomic, strong)NSString *searchableContent;

/**
 推送内容
*/
@property (nonatomic, strong)NSString *pushContent;
/**
 推送数据
*/
@property (nonatomic, strong)NSString *pushData;

/**
 内容
 */
@property (nonatomic, strong)NSString *content;

/**
 内容流
 */
@property (nonatomic, strong)NSData *binaryContent;

/**
 只存储在客户端本地的内容
 */
@property (nonatomic, strong)NSString *localContent;

/**
 提醒类型，1，提醒部分对象（mentinedTarget）。2，提醒全部。其他不提醒
 */
@property (nonatomic, assign)int mentionedType;

/**
 提醒对象，mentionedType 1时有效
 */
@property (nonatomic, strong)NSArray<NSString *> *mentionedTargets;

/**
 附加信息
 */
@property (nonatomic, strong)NSString *extra;
@end

/**
 媒体消息的持久化内容
 */
@interface WFCCMediaMessagePayload : WFCCMessagePayload

/**
 媒体类型
 */
@property (nonatomic, assign)WFCCMediaType mediaType;

/**
 媒体内容的服务器URL
 */
@property (nonatomic, strong)NSString *remoteMediaUrl;

/**
 媒体内容的本地URL，发送消息时不会携带，用于缓存加速显示
 */
@property (nonatomic, strong)NSString *localMediaPath;

@end

@class WFCCMessage;
/**
 消息协议，所有消息(包括自定义消息均需要实现此协议)
 */
@protocol WFCCMessageContent <NSObject>

/**
 消息编码

 @return 消息的持久化内容
 */
- (WFCCMessagePayload *)encode;

/**
 消息解码

 @param payload 消息的持久化内容
 */
- (void)decode:(WFCCMessagePayload *)payload;

/**
 消息类型，必须全局唯一。1000及以下为系统内置类型，自定义消息需要使用1000以上。

 @return 消息类型的唯一值
 */
+ (int)getContentType;

/**
 消息的存储策略

 @return 存储策略
 */
+ (int)getContentFlags;

/**
 消息的简短信息

 @return 消息的简短信息，主要用于通知提示和会话列表等需要简略信息的地方。
 */
- (NSString *)digest:(WFCCMessage *)message;
@end

/**
 消息内容，自定义消息可以继承此类
 */
@interface WFCCMessageContent : NSObject <WFCCMessageContent>

/**
 附加信息
 */
@property (nonatomic, strong)NSString *extra;
@end
