# 野火IM iOS 项目技术文档

> 版本：v1.0  
> 更新日期：2026-02-16  
> 适用版本：野火IM iOS SDK最新版

---

## 目录

1. [项目概述](#一项目概述)
2. [WFChatClient 功能SDK](#二wfchatclient-功能sdk)
3. [WFChatUIKit 界面SDK](#三wfchatuikit-界面sdk)
4. [WildFireChat 应用层](#四wildfirechat-应用层)
5. [第三方依赖](#五第三方依赖)
6. [资源文件](#六资源文件)
7. [集成指南](#七集成指南)
8. [进阶开发](#八进阶开发)
9. [附录](#九附录)

---

## 一、项目概述

### 1.1 项目简介

野火IM（WildFireChat）是专业级即时通讯和实时音视频整体解决方案，由北京野火无限网络科技有限公司维护和支持。

**主要特性：**
- 私有部署安全可靠
- 性能强大，支持百万级用户
- 功能齐全，全平台支持
- 开源率高，部署运维简单
- 二次开发友好，方便与第三方系统对接

### 1.2 整体架构

项目采用三层架构设计：

```
┌─────────────────────────────────────────────────────────────┐
│                    WildFireChat (App)                       │
│                  应用层，具体业务实现                        │
└───────────────────────────┬─────────────────────────────────┘
                            │ 依赖
┌───────────────────────────▼─────────────────────────────────┐
│                 WFChatUIKit (界面SDK)                       │
│         提供开箱即用的IM界面组件（ViewController等）         │
└───────────────────────────┬─────────────────────────────────┘
                            │ 依赖
┌───────────────────────────▼─────────────────────────────────┐
│                 WFChatClient (功能SDK)                      │
│        纯功能SDK，无UI依赖（网络、消息、数据管理）           │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 技术栈

| 层级 | 技术/框架 | 说明 |
|------|----------|------|
| 语言 | Objective-C | 主要开发语言 |
| 网络 | Mars | 腾讯开源长连接框架 |
| 音视频 | WebRTC | 实时音视频通话 |
| 图片 | SDWebImage | 图片加载缓存 |
| 数据库 | SQLite | 本地消息存储（Mars封装） |
| 协议 | Protobuf | 数据传输协议 |

### 1.4 模块说明

| 模块 | 类型 | 职责 |
|------|------|------|
| `wfchat/WildFireChat` | Application | 完整的IM应用示例，包含所有业务逻辑 |
| `wfuikit/WFChatUIKit` | Framework | UI组件库，提供聊天界面、通讯录等 |
| `wfclient/WFChatClient` | Framework | 功能SDK，处理网络连接、消息收发等 |

---

## 二、WFChatClient 功能SDK

### 2.1 模块概述

**定位：** 纯功能SDK，不包含任何UI代码  
**核心职责：**
- IM通信能力（长连接管理、消息收发）
- 数据管理（用户信息、群组信息、会话管理）
- 网络状态维护
- 本地数据持久化

**依赖关系：**
- 依赖 Mars 协议栈（`mars.xcframework`）
- 依赖 OpenSSL（`libcrypto.xcframework`、`libssl.xcframework`）
- 依赖 AMR 编解码（`opencore-amrnb.xcframework`）

### 2.2 核心服务类

#### 2.2.1 WFCCIMService - IM核心服务

**单例访问：**
```objc
WFCCIMService *service = [WFCCIMService sharedWFCIMService];
```

**主要职责：**
- 消息管理（发送、接收、撤回、删除）
- 会话管理（创建、删除、置顶、免打扰）
- 用户管理（获取用户信息、修改个人信息）
- 群组管理（创建、加入、退出、修改群信息）
- 好友管理（添加、删除、黑名单）
- 搜索功能（用户、群组、消息、文件）

**常用方法：**

```objc
// 发送消息
- (WFCCMessage *)sendMessage:(WFCCConversation *)conversation
                     content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *> *)toUsers
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                     error:(void(^)(int error_code))errorBlock;

// 获取会话列表
- (NSArray<WFCCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes
                                                    lines:(NSArray<NSNumber *> *)lines;

// 获取消息列表
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                              fromIndex:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                         withUser:(NSString *)user;
```

#### 2.2.2 WFCCNetworkService - 网络服务

**单例访问：**
```objc
WFCCNetworkService *service = [WFCCNetworkService sharedInstance];
```

**主要职责：**
- 长连接管理（连接、断开、重连）
- 连接状态监控
- 推送Token管理
- 消息接收分发

**关键属性：**
```objc
// 连接状态委托
@property(nonatomic, weak) id<ConnectionStatusDelegate> connectionStatusDelegate;

// 消息接收委托
@property(nonatomic, weak) id<ReceiveMessageDelegate> receiveMessageDelegate;

// 会议事件委托
@property(nonatomic, weak) id<ConferenceEventDelegate> conferenceEventDelegate;
```

**连接状态枚举：**
```objc
typedef NS_ENUM(NSInteger, ConnectionStatus) {
    kConnectionStatusTimeInconsistent = -9,  // 时间不一致
    kConnectionStatusNotLicensed = -8,       // 未授权
    kConnectionStatusKickedoff = -7,         // 被踢下线
    kConnectionStatusSecretKeyMismatch = -6, // 密钥错误
    kConnectionStatusTokenIncorrect = -5,    // Token错误
    kConnectionStatusServerDown = -4,        // 服务器关闭
    kConnectionStatusRejected = -3,          // 被拒绝
    kConnectionStatusLogout = -2,            // 退出登录
    kConnectionStatusUnconnected = -1,       // 未连接
    kConnectionStatusConnecting = 0,         // 连接中
    kConnectionStatusConnected = 1,          // 已连接
    kConnectionStatusReceiving = 2           // 同步数据中
};
```

#### 2.2.3 WFCCMessageBackupManager - 消息备份

**功能：**
- 消息备份到本地（含加密）
- 消息恢复到当前设备
- 跨设备迁移

```objc
// 备份消息
- (void)backupMessages:(NSString *)directoryPath
         conversations:(NSArray<WFCCConversation *> *)conversations
              password:(NSString *)password
          passwordHint:(NSString *)passwordHint
              progress:(void(^)(NSInteger current, NSInteger total))progress
               success:(void(^)(NSString *path, NSInteger messageCount, NSInteger mediaCount, long long mediaSize))successBlock
                 error:(void(^)(NSString *error))errorBlock;

// 恢复消息
- (void)restoreMessages:(NSString *)directoryPath
               password:(NSString *)password
      overwriteExisting:(BOOL)overwriteExisting
               progress:(void(^)(NSInteger current, NSInteger total))progress
                success:(void(^)(NSInteger messageCount, NSInteger mediaCount))successBlock
                  error:(void(^)(NSString *error))errorBlock;
```

### 2.3 数据模型体系

#### 2.3.1 用户体系

**WFCCUserInfo - 用户信息**
```objc
@interface WFCCUserInfo : WFCCJsonSerializer
@property(nonatomic, strong) NSString *userId;          // 用户ID
@property(nonatomic, strong) NSString *name;            // 用户名
@property(nonatomic, strong) NSString *displayName;     // 显示名
@property(nonatomic, strong) NSString *portrait;        // 头像URL
@property(nonatomic, assign) int gender;                // 性别
@property(nonatomic, strong) NSString *mobile;          // 手机号
@property(nonatomic, strong) NSString *email;           // 邮箱
@property(nonatomic, strong) NSString *address;         // 地址
@property(nonatomic, strong) NSString *company;         // 公司
@property(nonatomic, strong) NSString *social;          // 社交信息
@property(nonatomic, strong) NSString *extra;           // 扩展信息
@property(nonatomic, assign) int type;                  // 用户类型（0普通，1机器人）
@property(nonatomic, assign) int updateDt;              // 更新时间
@property(nonatomic, assign) BOOL deleted;              // 是否已删除
@end
```

**WFCCFriend - 好友关系**
```objc
@interface WFCCFriend : NSObject
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *alias;           // 好友备注
@property(nonatomic, assign) long long timestamp;       // 成为好友时间
@end
```

**WFCCFriendRequest - 好友请求**
```objc
@interface WFCCFriendRequest : NSObject
@property(nonatomic, strong) NSString *target;          // 目标用户ID
@property(nonatomic, strong) NSString *targetName;      // 目标用户名称
@property(nonatomic, strong) NSString *targetPortrait;  // 目标用户头像
@property(nonatomic, strong) NSString *reason;          // 请求原因
@property(nonatomic, assign) int status;                // 状态（0未处理，1已接受，2已拒绝）
@property(nonatomic, assign) long long timestamp;       // 请求时间
@property(nonatomic, assign) int readStatus;            // 读取状态
@end
```

#### 2.3.2 会话体系

**WFCCConversation - 会话标识**
```objc
@interface WFCCConversation : NSObject<NSCopying>
@property(nonatomic, assign) WFCCConversationType type; // 会话类型
@property(nonatomic, strong) NSString *target;          // 目标ID（用户/群组/频道ID）
@property(nonatomic, assign) int line;                  // 线路（默认0）

+ (instancetype)conversationWithType:(WFCCConversationType)type
                              target:(NSString *)target
                                line:(int)line;
@end
```

**WFCCConversationType 会话类型枚举：**
```objc
typedef NS_ENUM(NSInteger, WFCCConversationType) {
    Single_Type = 0,        // 单聊
    Group_Type = 1,         // 群聊
    Channel_Type = 2,       // 频道
    Chatroom_Type = 3,      // 聊天室
    SecretChat_Type = 4     // 密聊（阅后即焚）
};
```

**WFCCConversationInfo - 会话信息**
```objc
@interface WFCCConversationInfo : WFCCJsonSerializer
@property(nonatomic, strong) WFCCConversation *conversation;  // 会话
@property(nonatomic, strong) WFCCMessage *lastMessage;        // 最后一条消息
@property(nonatomic, strong) NSString *draft;                 // 草稿
@property(nonatomic, assign) long long timestamp;             // 最后消息时间
@property(nonatomic, strong) WFCCUnreadCount *unreadCount;    // 未读数
@property(nonatomic, assign) int isTop;                       // 置顶优先级（0未置顶）
@property(nonatomic, assign) BOOL isSilent;                   // 是否免打扰
@end
```

**WFCCUnreadCount - 未读计数**
```objc
@interface WFCCUnreadCount : NSObject
@property(nonatomic, assign) int unread;          // 普通未读数
@property(nonatomic, assign) int unreadMention;   // @提醒未读数
@property(nonatomic, assign) int unreadMentionAll; // @所有人未读数
@end
```

#### 2.3.3 群组体系

**WFCCGroupInfo - 群组信息**
```objc
@interface WFCCGroupInfo : WFCCJsonSerializer
@property(nonatomic, strong) NSString *target;          // 群组ID
@property(nonatomic, strong) NSString *name;            // 群组名称
@property(nonatomic, strong) NSString *portrait;        // 群组头像
@property(nonatomic, strong) NSString *owner;           // 群主
@property(nonatomic, strong) NSString *extra;           // 扩展信息
@property(nonatomic, assign) int type;                  // 群组类型
@property(nonatomic, assign) int memberCount;           // 成员数量
@property(nonatomic, assign) int mute;                  // 是否全员静音
@property(nonatomic, assign) int joinType;              // 加入类型
@property(nonatomic, assign) int privateChat;           // 是否禁止私聊
@property(nonatomic, assign) int searchable;            // 是否可搜索
@property(nonatomic, assign) int historyMessage;        // 新成员是否可见历史消息
@property(nonatomic, assign) int maxMemberCount;        // 最大成员数
@property(nonatomic, assign) long long updateDt;        // 更新时间
@property(nonatomic, assign) long long createDt;        // 创建时间
@end
```

**WFCCGroupMember - 群成员**
```objc
@interface WFCCGroupMember : NSObject
@property(nonatomic, strong) NSString *groupId;         // 群组ID
@property(nonatomic, strong) NSString *memberId;        // 成员ID
@property(nonatomic, strong) NSString *alias;           // 群内昵称
@property(nonatomic, strong) NSString *extra;           // 扩展信息
@property(nonatomic, assign) int type;                  // 成员类型（0普通，1管理员，2群主）
@property(nonatomic, assign) int mute;                  // 是否被禁言
@property(nonatomic, assign) long long createTime;      // 加入时间
@end
```

#### 2.3.4 消息体系

**WFCCMessage - 消息**
```objc
@interface WFCCMessage : NSObject
@property(nonatomic, strong) WFCCConversation *conversation;  // 所属会话
@property(nonatomic, strong) WFCCMessageContent *content;     // 消息内容
@property(nonatomic, strong) NSString *fromUser;              // 发送者
@property(nonatomic, strong) NSArray<NSString *> *toUsers;    // 指定接收者（可选）
@property(nonatomic, assign) WFCCMessageDirection direction;  // 方向
@property(nonatomic, assign) WFCCMessageStatus status;        // 状态
@property(nonatomic, assign) long long messageId;             // 消息ID（本地）
@property(nonatomic, assign) long long messageUid;            // 消息UID（服务器）
@property(nonatomic, assign) long long serverTime;            // 服务器时间
@property(nonatomic, strong) NSString *localExtra;            // 本地扩展
@end
```

**WFCCMessageDirection 消息方向：**
```objc
typedef NS_ENUM(NSInteger, WFCCMessageDirection) {
    MessageDirection_Send = 0,      // 发送
    MessageDirection_Receive = 1    // 接收
};
```

**WFCCMessageStatus 消息状态：**
```objc
typedef NS_ENUM(NSInteger, WFCCMessageStatus) {
    Message_Status_Sending = 0,     // 发送中
    Message_Status_Sent = 1,        // 发送成功
    Message_Status_Send_Failure = 2 // 发送失败
};
```

**WFCCMessagePayload - 消息负载（协议层）**
```objc
@interface WFCCMessagePayload : NSObject
@property(nonatomic, assign) int contentType;               // 内容类型
@property(nonatomic, strong) NSString *searchableContent;   // 可搜索内容
@property(nonatomic, strong) NSString *pushContent;         // 推送内容
@property(nonatomic, strong) NSString *pushData;            // 推送数据
@property(nonatomic, strong) NSString *content;             // 内容（JSON）
@property(nonatomic, strong) NSData *binaryContent;         // 二进制内容
@property(nonatomic, strong) NSString *localContent;        // 本地内容
@property(nonatomic, assign) int mentionedType;             // @类型
@property(nonatomic, strong) NSArray<NSString *> *mentionedTargets; // @目标
@property(nonatomic, strong) NSString *extra;               // 扩展
@property(nonatomic, assign) BOOL notLoaded;                // 是否未加载
@end
```

---


### 2.4 平台类型与多端登录

#### 2.4.1 平台类型枚举

野火IM支持12种平台类型，用于标识用户登录的客户端类型：

```objc
typedef NS_ENUM(NSInteger, WFCCPlatformType) {
    PlatformType_UNSET = 0,         // 未设置
    PlatformType_iOS = 1,           // iOS
    PlatformType_Android = 2,       // Android
    PlatformType_Windows = 3,       // Windows
    PlatformType_OSX = 4,           // macOS
    PlatformType_WEB = 5,           // Web
    PlatformType_WX = 6,            // 微信小程序
    PlatformType_Linux = 7,         // Linux
    PlatformType_iPad = 8,          // iPad
    PlatformType_APad = 9,          // Android Pad
    PlatformType_Harmony = 10,      // 鸿蒙手机
    PlatformType_HarmonyPad = 11,   // 鸿蒙平板
    PlatformType_HarmonyPC = 12     // 鸿蒙PC
};
```

#### 2.4.2 PC/Web端登录管理

**WFCCPCOnlineInfo - PC端在线信息**
```objc
@interface WFCCPCOnlineInfo : NSObject
@property(nonatomic, assign) BOOL isOnline;     // 是否在线
@property(nonatomic, assign) int platform;      // 平台类型
@property(nonatomic, assign) long long timestamp; // 登录时间
@end
```

**获取PC端在线状态：**
```objc
NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
```

**PC登录请求处理：**
```objc
// 处理PC扫码登录请求
WFCCPCLoginRequestMessageContent *content = ...;
[[WFCCIMService sharedWFCIMService] handlePCLoginRequest:content.sessionId 
                                                 confirm:YES 
                                                 success:^{} 
                                                   error:^(int errorCode) {}];
```

### 2.5 消息内容体系

所有消息内容都继承自 `WFCCMessageContent`，需要实现序列化和反序列化方法。

#### 2.5.1 基础消息类型

**文本消息**
```objc
@interface WFCCTextMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *text;
+ (instancetype)contentWithText:(NSString *)text;
@end
```

**图片消息**
```objc
@interface WFCCImageMessageContent : WFCCMediaMessageContent
@property(nonatomic, strong) UIImage *image;           // 原图
@property(nonatomic, strong) UIImage *thumbnail;       // 缩略图
@property(nonatomic, strong) NSString *localPath;      // 本地路径
@property(nonatomic, assign) CGSize size;              // 图片尺寸
@end
```

**语音消息**
```objc
@interface WFCCSoundMessageContent : WFCCMediaMessageContent
@property(nonatomic, strong) NSString *localPath;      // 本地路径
@property(nonatomic, assign) int duration;             // 时长（秒）
@property(nonatomic, strong) NSData *waveform;         // 波形数据
@end
```

**视频消息**
```objc
@interface WFCCVideoMessageContent : WFCCMediaMessageContent
@property(nonatomic, strong) NSString *localPath;      // 本地路径
@property(nonatomic, strong) UIImage *thumbnail;       // 封面图
@property(nonatomic, assign) CGSize size;              // 视频尺寸
@property(nonatomic, assign) int duration;             // 时长（秒）
@end
```

**文件消息**
```objc
@interface WFCCFileMessageContent : WFCCMediaMessageContent
@property(nonatomic, strong) NSString *localPath;      // 本地路径
@property(nonatomic, strong) NSString *name;           // 文件名
@property(nonatomic, assign) int size;                 // 文件大小
@end
```

**位置消息**
```objc
@interface WFCCLocationMessageContent : WFCCMessageContent
@property(nonatomic, assign) double latitude;          // 纬度
@property(nonatomic, assign) double longitude;         // 经度
@property(nonatomic, strong) NSString *title;          // 位置标题
@property(nonatomic, strong) UIImage *thumbnail;       // 缩略图
@end
```

#### 2.5.2 通知类消息

**群组通知基类**
```objc
@interface WFCCNotificationMessageContent : WFCCMessageContent
- (NSString *)formatNotification:(NSString *)groupId;
@end
```

**常见群组通知：**
- `WFCCCreateGroupNotificationContent` - 创建群组
- `WFCCAddGroupeMemberNotificationContent` - 添加成员
- `WFCCKickoffGroupMemberNotificationContent` - 踢出成员
- `WFCCQuitGroupNotificationContent` - 退出群组
- `WFCCDismissGroupNotificationContent` - 解散群组
- `WFCCChangeGroupNameNotificationContent` - 修改群名称
- `WFCCChangeGroupPortraitNotificationContent` - 修改群头像
- `WFCCTransferGroupOwnerNotificationContent` - 转让群主
- `WFCCModifyGroupAliasNotificationContent` - 修改群昵称
- `WFCCGroupMuteNotificationContent` - 群静音设置
- `WFCCGroupJoinTypeNotificationContent` - 群加入方式变更
- `WFCCGroupPrivateChatNotificationContent` - 群私聊设置变更

#### 2.5.3 通话与会议消息

**通话邀请消息**
```objc
@interface WFCCCallStartMessageContent : WFCCMessageContent
@property(nonatomic, assign) int callType;             // 0音频 1视频
@property(nonatomic, strong) NSString *targetId;       // 目标ID
@property(nonatomic, strong) NSString *connectUrl;     // 连接地址
@end
```

**会议邀请消息**
```objc
@interface WFCCConferenceInviteMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *callId;         // 会议ID
@property(nonatomic, strong) NSString *pin;            // PIN码
@property(nonatomic, strong) NSString *host;           // 主持人
@property(nonatomic, strong) NSString *title;          // 会议标题
@property(nonatomic, strong) NSString *desc;           // 会议描述
@property(nonatomic, strong) NSString *connectUrl;     // 连接地址
@property(nonatomic, assign) long long startTime;      // 开始时间
@property(nonatomic, assign) long long endTime;        // 结束时间
@property(nonatomic, assign) BOOL audience;            // 是否观众模式
@property(nonatomic, assign) BOOL advance;             // 是否高级会议
@end
```

#### 2.5.4 其他特殊消息

**名片消息**
```objc
@interface WFCCCardMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *targetId;       // 目标用户ID
@property(nonatomic, strong) NSString *name;           // 名称
@property(nonatomic, strong) NSString *portrait;       // 头像
@property(nonatomic, strong) NSString *displayName;    // 显示名
@end
```

**链接消息**
```objc
@interface WFCCLinkMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *title;          // 标题
@property(nonatomic, strong) NSString *desc;           // 描述
@property(nonatomic, strong) NSString *url;            // 链接URL
@property(nonatomic, strong) NSString *thumbnailUrl;   // 缩略图
@end
```

**合并转发消息**
```objc
@interface WFCCCompositeMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSArray<WFCCMessage *> *messages;  // 合并的消息列表
@property(nonatomic, strong) NSString *title;                   // 标题
@property(nonatomic, strong) NSArray<NSString *> *toUsers;      // 目标用户
@end
```

**投票消息**
```objc
@interface WFCCPollMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *pollId;         // 投票ID
@property(nonatomic, strong) NSString *title;          // 投票标题
@property(nonatomic, strong) NSArray<NSString *> *options;  // 选项
@property(nonatomic, assign) int maxVoteCount;         // 最大可选项数
@property(nonatomic, assign) long long endTime;        // 结束时间
@end
```

**流式文本消息（AI）**
```objc
@interface WFCCStreamingTextGeneratingMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *textId;         // 文本流ID
@property(nonatomic, strong) NSString *text;           // 当前文本
@property(nonatomic, strong) NSString *fullText;       // 完整文本
@end
```

### 2.6 会话管理功能

#### 2.6.1 会话设置

```objc
// 设置会话置顶（优先级，0表示取消置顶）
- (void)setConversation:(WFCCConversation *)conversation
                    top:(int)top
                success:(void(^)(void))successBlock
                  error:(void(^)(int errorCode))errorBlock;

// 设置会话免打扰
- (void)setConversation:(WFCCConversation *)conversation
                 silent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int errorCode))errorBlock;

// 设置会话草稿
- (void)setConversation:(WFCCConversation *)conversation
                  draft:(NSString *)draft;

// 清除会话消息
- (void)clearConversation:(WFCCConversation *)conversation
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock;

// 删除会话
- (void)removeConversation:(WFCCConversation *)conversation
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;
```

#### 2.6.2 全局设置

```objc
// 全局静音
- (void)setGlobalSilent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int errorCode))errorBlock;

// 音视频通知免打扰
- (void)setVoipNotificationSilent:(BOOL)silent
                          success:(void(^)(void))successBlock
                            error:(void(^)(int errorCode))errorBlock;

// 设置免打扰时间段
- (void)setNoDisturbingTime:(int)startMins
                     endMins:(int)endMins
                     success:(void(^)(void))successBlock
                       error:(void(^)(int errorCode))errorBlock;

// 是否开启草稿同步
- (void)setEnableSyncDraft:(BOOL)enable
                   success:(void(^)(void))successBlock
                     error:(void(^)(int errorCode))errorBlock;
```

### 2.7 搜索功能

#### 2.7.1 用户搜索

```objc
// 搜索类型
typedef NS_ENUM(NSInteger, WFCCSearchUserType) {
    SearchUserType_General,        // 模糊搜索
    SearchUserType_Name_Mobile,    // 精确匹配name或电话
    SearchUserType_Name,           // 精确匹配name
    SearchUserType_Mobile,         // 精确匹配电话
    SearchUserType_UserId,         // 精确匹配用户ID
    SearchUserType_Name_Mobile_UserId
};

// 搜索用户（可指定域）
- (void)searchUser:(NSString *)keyword
          domain:(NSString *)domainId
        searchType:(WFCCSearchUserType)searchType
          userType:(WFCCUserSearchUserType)userType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock;
```

#### 2.7.2 会话与消息搜索

```objc
// 搜索会话
- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword
                                               inConversation:(NSArray<NSNumber *> *)conversationTypes
                                                        lines:(NSArray<NSNumber *> *)lines
                                                    startTime:(int64_t)startTime
                                                      endTime:(int64_t)endTime
                                                         desc:(BOOL)desc
                                                        limit:(int)limit
                                                       offset:(int)offset;

// 搜索消息
- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                                     desc:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset
                                 withUser:(NSString *)withUser;

// 搜索提醒消息（@我）
- (NSArray<WFCCMessage *> *)searchMentionedMessages:(WFCCConversation *)conversation
                                            keyword:(NSString *)keyword
                                               desc:(BOOL)desc
                                              limit:(int)limit
                                             offset:(int)offset;
```

#### 2.7.3 文件搜索

```objc
// 搜索会话内文件
- (void)searchFiles:(NSString *)keyword
       conversation:(WFCCConversation *)conversation
           fromUser:(NSString *)fromUser
      beforeMessageUid:(long long)messageUid
              order:(WFCCFileRecordOrder)order
              count:(int)count
            success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
              error:(void(^)(int errorCode))errorBlock;

// 搜索我发送的文件
- (void)searchMyFiles:(NSString *)keyword
      beforeMessageUid:(long long)messageUid
                order:(WFCCFileRecordOrder)order
                count:(int)count
              success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                error:(void(^)(int errorCode))errorBlock;
```

### 2.8 消息状态与回执

#### 2.8.1 已送达回执

当消息成功送达对方客户端时，发送方会收到送达回执：

```objc
// Delivery Report 模型
@interface WFCCDeliveryReport : NSObject
@property(nonatomic, strong) NSString *userId;      // 用户ID
@property(nonatomic, assign) long long messageUid;  // 消息UID
@property(nonatomic, assign) long long timestamp;   // 送达时间
@end

// 接收送达回执的委托方法
- (void)onMessageDelivered:(NSArray<WFCCDeliveryReport *> *)delivereds;
```

#### 2.8.2 已读回执

当对方阅读消息后，发送方会收到已读回执：

```objc
// Read Report 模型
@interface WFCCReadReport : NSObject
@property(nonatomic, strong) NSString *userId;      // 用户ID
@property(nonatomic, assign) long long messageUid;  // 消息UID
@property(nonatomic, assign) long long timestamp;   // 阅读时间
@end

// 接收已读回执的委托方法
- (void)onMessageReaded:(NSArray<WFCCReadReport *> *)readeds;

// 发送已读回执
- (void)sendReadedMessage:(WFCCConversation *)conversation
                  messageId:(NSArray<NSNumber *> *)messageIds;
```

#### 2.8.3 正在输入状态

```objc
@interface WFCCTypingMessageContent : WFCCMessageContent
typedef NS_ENUM(NSInteger, WFCCTypingType) {
    Typing_TEXT = 0,    // 正在输入文本
    Typing_VOICE = 1    // 正在输入语音
};
@property(nonatomic, assign) WFCCTypingType typingType;
@end

// 发送正在输入状态
[[WFCCIMService sharedWFCIMService] sendMessage:conversation
                                        content:[WFCCTypingMessageContent contentWithType:Typing_TEXT]
                                        toUsers:nil
                                        success:nil
                                          error:nil];
```

### 2.9 聊天室功能

#### 2.9.1 聊天室信息

```objc
@interface WFCCChatroomInfo : WFCCJsonSerializer
@property(nonatomic, strong) NSString *chatroomId;      // 聊天室ID
@property(nonatomic, strong) NSString *title;           // 标题
@property(nonatomic, strong) NSString *desc;            // 描述
@property(nonatomic, strong) NSString *portrait;        // 头像
@property(nonatomic, strong) NSString *extra;           // 扩展信息
@property(nonatomic, assign) int state;                 // 状态（0正常，1未开始，2已结束）
@property(nonatomic, assign) int memberCount;           // 成员数量
@property(nonatomic, assign) long long createDt;        // 创建时间
@property(nonatomic, assign) long long updateDt;        // 更新时间
@end
```

#### 2.9.2 聊天室操作

```objc
// 获取聊天室信息
- (void)getChatroomInfo:(NSString *)chatroomId
               updateDt:(long long)updateDt
                success:(void(^)(WFCCChatroomInfo *chatroomInfo))successBlock
                  error:(void(^)(int errorCode))errorBlock;

// 加入聊天室
- (void)joinChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int errorCode))errorBlock;

// 退出聊天室
- (void)quitChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int errorCode))errorBlock;

// 获取聊天室成员
- (void)getChatroomMemberInfo:(NSString *)chatroomId
                     maxCount:(int)maxCount
                      success:(void(^)(WFCCChatroomMemberInfo *memberInfo))successBlock
                        error:(void(^)(int errorCode))errorBlock;
```

### 2.10 音视频会议功能

#### 2.10.1 会议事件监听

```objc
@protocol ConferenceEventDelegate <NSObject>
- (void)onConferenceEvent:(NSString *)event;
@end

// 设置监听
[WFCCNetworkService sharedInstance].conferenceEventDelegate = self;
```

#### 2.10.2 发送会议请求

```objc
// 基础会议请求
- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                         data:(NSString *)data
                      success:(void(^)(NSString *response))successBlock
                        error:(void(^)(int errorCode))errorBlock;

// 高级会议请求
- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                     advanced:(BOOL)advanced
                         data:(NSString *)data
                      success:(void(^)(NSString *response))successBlock
                        error:(void(^)(int errorCode))errorBlock;
```

### 2.11 推送配置

```objc
// 设置DeviceToken（APNs）
- (void)setDeviceToken:(NSString *)token;

// 设置DeviceToken（指定推送类型，如个推、极光）
- (void)setDeviceToken:(NSString *)token
              pushType:(int)pushType;

// 设置VoIP Token
- (void)setVoipDeviceToken:(NSString *)token;

// 设置角标数字
- (void)setBadgeNumber:(int)badge;
```

**推送类型枚举：**
```objc
typedef NS_ENUM(NSInteger, WFCCPushType) {
    PushType_APNS = 0,          // APNs
    PushType_Xiaomi = 1,        // 小米
    PushType_Huawei = 2,        // 华为
    PushType_Meizu = 3,         // 魅族
    PushType_Vivo = 4,          // Vivo
    PushType_Oppo = 5,          // Oppo
    PushType_Getui = 8,         // 个推
    PushType_JPush = 9          // 极光
};
```

### 2.12 事件通知机制

**全局通知名称：**

```objc
// 连接状态
extern NSString *kConnectionStatusChanged;      // 连接状态变化

// 消息相关
extern NSString *kSendingMessageStatusUpdated;  // 发送状态更新
extern NSString *kReceiveMessages;              // 收到新消息
extern NSString *kRecallMessages;               // 消息被撤回
extern NSString *kDeleteMessages;               // 消息被删除
extern NSString *kMessageUpdated;               // 消息更新
extern NSString *kMessageDelivered;             // 消息已送达
extern NSString *kMessageReaded;                // 消息已读

// 用户信息
extern NSString *kUserInfoUpdated;              // 用户信息更新
extern NSString *kFriendListUpdated;            // 好友列表更新
extern NSString *kFriendRequestUpdated;         // 好友请求更新

// 群组信息
extern NSString *kGroupInfoUpdated;             // 群组信息更新
extern NSString *kGroupMemberUpdated;           // 群成员更新
extern NSString *kJoinGroupRequestUpdated;      // 入群申请更新

// 频道信息
extern NSString *kChannelInfoUpdated;           // 频道信息更新

// 密聊
extern NSString *kSecretChatStateUpdated;       // 密聊状态更新
extern NSString *kSecretMessageStartBurning;    // 阅后即焚开始
extern NSString *kSecretMessageBurned;          // 阅后即焚完成

// 其他
extern NSString *kSettingUpdated;               // 设置更新
extern NSString *kDomainInfoUpdated;            // 域信息更新
extern NSString *kUserOnlineStateUpdated;       // 在线状态更新
```

**使用示例：**
```objc
// 注册监听
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(onReceiveMessages:)
                                             name:kReceiveMessages
                                           object:nil];

