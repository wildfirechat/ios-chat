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
#import "WFCCReadReport.h"
#import "WFCCDeliveryReport.h"

extern const NSString *SDKVERSION;
#pragma mark - 通知定义
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
//用户在线状态更新通知
extern NSString *kUserOnlineStateUpdated;
//密聊状态更新通知
extern NSString *kSecretChatStateUpdated;
//密聊消息阅后即焚开始计时
extern NSString *kSecretMessageStartBurning;
//密聊消息阅后即焚完成
extern NSString *kSecretMessageBurned;

#pragma mark - 枚举值定义
/**
 连接状态

 - kConnectionStatusKickedoff 多端登录被迫下线。
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
  //错误码kConnectionStatusKickedoff是IM服务2021.9.15之后的版本才支持，并且打开服务器端开关server.client_support_kickoff_event
  kConnectionStatusKickedoff = -7,
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


/**
平台枚举值

 //Platform_Android = 2,
 //Platform_Windows = 3,
 //Platform_OSX = 4,
 //Platform_WEB = 5,
 //Platform_WX = 6,
 //Platform_Linux = 7,
 //Platform_iPad = 8,
 //Platform_APad = 9,
*/
#define Platform_iOS 1
#define Platform_iPad 8

    
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
 连接状态的监听
 */
@protocol ConnectToServerDelegate <NSObject>

/**
 成功连到某个服务的回调

 @param host  服务Host
 @param ip       服务ip
 @param port   服务端口
 */
- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port;

@end

/**
 网络流量使用监听
 */
@protocol TrafficDataDelegate <NSObject>

/**
 网络产生流量的回调

 @param send  发送的字节数
 @param recv 收到的字节数
 */
- (void)onTrafficData:(int64_t)send recv:(int64_t)recv;

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
- (void)onDeleteMessage:(long long)messageUid;

/**
消息已送达到目标用户的回调

@param delivereds 送达报告
*/

- (void)onMessageDelivered:(NSArray<WFCCDeliveryReport *> *)delivereds;

/**
消息已读的监听
*/
- (void)onMessageReaded:(NSArray<WFCCReadReport *> *)readeds;
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

/**
 会议事件的监听
 */
@protocol ConferenceEventDelegate <NSObject>

/**
 会议事件的回调

 @param event 事件
 */
- (void)onConferenceEvent:(NSString *)event;
@end

@class WFCCUserOnlineState;
/**
 在线事件的监听
 */
@protocol OnlineEventDelegate <NSObject>

/**
 在线事件的回调

 @param events 事件
 */
- (void)onOnlineEvent:(NSArray<WFCCUserOnlineState *> *)events;
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
 连接到服务监听
 */
@property(nonatomic, weak) id<ConnectToServerDelegate> connectToServerDelegate;

/**
 网络流量监听
 */
@property(nonatomic, weak) id<TrafficDataDelegate> trafficDataDelegate;

/**
 消息接收监听
 */
@property(nonatomic, weak) id<ReceiveMessageDelegate> receiveMessageDelegate;

/**
会议事件监听
*/
@property(nonatomic, weak) id<ConferenceEventDelegate> conferenceEventDelegate;

/**
在线事件监听
*/
@property(nonatomic, weak) id<OnlineEventDelegate> onlineEventDelegate;

/**
 当前是否处于登录状态
 */
@property(nonatomic, assign, getter=isLogined, readonly)BOOL logined;

/**
 当前的连接状态
 */
@property(nonatomic, assign, readonly)ConnectionStatus currentConnectionStatus;

/**
 当前登录的用户ID
 */
@property (nonatomic, strong, readonly)NSString *userId;

/**
 服务器时间与本地时间的差值
 */
@property(nonatomic, assign, readonly)long long serverDeltaTime;

/**
 发送日志命令
 */
@property (nonatomic, strong)NSString *sendLogCommand;

/**
 开启Log
 */
+ (void)startLog;

/**
 停止Log
 */
+ (void)stopLog;

/**
获取日志文件路径
*/
+ (NSArray<NSString *> *)getLogFilesPath;

/*
 使用国密加密。注意必须和服务器同时配置，否则无法连接。
 */
- (void)useSM4;

/**
 设置Lite模式。
 Lite模式下，协议栈不存储数据库，不同步所有信息，只能收发消息，接收消息只接收连接以后发送的消息。
 此函数只能在connect之前调用。
 
 @param isLiteMode 是否Lite模式
 */
- (void)setLiteMode:(BOOL)isLiteMode;

/**
 获取客户端id
 
 @return 客户端ID
 */
- (NSString *)getClientId;

/**
 连接服务器，需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）

 @param userId 用户Id
 @param token 密码
 
 @return 是否是第一次连接。第一次连接需要同步用户信息，耗时较长，可以加个第一次登录的等待提示界面。
 */
- (BOOL)connect:(NSString *)userId token:(NSString *)token;

/**
 断开连接

 @param disablePush   是否停止推送，clearSession为YES时无意义。如果为true，session会变成disable状态，token会失效，必须重新获取token才能登录。
 @param clearSession 是否清除Session信息，如果清除本地历史消息将全部清除，且token失效无法再次登录，必须重新获取token才能进行登录。
 */
- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession;

/**
 设置服务器信息。host可以是IP，可以是域名，如果是域名的话只支持主域名或www域名，二级域名不支持！
 例如：example.com或www.example.com是支持的；xx.example.com或xx.yy.example.com是不支持的。

 @param host 服务器地址
 */
- (void)setServerAddress:(NSString *)host;

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

/*
 设置备选服务地址，仅专业版支持，一般用于政企单位内外网两种网络环境。
 */
- (void)setBackupAddressStrategy:(int)strategy;
- (void)setBackupAddress:(NSString *)host port:(int)port;

/*
 设置协议栈短连接User agent。
 
 @param userAgent  User agent
 */
- (void)setProtoUserAgent:(NSString *)userAgent;

/*
 添加协议栈短连接自定义header，value为空时清除该header。
 
 @param header header
 @param value  value
 */
- (void)addHttpHeader:(NSString *)header value:(NSString *)value;

/*
 设置代理，注意只能支持socks5代理，http代理无法支持，只有专业版支持次功能。
 
 @param host     代理服务域名，host和ip至少要有一个有效值。
 @param ip       代理服务IP地址，host和ip至少要有一个有效值。
 @param port     代理服务端口
 @param username 账户
 @param password 密码
 */
- (void)setProxyInfo:(NSString *)host ip:(NSString *)ip port:(int)port username:(NSString *)username password:(NSString *)password;

/**
 获取协议栈版本
 */
- (NSString *)getProtoRevision;
@end

#endif
