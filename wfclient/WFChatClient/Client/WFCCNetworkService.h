//
//  WFCCNetworkService.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef WFCCNetworkService_h
#define WFCCNetworkService_h

#import <Foundation/Foundation.h>
#import "WFCCMessage.h"

extern const NSString *SDKVERSION;
#pragma mark - 频道通知定义
//群组信息更新通知
extern NSString *kGroupInfoUpdated;
//群组成员更新通知
extern NSString *kGroupMemberUpdated;
//用户信息更新通知
extern NSString *kUserInfoUpdated;
//好友列表更新通知
extern NSString *kFriendListUpdated;
//好友请求信息更新通知
extern NSString *kFriendRequestUpdated;
//设置更新通知
extern NSString *kSettingUpdated;
//频道信息更新通知
extern NSString *kChannelInfoUpdated;

#pragma mark - 枚举值定义
/**
 连接状态

 - kConnectionStatusSecretKeyMismatch 密钥错误
 - kConnectionStatusTokenIncorrect Token错误
 - kConnectionStatusServerDown 服务器关闭
 - kConnectionStatusRejected: 被拒绝
 - kConnectionStatusLogout: 退出登录
 - kConnectionStatusUnconnected: 未连接
 - kConnectionStatusConnecting: 连接中
 - kConnectionStatusConnected: 已连接
 - kConnectionStatusReceiving: 获取离线消息中，可忽略
 */
typedef NS_ENUM(NSInteger, ConnectionStatus) {
  kConnectionStatusSecretKeyMismatch = -6,
  kConnectionStatusTokenIncorrect = -5,
  kConnectionStatusServerDown = -4,
  kConnectionStatusRejected = -3,
  kConnectionStatusLogout = -2,
  kConnectionStatusUnconnected = -1,
  kConnectionStatusConnecting = 0,
  kConnectionStatusConnected = 1,
  kConnectionStatusReceiving = 2
};

#pragma mark - 连接状态&消息监听
/**
 连接状态的监听
 */
@protocol ConnectionStatusDelegate <NSObject>

/**
 连接状态变化的回调

 @param status 连接状态
 */
- (void)onConnectionStatusChanged:(ConnectionStatus)status;

@end

/**
 消息接收的监听
 */
@protocol ReceiveMessageDelegate <NSObject>

/**
 接收消息的回调

 @param messages 收到的消息
 @param hasMore 是否还有待接受的消息，UI可以根据此参数决定刷新的时机
 */
- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore;

@optional
- (void)onRecallMessage:(long long)messageUid;
@end

/**
 接收消息前的拦截Filter
 */
@protocol ReceiveMessageFilter <NSObject>

/**
 是否拦截收到的消息

 @param message 消息
 @return 是否拦截，如果拦截该消息，则ReceiveMessageDelegate回调不会再收到此消息
 */
- (BOOL)onReceiveMessage:(WFCCMessage *)message;
@end

#pragma mark - 连接服务
/**
 连接服务
 */
@interface WFCCNetworkService : NSObject

/**
 连接服务单例

 @return 连接服务单例
 */
+ (WFCCNetworkService *)sharedInstance;

/**
 连接状态监听
 */
@property(nonatomic, weak) id<ConnectionStatusDelegate> connectionStatusDelegate;

/**
 消息接收监听
 */
@property(nonatomic, weak) id<ReceiveMessageDelegate> receiveMessageDelegate;

/**
 当前是否处于登陆状态
 */
@property(nonatomic, assign, getter=isLogined, readonly)BOOL logined;

/**
 当前的连接状态
 */
@property(nonatomic, assign, readonly)ConnectionStatus currentConnectionStatus;

/**
 当前登陆的用户ID
 */
@property (nonatomic, strong, readonly)NSString *userId;

/**
 服务器时间与本地时间的差值
 */
@property(nonatomic, assign, readonly)long long serverDeltaTime;

/**
 开启Log
 */
+ (void)startLog;

/**
 停止Log
 */
+ (void)stopLog;

/**
 获取客户端id
 
 @return 客户端ID
 */
- (NSString *)getClientId;

/**
 连接服务器

 @param userId 用户Id
 @param token 密码
 
 @return 是否是第一次连接。第一次连接需要同步用户信息，耗时较长，可以加个第一次登录的等待提示界面。
 */
- (BOOL)connect:(NSString *)userId token:(NSString *)token;

/**
 断开连接

 @param clearSession 是否清除Session信息
 */
- (void)disconnect:(BOOL)clearSession;

/**
 设置服务器信息

 @param host 服务器地址
 */
- (void)setServerAddress:(NSString *)host port:(uint)port;

/**
 设置当前设备的device token

 @param token 苹果APNs Device Token
 */
- (void)setDeviceToken:(NSString *)token;

/**
 设置当前设备的Voip device token
 
 @param token 苹果APNs Device Token
 */
- (void)setVoipDeviceToken:(NSString *)token;

/**
 添加消息拦截Filter

 @param filter 消息拦截Filter
 */
- (void)addReceiveMessageFilter:(id<ReceiveMessageFilter>)filter;

/**
 移除消息拦截Filter

 @param filter 消息拦截Filter
 */
- (void)removeReceiveMessageFilter:(id<ReceiveMessageFilter>)filter;

/**
 应用已经login且在后台的情况下，强制进行连接，确保后台连接5秒钟，用于voip推送后台刷新等场景。
 应用在前台情况下，此方法无效。
 */
- (void)forceConnect:(NSUInteger)second;

- (void)cancelForceConnect;
@end

#endif