// 处理通知
- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    BOOL hasMore = [notification.userInfo[@"hasMore"] boolValue];
    // 处理消息...
}
```

---


## 三、WFChatUIKit 界面SDK

### 3.1 模块概述

**定位：** 提供开箱即用的IM界面组件库  
**核心职责：**
- 提供完整的聊天界面（消息列表、输入栏）
- 提供通讯录、会话列表等标准UI
- 提供音视频通话界面
- 提供群组管理、用户资料等辅助界面

**依赖关系：**
- 依赖 `WFChatClient` 功能SDK
- 依赖 `SDWebImage` 图片加载
- 依赖 `ZLPhotoBrowser` 图片选择
- 依赖 `WebRTC` 音视频框架（可选）

### 3.2 核心视图控制器

#### 3.2.1 会话列表

**WFCUConversationTableViewController**

最近会话列表控制器，展示所有会话的概要信息。

```objc
#import <WFChatUIKit/WFCUConversationTableViewController.h>

WFCUConversationTableViewController *vc = [[WFCUConversationTableViewController alloc] init];
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**特性：**
- 自动刷新会话列表
- 支持会话置顶、免打扰标识
- 支持未读数角标显示
- 支持左滑删除会话
- 支持搜索会话

#### 3.2.2 消息列表

**WFCUMessageListViewController**

核心聊天界面，支持单聊、群聊、频道、聊天室。

```objc
#import <WFChatUIKit/WFCUMessageListViewController.h>

WFCUMessageListViewController *vc = [[WFCUMessageListViewController alloc] init];
vc.conversation = [WFCCConversation conversationWithType:Single_Type target:@"userId" line:0];
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**属性配置：**
```objc
@property(nonatomic, strong) WFCCConversation *conversation;  // 会话标识
@property(nonatomic, assign) BOOL isChatroom;                  // 是否是聊天室
@property(nonatomic, strong) NSString *highlightMessageId;     // 高亮消息ID（用于搜索跳转）
```

**特性：**
- 支持文本、图片、语音、视频、文件等消息类型
- 支持消息撤回、删除、转发
- 支持引用回复
- 支持@提醒功能
- 支持消息搜索
- 支持已读回执显示
- 支持正在输入提示

#### 3.2.3 通讯录

**WFCUContactListViewController**

联系人列表，展示好友列表和组织架构（如果有）。

```objc
#import <WFChatUIKit/WFCUContactListViewController.h>

WFCUContactListViewController *vc = [[WFCUContactListViewController alloc] init];
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**特性：**
- 按字母分组显示好友
- 支持快速索引
- 支持搜索联系人
- 支持组织架构展示（需配置OrgService）

#### 3.2.4 用户资料

**WFCUProfileTableViewController**

查看其他用户资料的界面。

```objc
#import <WFChatUIKit/WFCUProfileTableViewController.h>

WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
vc.userId = @"targetUserId";
vc.groupId = @"groupId";  // 可选，用于显示群内昵称
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**WFCUMyProfileTableViewController**

查看和编辑当前用户资料。

```objc
WFCUMyProfileTableViewController *vc = [[WFCUMyProfileTableViewController alloc] init];
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

### 3.3 消息列表组件详解

#### 3.3.1 Cell体系

消息列表中的每种消息类型对应一个Cell类，都继承自 `WFCUMessageCellBase`。

**Cell继承关系：**
```
WFCUMessageCellBase
├── WFCUMessageCell（基类，处理气泡、头像等通用逻辑）
    ├── WFCUTextCell（文本消息）
    ├── WFCUImageCell（图片消息）
    ├── WFCUVoiceCell（语音消息）
    ├── WFCUVideoCell（视频消息）
    ├── WFCUFileCell（文件消息）
    ├── WFCULocationCell（位置消息）
    ├── WFCUCardCell（名片消息）
    ├── WFCULinkCell（链接消息）
    ├── WFCUStickerCell（贴纸消息）
    ├── WFCUArticlesCell（图文消息）
    ├── WFCURichNotificationCell（富文本通知）
    ├── WFCUStreamingTextCell（AI流式文本）
    ├── WFCUPollMessageCell（投票消息）
    ├── WFCUConferenceInviteCell（会议邀请）
    ├── WFCUPTTInviteCell（PTT邀请）
    ├── WFCURecallCell（撤回消息）
    ├── WFCUInformationCell（系统提示）
    ├── WFCUCallSummaryCell（通话记录）
    └── WFCUMultiCallOngoingCell（多人通话中）
```

**自定义Cell：**
```objc
// 1. 继承 WFCUMessageCell
@interface MyCustomCell : WFCUMessageCell
@end

// 2. 注册Cell
[tableView registerClass:[MyCustomCell class] forCellReuseIdentifier:@"my_custom_cell"];

// 3. 在 WFCUMessageListViewController 子类中返回自定义Cell
- (WFCUMessageCellBase *)cellForMessage:(WFCCMessage *)message {
    if (message.contentType == CUSTOM_CONTENT_TYPE) {
        return [MyCustomCell class];
    }
    return [super cellForMessage:message];
}
```

#### 3.3.2 消息模型

**WFCUMessageModel**

UI层消息模型，包装 `WFCCMessage` 并添加UI相关属性。

```objc
@interface WFCUMessageModel : NSObject
@property(nonatomic, strong) WFCCMessage *message;
@property(nonatomic, assign) BOOL isPlaying;        // 是否正在播放语音
@property(nonatomic, assign) BOOL isDownloading;    // 是否正在下载
@property(nonatomic, assign) CGFloat cellHeight;    // 缓存的Cell高度
@end
```

#### 3.3.3 消息操作

**长按菜单：**
- 复制（文本消息）
- 转发
- 收藏
- 撤回（2分钟内）
- 删除
- 多选
- 引用

**引用回复：**
```objc
// 显示引用视图
WFCUQuoteViewController *quoteVC = [[WFCUQuoteViewController alloc] init];
quoteVC.quoteMessage = message;
[self presentViewController:quoteVC animated:YES completion:nil];
```

### 3.4 聊天输入组件

#### 3.4.1 WFCUChatInputBar

输入栏主组件，位于消息列表底部。

**功能区域：**
1. **功能按钮** - 切换文本/语音输入
2. **输入框** - 文本输入
3. **语音按钮** - 按住说话
4. **表情按钮** - 打开表情面板
5. **更多按钮** - 打开功能面板（相册、拍照、位置等）

**配置属性：**
```objc
@property(nonatomic, weak) id<WFCUChatInputBarDelegate> delegate;
@property(nonatomic, assign) BOOL disableInput;         // 禁用输入
@property(nonatomic, strong) NSString *draft;           // 草稿
```

**委托方法：**
```objc
@protocol WFCUChatInputBarDelegate <NSObject>
- (void)onSendTextMessage:(NSString *)text;
- (void)onSendVoiceMessage:(NSString *)audioPath duration:(int)duration;
- (void)onSendStickerMessage:(WFCUStickerItem *)sticker;
- (void)onPickImage;
- (void)onTakePhoto;
- (void)onPickLocation;
- (void)onPickFile;
@end
```

#### 3.4.2 WFCUFaceBoard

表情面板，支持Emoji和自定义贴纸。

**结构：**
- Emoji标签页
- 贴纸标签页（多个Sticker Bundle）
- 发送按钮

**贴纸配置：**
贴纸资源位于 `WFChatUIKit/Resources/Stickers.bundle/` 目录下，每个子目录代表一个贴纸包。

#### 3.4.3 WFCUPluginBoardView

功能插件面板，提供快捷功能入口。

**默认功能：**
- 相册 - 选择图片/视频
- 拍摄 - 拍照/录像
- 位置 - 发送地理位置
- 文件 - 发送文件
- 语音通话
- 视频通话

**自定义插件：**
```objc
WFCUPluginItem *customItem = [[WFCUPluginItem alloc] init];
customItem.title = @"自定义";
customItem.image = [UIImage imageNamed:@"custom_icon"];
customItem.action = ^{
    // 执行自定义操作
};
[pluginBoardView addPluginItem:customItem];
```

#### 3.4.4 位置选择

**WFCULocationViewController**

发送位置消息时调用的地图选择界面。

```objc
WFCULocationViewController *vc = [[WFCULocationViewController alloc] init];
vc.delegate = self;
[self.navigationController pushViewController:vc animated:YES];

// 委托回调
- (void)onSelectLocation:(WFCULocationPoint *)locationPoint {
    WFCCLocationMessageContent *content = [[WFCCLocationMessageContent alloc] init];
    content.latitude = locationPoint.coordinate.latitude;
    content.longitude = locationPoint.coordinate.longitude;
    content.title = locationPoint.title;
    // 发送消息...
}
```

### 3.5 群组管理

#### 3.5.1 群组信息

**WFCUGroupInfoViewController**

群组信息设置界面，支持修改群名称、头像、公告等。

```objc
WFCUGroupInfoViewController *vc = [[WFCUGroupInfoViewController alloc] init];
vc.groupId = @"groupId";
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**功能：**
- 查看群成员
- 修改群名称/头像
- 设置群公告
- 群管理（禁言、加群方式等）
- 退出/解散群组

#### 3.5.2 群成员管理

**WFCUGroupMemberTableViewController**

群成员列表管理。

```objc
WFCUGroupMemberTableViewController *vc = [[WFCUGroupMemberTableViewController alloc] init];
vc.groupId = @"groupId";
vc.isManager = YES;  // 是否有管理权限
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

**WFCUGroupMemberCollectionViewController**

网格形式的群成员展示，用于会话设置页。

#### 3.5.3 群管理功能

**GroupManageTableViewController**

群管理主界面，包含：
- 管理员设置
- 群禁言设置
- 入群验证设置
- 群成员保护

**GroupMuteTableViewController**

群禁言设置，支持：
- 全员禁言
- 单独成员禁言
- 白名单设置

**WFCUGroupAnnouncementViewController**

群公告编辑和展示。

```objc
WFCUGroupAnnouncementViewController *vc = [[WFCUGroupAnnouncementViewController alloc] init];
vc.announcement = announcement;
vc.isManager = YES;  // 是否有编辑权限
[self.navigationController pushViewController:vc animated:YES];
```

### 3.6 聊天室

**ChatroomListViewController**

聊天室列表（应用层实现，参考 WildFireChat/Discover/chatroom/）。

**特性：**
- 展示可加入的聊天室列表
- 点击进入聊天室
- 聊天室消息界面复用 `WFCUMessageListViewController`

```objc
// 进入聊天室
WFCUMessageListViewController *vc = [[WFCUMessageListViewController alloc] init];
vc.conversation = [WFCCConversation conversationWithType:Chatroom_Type target:@"chatroomId" line:0];
vc.isChatroom = YES;
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

### 3.7 音视频通话

#### 3.7.1 基础通话

**WFCUVideoViewController**

1对1音视频通话界面。

```objc
#import <WFChatUIKit/WFCUVideoViewController.h>

WFCUVideoViewController *vc = [[WFCUVideoViewController alloc] init];
vc.conversation = conversation;
vc.isAudioOnly = NO;  // YES为音频通话，NO为视频通话
vc.isIncoming = YES;  // YES为接听，NO为拨打
vc.modalPresentationStyle = UIModalPresentationFullScreen;
[self presentViewController:vc animated:YES completion:nil];
```

**WFCUMultiVideoViewController**

多人音视频通话界面。

```objc
WFCUMultiVideoViewController *vc = [[WFCUMultiVideoViewController alloc] init];
vc.conversation = conversation;
vc.isAudioOnly = NO;
vc.modalPresentationStyle = UIModalPresentationFullScreen;
[self presentViewController:vc animated:YES completion:nil];
```

#### 3.7.2 会议系统

**会议UI组件结构：**
```
Voip/Conference/
├── WFCUConferenceViewController          # 会议主界面
├── WFCUConferenceManager                 # 会议管理器
├── WFCUConferenceInviteViewController    # 邀请参会
├── WFCUConferenceMemberManagerViewController  # 成员管理
├── WFCUConferenceHandupTableViewController    # 举手列表
├── WFCUConferenceUnmuteRequestTableViewController  # 解除静音请求
├── Cell/                                 # 会议Cell
│   ├── WFCUConferenceAudioCollectionViewCell   # 音频会议Cell
│   ├── WFCUConferenceMemberTableViewCell       # 成员列表Cell
│   └── WFCUConferenceParticipantCollectionViewCell  # 参会者视频Cell
├── Model/                                # 会议模型
│   ├── WFZConferenceInfo                       # 会议信息
│   ├── WFCUConferenceMember                    # 会议成员
│   └── WFCUConferenceHistory                   # 会议历史
├── Message/                              # 会议信令消息
│   ├── WFCUConferenceChangeModelContent        # 切换模式消息
│   └── WFCUConferenceCommandContent            # 会议命令消息
├── View/                                 # 会议视图
│   ├── WFCUConferenceLabelView                 # 会议标签视图
│   └── WFCUMoreBoardView                       # 更多操作面板
└── Zoom/                                 # Zoom风格会议UI
    ├── WFZHomeViewController                   # 会议首页
    ├── WFZStartConferenceViewController        # 发起会议
    ├── WFZOrderConferenceViewController        # 预约会议
    ├── WFZConferenceInfoViewController         # 会议详情
    └── WFZConferenceHistoryListViewController  # 会议历史
```

**发起会议：**
```objc
WFZStartConferenceViewController *vc = [[WFZStartConferenceViewController alloc] init];
vc.createResult = ^(WFZConferenceInfo *conferenceInfo) {
    // 会议创建成功，进入会议
    WFCUConferenceViewController *conferenceVC = [[WFCUConferenceViewController alloc] init];
    conferenceVC.conferenceInfo = conferenceInfo;
    [self presentViewController:conferenceVC animated:YES completion:nil];
};
[self.navigationController pushViewController:vc animated:YES];
```

**会议信息模型：**
```objc
@interface WFZConferenceInfo : NSObject
@property(nonatomic, strong) NSString *conferenceId;        // 会议ID
@property(nonatomic, strong) NSString *conferenceTitle;     // 会议标题
@property(nonatomic, strong) NSString *password;            // 密码
@property(nonatomic, strong) NSString *pin;                 // PIN码
@property(nonatomic, strong) NSString *owner;               // 主持人
@property(nonatomic, strong) NSArray<NSString *> *managers; // 管理员列表
@property(nonatomic, strong) NSString *focus;               // 焦点视频
@property(nonatomic, assign) long long startTime;           // 开始时间
@property(nonatomic, assign) long long endTime;             // 结束时间
@property(nonatomic, assign) BOOL audience;                 // 是否观众模式
@property(nonatomic, assign) BOOL advance;                  // 是否高级会议
@property(nonatomic, assign) BOOL allowTurnOnMic;           // 允许开麦
@property(nonatomic, assign) BOOL noJoinBeforeStart;        // 开始前禁止加入
@property(nonatomic, assign) BOOL recording;                // 是否录制
@property(nonatomic, assign) int maxParticipants;           // 最大参会人数
@end
```

### 3.8 消息转发与分享

**WFCUForwardViewController**

消息转发界面，支持选择转发目标。

```objc
WFCUForwardViewController *vc = [[WFCUForwardViewController alloc] init];
vc.message = message;  // 要转发的消息
vc.forwardDone = ^(WFCCConversation *conversation, BOOL success) {
    // 转发完成
};
UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
[self presentViewController:nav animated:YES completion:nil];
```

**转发类型：**
- 逐条转发 - 每条消息单独发送
- 合并转发 - 多条消息合并为一条转发

### 3.9 文件管理

**WFCUFilesEntryViewController**

文件入口界面，展示文件分类。

**WFCUFilesViewController**

文件列表界面，展示某个会话的文件记录。

```objc
WFCUFilesViewController *vc = [[WFCUFilesViewController alloc] init];
vc.conversation = conversation;
vc.hidesBottomBarWhenPushed = YES;
[self.navigationController pushViewController:vc animated:YES];
```

### 3.10 配置与工具

#### 3.10.1 WFCUConfigManager

UIKit全局配置管理器。

```objc
// 获取单例
WFCUConfigManager *manager = [WFCUConfigManager globalManager];

// 配置项
@property(nonatomic, strong) NSString *fileTransferId;      // 文件传输助手ID
@property(nonatomic, strong) NSString *aiRobotId;           // AI机器人ID
@property(nonatomic, strong) UIColor *backgroudColor;       // 背景色
@property(nonatomic, strong) UIColor *textColor;            // 文字颜色
@property(nonatomic, strong) UIColor *highlightColor;       // 高亮色
@property(nonatomic, assign) BOOL enableMessageBubbleStyle; // 是否使用气泡样式
```

#### 3.10.2 WFCUAppServiceProvider

应用服务协议，需要应用层实现。

```objc
@protocol WFCUAppServiceProvider <NSObject>
// 获取用户信息（异步）
- (void)getUserInfo:(NSString *)userId 
            success:(void(^)(WFCCUserInfo *userInfo))successBlock 
              error:(void(^)(int errorCode))errorBlock;

// 获取群组信息（异步）
- (void)getGroupInfo:(NSString *)groupId 
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock 
               error:(void(^)(int errorCode))errorBlock;

// 获取群公告
- (void)getGroupAnnouncement:(NSString *)groupId 
                     success:(void(^)(WFCUGroupAnnouncement *announcement))successBlock 
                       error:(void(^)(int errorCode))errorBlock;

// 设置群公告
- (void)setGroupAnnouncement:(NSString *)groupId 
                announcement:(WFCUGroupAnnouncement *)announcement 
                     success:(void(^)(void))successBlock 
                       error:(void(^)(int errorCode))errorBlock;
@end
```

**设置服务提供者：**
```objc
[WFCUConfigManager globalManager].appServiceProvider = myAppService;
```

---


## 四、WildFireChat 应用层

### 4.1 应用架构

WildFireChat 是完整的IM应用示例，展示了如何集成 Client 和 UIKit SDK。

**目录结构：**
```
wfchat/WildFireChat/
├── AppDelegate.{h,m}           # 应用入口
├── WFCConfig.{h,m}             # 服务器配置
├── Login/                      # 登录模块
├── Discover/                   # 发现页
│   ├── DiscoverViewController.{h,m}
│   ├── chatroom/               # 聊天室
│   └── chatroom/
├── Me/                         # 我的页面
├── Favorite/                   # 收藏功能
├── Moments/                    # 朋友圈（可选）
├── Things/                     # 物联网（已废弃）
├── Ptt/                        # 对讲机功能
├── AppService/                 # 应用层服务
├── OrgService/                 # 组织架构服务
├── PollService/                # 投票服务
├── CollectionService/          # 接龙服务
├── ShareExtension/             # 分享扩展
├── Broadcast/                  # 屏幕录制直播
├── Utilities/                  # 工具类
└── Vendor/                     # 第三方库
```

### 4.2 配置说明

**WFCConfig.h - 服务器配置**

```objc
// IM服务器地址
extern NSString *IM_SERVER_HOST;
extern int IM_SERVER_PORT;

// 应用服务器地址
extern NSString *APP_SERVER_ADDRESS;

// 组织通讯录服务地址（可选）
extern NSString *ORG_SERVER_ADDRESS;

// 工作台/开放平台地址（可选）
extern NSString *WORK_PLATFORM_URL;

// 文件传输助手用户ID
extern NSString *FILE_TRANSFER_ID;

// AI机器人用户ID
extern NSString *AI_ROBOT;
```

**示例配置（WFCConfig.m）：**
```objc
// IM服务器
NSString *IM_SERVER_HOST = @"im.wildfirechat.cn";
int IM_SERVER_PORT = 80;

// 应用服务器
NSString *APP_SERVER_ADDRESS = @"https://app.wildfirechat.net";

// 组织通讯录（可选，nil表示关闭）
NSString *ORG_SERVER_ADDRESS = nil;

// 工作台（可选，nil表示关闭）
NSString *WORK_PLATFORM_URL = @"https://open.wildfirechat.cn/work.html";

// 文件传输助手
NSString *FILE_TRANSFER_ID = @"wfc_file_transfer";

// AI机器人
NSString *AI_ROBOT = @"FireRobot";
```

### 4.3 初始化流程

**AppDelegate.m - 应用启动初始化**

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 1. 配置日志
    [WFCCNetworkService startLog];
    
    // 2. 设置UIKit配置
    [WFCUConfigManager globalManager].fileTransferId = FILE_TRANSFER_ID;
    [WFCUConfigManager globalManager].aiRobotId = AI_ROBOT;
    [WFCUConfigManager globalManager].appServiceProvider = [AppService sharedAppService];
    
    // 3. 连接IM服务器
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
    
    // 4. 检查自动登录
    if ([WFCCNetworkService sharedInstance].userId.length) {
        // 已登录，进入主界面
        [self switchToMainViewController];
    } else {
        // 未登录，进入登录界面
        [self switchToLoginViewController];
    }
    
    // 5. 注册推送
    [self registerPushService];
    
    return YES;
}
```

### 4.4 开放平台相关

#### 4.4.1 工作台

工作台是一个H5应用，集成在TabBar的"工作台"标签中。

```objc
// WFCBaseTabBarController.m
if (WORK_PLATFORM_URL.length) {
    WFCUBrowserViewController *browserVC = [[WFCUBrowserViewController alloc] init];
    browserVC.url = WORK_PLATFORM_URL;
    browserVC.tabBarItem.title = LocalizedString(@"Workbench");
    // ...
}
```

**配置说明：**
- `WORK_PLATFORM_URL` 设置为 `nil` 可关闭工作台功能
- 工作台项目开源地址：https://gitee.com/wfchat/open-platform

#### 4.4.2 机器人

**发现页机器人入口：**
```objc
// DiscoverViewController.m
self.dataSource = @[
    @{@"title":LocalizedString(@"Chatroom"), @"image":@"discover_chatroom", @"des":@"chatroom"},
    @{@"title":LocalizedString(@"Robot"), @"image":@"robot", @"des":@"robot"},
    @{@"title":LocalizedString(@"Channel"), @"image":@"chat_channel", @"des":@"channel"},
    // ...
];

// 点击机器人进入聊天
if ([des isEqualToString:@"robot"]) {
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:AI_ROBOT line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}
```

**机器人类型：**
- 文件传输助手 - 用于跨设备文件传输
- AI机器人 - 提供智能问答服务
- 自定义机器人 - 可在发现页添加多个机器人入口

#### 4.4.3 小程序支持

**PC端管理中的小程序登录状态：**
```objc
// PCSessionViewController.m
if (infos[0].platform == PlatformType_WX) {
    [logoutBtn setTitle:LocalizedString(@"LogoutMiniProgram") forState:UIControlStateNormal];
    [label setText:LocalizedString(@"MiniProgramLoggedIn")];
}
```

### 4.5 业务模块

#### 4.5.1 登录模块

**WFCLoginViewController**

支持手机号+验证码登录，也支持密码登录。

```objc
// 发送验证码
[[AppService sharedAppService] sendLoginCode:mobile success:^{} error:^(NSString * _Nonnull message) {}];

// 验证码登录
[[AppService sharedAppService] login:mobile verifyCode:code success:^(NSString * _Nonnull userId, NSString * _Nonnull token, BOOL newUser) {
    // 登录成功，连接IM服务器
    [[WFCCNetworkService sharedInstance] connect:userId token:token];
} error:^(NSString * _Nonnull message) {}];
```

#### 4.5.2 发现页

**DiscoverViewController**

发现页包含以下功能入口：
1. **朋友圈**（可选，需集成Moment库）
2. **聊天室** - 进入聊天室列表
3. **机器人** - 进入AI机器人聊天
4. **频道** - 进入频道列表
5. **会议**（可选，需支持VoIP）
6. **工作台**（如果配置）

#### 4.5.3 收藏功能

**WFCFavoriteTableViewController**

实现消息收藏功能，支持收藏：
- 文本消息
- 图片消息
- 语音消息
- 文件消息
- 位置消息
- 链接消息

```objc
// 添加收藏
[[AppService sharedAppService] addFavorite:message success:^(int favId) {} error:^(NSString * _Nonnull message) {}];

// 获取收藏列表
[[AppService sharedAppService] getFavoriteItems:0 count:100 success:^(NSArray<WFCUFavoriteItem *> * _Nonnull items, BOOL hasMore) {} error:^(NSString * _Nonnull message) {}];
```

#### 4.5.4 对讲机功能

**WFPttViewController**

实时语音对讲功能，类似对讲机体验。

### 4.6 扩展组件

#### 4.6.1 ShareExtension

系统分享扩展，支持从其他应用分享内容到野火IM。

**支持的分享类型：**
- 文本
- 图片
- 视频
- 文件
- 链接

#### 4.6.2 Broadcast（屏幕录制直播）

支持屏幕录制直播功能，包含：
- Broadcast - 录制处理
- BroadcastSetupUI - 录制设置界面

### 4.7 第三方推送

#### 4.7.1 个推集成

```objc
// 初始化个推
[GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret delegate:self];

// 注册VoIP推送
[GeTuiSdk registerVoipToken:self.voipToken];

// 收到推送后连接IM服务器
- (void)GeTuiSdkDidReceivePayload:(NSString *)payloadId andTaskId:(NSString *)taskId andMessageId:(NSString *)aMsgId andOffLine:(BOOL)offLine fromApplication:(NSString *)appId {
    // 连接IM服务器接收消息
    [[WFCCNetworkService sharedInstance] connect:token];
}
```

#### 4.7.2 CallKit集成

**WFCCallKitManager**

集成iOS CallKit框架，实现系统级来电体验。

```objc
// 报告来电
[[WFCCallKitManager sharedManager] reportIncomingCall:conversation audioOnly:isAudioOnly];

// 接听来电
[[WFCCallKitManager sharedManager] answerCall:uuid];

// 结束通话
[[WFCCallKitManager sharedManager] endCall:uuid];
```

---

## 五、第三方依赖

### 5.1 网络与数据

| 库名 | 版本 | 用途 | 来源 |
|------|------|------|------|
| AFNetworking | 4.x | 网络请求 | GitHub |
| CocoaAsyncSocket | 7.x | 异步Socket | GitHub |
| Mars | 最新 | 长连接协议栈 | Tencent |

### 5.2 图片与媒体

| 库名 | 版本 | 用途 | 来源 |
|------|------|------|------|
| SDWebImage | 5.x | 图片加载缓存 | GitHub |
| ZLPhotoBrowser | 4.x | 图片选择器 | GitHub |
| DNImagePicker | - | 图片选择（备用） | GitHub |
| MWPhotoBrowser | 2.x | 图片浏览器 | GitHub |
| KZSmallVideoRecorder | - | 小视频录制 | GitHub |
| VideoPlayerKit | - | 视频播放 | GitHub |
| libyuv | - | YUV图像处理 | Google |

### 5.3 UI组件

| 库名 | 版本 | 用途 | 来源 |
|------|------|------|------|
| MBProgressHUD | 1.x | 加载提示 | GitHub |
| TYAlertController | - | 弹窗 | GitHub |
| CCHMapClusterController | - | 地图聚类 | GitHub |
| XLPageViewController | - | 分页控制器 | GitHub |
| SDRefeshView | - | 下拉刷新 | GitHub |
| LBXScan | - | 二维码扫描 | GitHub |
| DACircularProgress | - | 圆形进度条 | GitHub |
| HWCircleView | - | 圆形进度 | GitHub |
| ZCCCircleProgressView | - | 圆形进度 | GitHub |
| KxMenu | - | 弹出菜单 | GitHub |
| UITextViewPlaceholder | - | 占位符 | GitHub |

### 5.4 工具库

| 库名 | 版本 | 用途 | 来源 |
|------|------|------|------|
| Pinyin | - | 拼音转换 | GitHub |
| YLGIFImage | - | GIF播放 | GitHub |
| YBAttributeTextTapAction | - | 富文本点击 | GitHub |
| dsbridge | - | JS桥接 | GitHub |

### 5.5 音视频

| 库名 | 版本 | 用途 | 来源 |
|------|------|------|------|
| WebRTC | Mxx | 实时音视频 | Google |
| WFAVEngineKit | - | 音视频引擎 | 野火IM |
| opencore-amrnb | - | AMR编解码 | - |

---

## 六、资源文件

### 6.1 国际化

多语言资源文件位于：
- `WFChatClient/en.lproj/wfc_client.strings` - 客户端英文
- `WFChatClient/zh-Hans.lproj/wfc_client.strings` - 客户端简体中文
- `WFChatClient/zh-Hant.lproj/wfc_client.strings` - 客户端繁体中文
- `WFChatUIKit/Resources/en.lproj/wfc.strings` - UIKit英文
- `WFChatUIKit/Resources/zh-Hans.lproj/wfc.strings` - UIKit简体中文
- `WFChatUIKit/Resources/zh-Hant.lproj/wfc.strings` - UIKit繁体中文

**常用词条：**
```ini
; 通用
"Send" = "发送";
"Cancel" = "取消";
"Delete" = "删除";
"Copy" = "复制";
"Forward" = "转发";
"Recall" = "撤回";

; 会话相关
"Conversation" = "会话";
"Draft" = "草稿";
"Message" = "消息";

; 机器人/开放平台
"Robot" = "机器人";
"MiniProgramLoggedIn" = "小程序已登录";
"LogoutMiniProgram" = "退出小程序登录";
```

### 6.2 图片资源

**WFChatUIKit.xcassets 包含：**
- 聊天气泡（发送/接收）
- 功能图标（相机、相册、位置等）
- 消息状态图标（发送中、发送失败、已送达、已读）
- 文件类型图标（PDF、Word、Excel等）
- 通话相关图标
- 会议相关图标

**Stickers.bundle 贴纸包：**
- 默认包含两组贴纸
- 可自定义添加贴纸包

### 6.3 其他资源

**Emoj.plist**
- Emoji表情配置列表

**unicode_to_hanyu_pinyin.txt**
- 拼音转换数据表，用于联系人排序

---


## 七、集成指南

### 7.1 快速集成

#### 7.1.1 源码集成

1. **添加子项目到主工程**
   - 将 `wfclient/WFChatClient.xcodeproj` 添加到主工程
   - 将 `wfuikit/WFChatUIKit.xcodeproj` 添加到主工程

2. **设置依赖关系**
   - 主工程依赖 `WFChatUIKit` 和 `WFChatClient`
   - `WFChatUIKit` 已自动依赖 `WFChatClient`

3. **添加Framework依赖**
   ```
   Build Phases -> Link Binary With Libraries:
   - WFChatClient.framework
   - WFChatUIKit.framework
   ```

4. **Embed动态库**
   ```
   Build Phases -> Embed Frameworks:
   - WFChatClient.framework (Embed)
   - WFChatUIKit.framework (Embed)
   ```

#### 7.1.2 动态库集成

使用 `release_libs.sh` 脚本打包动态库：

```bash
./release_libs.sh
```

打包后会生成 `Libs&Resources` 目录，包含：
- `WFChatClient.framework`
- `WFChatUIKit.framework`
- `WFChatUIKit.bundle`（资源文件）

将这些文件添加到主工程即可。

#### 7.1.3 Info.plist 配置

```xml
<!-- 支持混合本地化 -->
<key>CFBundleAllowMixedLocalizations</key>
<true/>

<!-- 权限声明 -->
<key>NSCameraUsageDescription</key>
<string>需要相机权限用于拍照、视频通话和扫描二维码</string>

<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限用于发送语音消息和音视频通话</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限用于发送图片和视频</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>需要位置权限用于发送地理位置消息</string>

<!-- VoIP推送（可选） -->
<key>UIBackgroundModes</key>
<array>
    <string>voip</string>
    <string>audio</string>
    <string>fetch</string>
</array>
```

### 7.2 初始化流程

#### 7.2.1 基础初始化

```objc
#import <WFChatClient/WFChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

// 1. 配置服务器地址
NSString *IM_SERVER_HOST = @"your.im.server.com";
int IM_SERVER_PORT = 80;

// 2. 启动日志（调试时开启）
[WFCCNetworkService startLog];

// 3. 设置UIKit配置
[WFCUConfigManager globalManager].fileTransferId = @"wfc_file_transfer";
[WFCUConfigManager globalManager].aiRobotId = @"FireRobot";

// 4. 连接服务器
[[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
```

#### 7.2.2 登录集成

```objc
// 使用野火提供的App Server登录
[[AppService sharedAppService] login:mobile verifyCode:code success:^(NSString *userId, NSString *token, BOOL newUser) {
    // 连接IM服务器
    long long lastActiveTime = [[WFCCNetworkService sharedInstance] connect:userId token:token];
    
    if (lastActiveTime > 0) {
        // 同步历史消息
        [self showSyncingView];
    }
} error:^(NSString *message) {
    // 登录失败
}];
```

#### 7.2.3 推送配置

**APNs推送：**
```objc
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[WFCCNetworkService sharedInstance] setDeviceToken:token];
}
```

### 7.3 关键接口使用

#### 7.3.1 发送消息

```objc
// 构建会话
WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:@"userId" line:0];

// 文本消息
WFCCTextMessageContent *textContent = [WFCCTextMessageContent contentWithText:@"Hello"];

// 发送
WFCCMessage *message = [[WFCCIMService sharedWFCIMService] sendMessage:conversation
                                                               content:textContent
                                                               toUsers:nil
                                                               success:^(long long messageUid, long long timestamp) {
    // 发送成功
} error:^(int error_code) {
    // 发送失败
}];
```

#### 7.3.2 创建群组

```objc
// 创建群组
[[WFCCIMService sharedWFCIMService] createGroup:@"群名称"
                                      portrait:@"头像URL"
                                       members:@[@"user1", @"user2"]
                                          type:GroupType_Normal
                                         extra:nil
                                       success:^(NSString *groupId) {
    // 创建成功，进入群聊
    WFCUMessageListViewController *vc = [[WFCUMessageListViewController alloc] init];
    vc.conversation = [WFCCConversation conversationWithType:Group_Type target:groupId line:0];
    [self.navigationController pushViewController:vc animated:YES];
} error:^(int errorCode) {
    // 创建失败
}];
```

---

## 八、进阶开发

### 8.1 自定义消息类型

#### 8.1.1 创建消息内容类

```objc
// MyCustomMessageContent.h
#import <WFChatClient/WFChatClient.h>

@interface MyCustomMessageContent : WFCCMessageContent
@property(nonatomic, strong) NSString *customData;
@property(nonatomic, assign) int customType;
@end
```

#### 8.1.2 注册消息解析器

```objc
// AppDelegate.m
#import "MyCustomMessageContent.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 注册自定义消息类型
    [WFCCMessageContent registerMessageContentClass:[MyCustomMessageContent class]];
    return YES;
}
```

### 8.2 UI自定义

```objc
// 配置主题色
[WFCUConfigManager globalManager].backgroudColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
[WFCUConfigManager globalManager].textColor = [UIColor blackColor];
[WFCUConfigManager globalManager].highlightColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
```

---

## 九、附录

### 9.1 错误码定义

**连接错误：**
| 错误码 | 说明 |
|--------|------|
| -9 | 时间不一致 |
| -8 | 未授权 |
| -7 | 被踢下线 |
| -6 | 密钥错误 |
| -5 | Token错误 |
| -4 | 服务器关闭 |
| -3 | 被拒绝 |
| -2 | 退出登录 |
| -1 | 未连接 |

**发送错误：**
| 错误码 | 说明 |
|--------|------|
| 1 | 发送失败 |
| 2 | 被拉黑 |
| 3 | 被禁言 |
| 4 | 内容敏感 |
| 5 | 超出频率限制 |

### 9.2 常见问题

**Q: 如何调试网络问题？**
A: 开启日志 `[WFCCNetworkService startLog]`，日志文件位于应用沙盒的 `log` 目录。

**Q: 消息发送失败如何处理？**
A: 检查连接状态，实现错误回调进行重试或提示用户。

**Q: 是否支持离线消息？**
A: 支持，客户端上线后会自动拉取离线期间的消息。

---

## 文档结束

**版权所有：** 北京野火无限网络科技有限公司  
**开源协议：** Creative Commons Attribution-NoDerivs 3.0 Unported + 996ICU  
**项目地址：** https://github.com/wildfirechat/ios-chat

