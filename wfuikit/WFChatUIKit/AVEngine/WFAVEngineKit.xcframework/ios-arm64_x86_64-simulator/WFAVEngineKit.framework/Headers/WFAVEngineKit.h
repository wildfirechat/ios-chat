//
//  WFAVEngineKit.h
//  WFAVEngineKit
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for WFAVEngineKit.
FOUNDATION_EXPORT double WFAVEngineKitVersionNumber;

//! Project version string for WFAVEngineKit.
FOUNDATION_EXPORT const unsigned char WFAVEngineKitVersionString[];

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import <WFChatClient/WFCChatClient.h>

@class WFAVCallSession;

#pragma mark - 通知定义
//通话状态更新通知
extern NSString *kCallStateUpdated;


#pragma mark - 枚举值定义
/**
 通话状态

 - kWFAVEngineStateIdle: 无通话状态
 - kWFAVEngineStateOutgoing: 呼出中
 - kWFAVEngineStateIncomming: 呼入中
 - kWFAVEngineStateConnecting: 建立中
 - kWFAVEngineStateConnected: 通话中
 */
typedef NS_ENUM(NSInteger, WFAVEngineState) {
  kWFAVEngineStateIdle,
  kWFAVEngineStateOutgoing,
  kWFAVEngineStateIncomming,
  kWFAVEngineStateConnecting,
  kWFAVEngineStateConnected
};

/**
 缩放模式

 - kWFAVVideoScalingTypeAspectFit: 填满屏幕，裁去多余部分。如果视图和视频的方向不一致，则缩放模式自动采用kWFAVVideoScalingTypeAspectFill模式，因为如果要是裁边会裁去过多内容。
 - kWFAVVideoScalingTypeAspectFill: 显示所有内容，背景会留黑边
 - kWFAVVideoScalingTypeAspectBalanced: 平衡，Fit和Fill折中
 - kWFAVVideoScalingTypeScaleFill: 拉伸填满
 */
typedef NS_ENUM(NSInteger, WFAVVideoScalingType) {
    kWFAVVideoScalingTypeAspectFit,
    kWFAVVideoScalingTypeAspectFill,
    kWFAVVideoScalingTypeAspectBalanced,
    kWFAVVideoScalingTypeScaleFill
};

/**
 视频属性
 分辨率(宽x高), 帧率(fps),码率(kpbs)

 - kWFAVVideoProfile120P:       160x120,    15, 120
 - kWFAVVideoProfile120P_3:     120x120,    15, 100
 - kWFAVVideoProfile180P:       320x180,    15, 280
 - kWFAVVideoProfile180P_3:     180x180,    15, 200
 - kWFAVVideoProfile180P_4:     240x180,    15, 240
 - kWFAVVideoProfile240P:       320x240,    15, 360
 - kWFAVVideoProfile240P_3:     240x240,    15, 280
 - kWFAVVideoProfile240P_4:     424x240,    15, 400
 - kWFAVVideoProfile360P:       640x360,    15, 800
 - kWFAVVideoProfile360P_3:     360x360,    15, 520
 - kWFAVVideoProfile360P_4:     640x360,    30, 1200
 - kWFAVVideoProfile360P_6:     360x360,    30, 780
 - kWFAVVideoProfile360P_7:     480x360,    15, 1000
 - kWFAVVideoProfile360P_8:     480x360,    30, 1500
 - kWFAVVideoProfile480P:       640x480,    15, 1000
 - kWFAVVideoProfile480P_3:     480x480,    15, 800
 - kWFAVVideoProfile480P_4:     640x480,    30, 1500
 - kWFAVVideoProfile480P_6:     480x480,    30, 1200
 - kWFAVVideoProfile480P_8:     848x480,    15, 1200
 - kWFAVVideoProfile480P_9:     848x480,    30, 1800
 - kWFAVVideoProfile720P:       1280x720,   15, 2400
 - kWFAVVideoProfile720P_3:     1280x720,   30, 3699
 - kWFAVVideoProfile720P_5:     960x720,    15, 1920
 - kWFAVVideoProfile720P_6:     960x720,    30, 2880
 - kWFAVVideoProfileDefault:    默认值kWFAVVideoProfile360P
 */
typedef NS_ENUM(NSInteger, WFAVVideoProfile) {
    kWFAVVideoProfile120P       = 0,
    kWFAVVideoProfile120P_3     = 2,
    kWFAVVideoProfile180P       = 10,
    kWFAVVideoProfile180P_3     = 12,
    kWFAVVideoProfile180P_4     = 13,
    kWFAVVideoProfile240P       = 20,
    kWFAVVideoProfile240P_3     = 22,
    kWFAVVideoProfile240P_4     = 23,
    kWFAVVideoProfile360P       = 30,
    kWFAVVideoProfile360P_3     = 32,
    kWFAVVideoProfile360P_4     = 33,
    kWFAVVideoProfile360P_6     = 35,
    kWFAVVideoProfile360P_7     = 36,
    kWFAVVideoProfile360P_8     = 37,
    kWFAVVideoProfile480P       = 40,
    kWFAVVideoProfile480P_3     = 42,
    kWFAVVideoProfile480P_4     = 43,
    kWFAVVideoProfile480P_6     = 45,
    kWFAVVideoProfile480P_8     = 47,
    kWFAVVideoProfile480P_9     = 48,
    kWFAVVideoProfile720P       = 50,
    kWFAVVideoProfile720P_3     = 52,
    kWFAVVideoProfile720P_5     = 54,
    kWFAVVideoProfile720P_6     = 55,
    kWFAVVideoProfileDefault    = kWFAVVideoProfile360P
};

/**
 通话结束原因
 - kWFAVCallEndReasonUnknown: 未知错误
 - kWFAVCallEndReasonBusy: 忙线
 - kWFAVCallEndReasonSignalError: 链路错误
 - kWFAVCallEndReasonHangup: 用户挂断
 - kWFAVCallEndReasonMediaError: 媒体错误
 - kWFAVCallEndReasonRemoteHangup: 对方挂断
 - kWFAVCallEndReasonOpenCameraFailure: 摄像头错误
 - kWFAVCallEndReasonTimeout: 未接听
 - kWFAVCallEndReasonAcceptByOtherClient: 被其它端接听
 - kWFAVCallEndReasonRemoteBusy: 对方忙线中
 - kWFAVCallEndReasonRemoteTimeout：对方未接听
 - kWFAVCallEndReasonRemoteNetworkError：对方网络错误
 - kWFAVCallEndReasonRoomDestroyed：会议室被销毁
 */
typedef NS_ENUM(NSInteger, WFAVCallEndReason) {
  kWFAVCallEndReasonUnknown = 0,
  kWFAVCallEndReasonBusy,
  kWFAVCallEndReasonSignalError,
  kWFAVCallEndReasonHangup,
  kWFAVCallEndReasonMediaError,
  kWFAVCallEndReasonRemoteHangup,
  kWFAVCallEndReasonOpenCameraFailure,
  kWFAVCallEndReasonTimeout,
  kWFAVCallEndReasonAcceptByOtherClient,
  kWFAVCallEndReasonAllLeft,
  kWFAVCallEndReasonRemoteBusy,
  kWFAVCallEndReasonRemoteTimeout,
  kWFAVCallEndReasonRemoteNetworkError,
  kWFAVCallEndReasonRoomDestroyed,
  kWFAVCallEndReasonRoomNotExist,
  kWFAVCallEndReasonRoomParticipantsFull
};

#pragma mark - 通话监听
/**
 全局的通话事件监听
 */
@protocol WFAVEngineDelegate <NSObject>

/**
 收到通话的回调

 @param session 通话Session
 */
- (void)didReceiveCall:(WFAVCallSession *)session;

/**
 播放铃声的回调

 @param isIncoming 来电或去电
 */
- (void)shouldStartRing:(BOOL)isIncoming;

/**
 停止播放铃声的回调
 */
- (void)shouldStopRing;

/**
 电话终止，一般用于未接听或者挂掉时的通知使用，UI界面需要根据CallSession的回调判断电话终止。
 */
- (void)didCallEnded:(WFAVCallEndReason) reason duration:(int)callDuration;
@end

/**
 每次通话Session的事件监听
 */
@protocol WFAVCallSessionDelegate <NSObject>

/**
 通话状态变更的回调
 
 @param state 通话状态
 */
- (void)didChangeState:(WFAVEngineState)state;

//多人音视频版本会调用到
- (void)didParticipantJoined:(NSString *_Nonnull)userId screenSharing:(BOOL)screenSharing;

//多人音视频版本会调用到
- (void)didParticipantConnected:(NSString *_Nonnull)userId screenSharing:(BOOL)screenSharing;

//多人音视频版本会调用到
- (void)didParticipantLeft:(NSString *_Nonnull)userId screenSharing:(BOOL)screenSharing withReason:(WFAVCallEndReason)reason;



/**
 通话结束的回调

 @param reason 通话结束的原因
 */
- (void)didCallEndWithReason:(WFAVCallEndReason)reason;

/**
 通话发生错误的回调

 @param error 错误
 */
- (void)didError:(NSError *)error;

/**
 通话模式发生变化的回调
 
 @param isAudioOnly 是否是纯语音
 */
- (void)didChangeMode:(BOOL)isAudioOnly;

/**
 通话状态统计的回调

 @param stats 统计信息
 */
- (void)didGetStats:(NSArray *)stats;

/**
 创建本地视频流的回调

 @param localVideoTrack 本地视频流
 */
- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack;

/**
 收到对方视频流的回调

 @param remoteVideoTrack 对方视频流
 @param screenSharing 是否是共享屏幕

 */
- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack * _Nonnull)remoteVideoTrack fromUser:(NSString *_Nonnull)userId screenSharing:(BOOL)screenSharing;


@optional
/**
语音音量报告

@param volume 音量
@param userId 用户Id
*/
- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString *_Nonnull)userId;

/**
用户类型改变

@param audience 是否是观众
@param userId 用户Id
*/
- (void)didChangeType:(BOOL)audience ofUser:(NSString *_Nonnull)userId;

/**
音频播放port发送改变，当蓝牙设备/耳机 连接/断开连接时回调
*/
- (void)didChangeAudioRoute;

/**
用户视频mute状态改变，包括音频和视频，只有会议才会有此回调。

@param userIds 改变mute状态的用户列表
*/
- (void)didMuteStateChanged:(NSArray<NSString *> *_Nonnull)userIds;

/**
 当前用户发送媒体丢包回调
 
 @param media 媒体类型，audio或video
 @param lostPackage 丢包数
 @param screenSharing 是否是共享屏幕

 */
- (void)didMedia:(NSString *_Nullable)media lostPackage:(int)lostPackage screenSharing:(BOOL)screenSharing;

/**
 接受对应用户媒体丢包回调，uplink为true是对方丢的，false是己方丢的。
 
 @param media 媒体类型，audio或video
 @param lostPackage 丢包数
 @param uplink 方向
 @param userId 用户ID
 @param screenSharing 是否是共享屏幕

 */
- (void)didMedia:(NSString *_Nullable)media lostPackage:(int)lostPackage uplink:(BOOL)uplink ofUser:(NSString *_Nonnull)userId screenSharing:(BOOL)screenSharing;

/**
 发起屏幕共享失败
 */
- (void)onScreenSharingFailure;
@end

#pragma mark - 通话引擎

/**
 通话引擎
 */
@interface WFAVEngineKit : NSObject

/**
 单例

 @return 通话引擎的单例
 */
+ (instancetype)sharedEngineKit;

/*
 设置不注册voip推送服务，注意必须在第一次调用sharedEngineKit之前调用，否则不生效。
 */
+ (void)notRegisterVoipPushService;

/*
 是否支持多人通话
 */
@property(nonatomic, assign, readonly)BOOL supportMultiCall;

/*
 最大音频通话路数，单人音视频默认为2，无法修改。
 */
@property(nonatomic, assign)int maxAudioCallCount;

/*
最大视频通话路数，单人音视频默认为2，无法修改。
*/
@property(nonatomic, assign)int maxVideoCallCount;

/*
是否更新邀请消息的时间。当为YES时，StartCall消息会被更新为结束时间。
*/
@property(nonatomic, assign)BOOL updateCallStartMessageTimestamp;

/*
 是否使用距离传感器，默认为YES
 */
@property(nonatomic, assign)BOOL enableProximitySensor;

/**
 添加ICE服务地址和鉴权

 @param address 服务地址
 @param userName 用户名
 @param password 密码
 */
- (void)addIceServer:(NSString *)address
            userName:(NSString *)userName
            password:(NSString *)password;

/**
 是否启用统计功能
 */
@property(nonatomic, assign) BOOL shouldGetStats;

/**
 全局的通话事件监听
 */
@property(nonatomic, weak) id<WFAVEngineDelegate> delegate;

/**
 当前的通话Session
 */
@property(nonatomic, strong, readonly) WFAVCallSession *currentSession;

/**
 发起通话

 @param targetIds 接收用户ID，本sdk只支持一个用户
 @param conversation 通话所在会话
 @param callExtra 通话附加信息
 @param sessionDelegate 通话Session的监听
 @return 通话Session
 */
- (WFAVCallSession *)startCall:(NSArray<NSString *> *)targetIds
                     audioOnly:(BOOL)audioOnly
                     callExtra:(NSString *_Nullable)callExtra
                  conversation:(WFCCConversation *)conversation
               sessionDelegate:(id<WFAVCallSessionDelegate>)sessionDelegate;


/* 是否支持音视频会议 */
@property(nonatomic, assign, readonly)BOOL supportConference;

/* 此函数没有意义，仅为了兼容UI代码 */
- (void)listConference:(void(^_Nullable)(NSArray<NSDictionary *> * _Nullable conferences))successBlock
                 error:(void(^_Nullable)(int error_code))errorBlock;

/* 此属性没有意义，仅为了兼容UI代码 */
@property(nonatomic, assign) BOOL disableDualStreamMode;

/* 此属性没有意义，仅为了兼容UI代码 */
@property(nonatomic, assign)BOOL screenSharingReplaceMode;


/* 此函数没有意义，仅为了兼容UI代码 */
- (WFAVCallSession *_Nonnull)startConference:(NSString *_Nullable)callId
                                   audioOnly:(BOOL)audioOnly
                                         pin:(NSString *_Nonnull)pin
                                        host:(NSString *_Nullable)host
                                       title:(NSString *_Nullable)title
                                        desc:(NSString *_Nullable)desc
                                   callExtra:(NSString *_Nullable)callExtra
                                    audience:(BOOL)audience
                                    advanced:(BOOL)advanced
                                      record:(BOOL)record
                             sessionDelegate:(id<WFAVCallSessionDelegate>_Nonnull)sessionDelegate;

/* 此函数没有意义，仅为了兼容UI代码 */
- (WFAVCallSession *_Nonnull)joinConference:(NSString *_Nonnull)callId
                                  audioOnly:(BOOL)audioOnly
                                        pin:(NSString *_Nonnull)pin
                                       host:(NSString *_Nullable)host
                                      title:(NSString *_Nullable)title
                                       desc:(NSString *_Nullable)desc
                                  callExtra:(NSString *_Nullable)callExtra
                                   audience:(BOOL)audience
                                   advanced:(BOOL)advanced
                                  muteAudio:(BOOL)muteAudio
                                  muteVideo:(BOOL)muteVideo
                             sessionDelegate:(id<WFAVCallSessionDelegate>_Nonnull)sessionDelegate;

/**
 开启画面预览
 */
- (void)startPreview;

/**
 设置视频参数

 @param videoProfile 视频属性
 @param swapWidthHeight 是否旋转
 */
- (void)setVideoProfile:(WFAVVideoProfile)videoProfile swapWidthHeight:(BOOL)swapWidthHeight;


/*!
 模态弹出ViewController，是个工具方法。这里用来弹出通话界面，也可以弹出别的界面，但注意要配对这里的dismiss来关闭界面。弹出通话界面你也可以自己来处理，不一定必须使用此工具方法。
 */
- (void)presentViewController:(UIViewController *)viewController;

/*!
 取消通话界面
 */
- (void)dismissViewController:(UIViewController *)viewController;
@end

@interface WFAVParticipantProfile : NSObject
@property(nonatomic, strong, readonly)NSString *userId;
@property(nonatomic, assign, readonly)long long startTime;
@property(nonatomic, assign, readonly)WFAVEngineState state;
@property(nonatomic, assign, readonly)BOOL videoMuted;
@property(nonatomic, assign, readonly)BOOL audioMuted;
@property(nonatomic, assign, readonly)BOOL audience;
@property(nonatomic, assign, readonly)BOOL screeSharing;
@end

#pragma mark - 通话Session
/**
 通话的Session实体
 */
@interface WFAVCallSession : NSObject

/**
 通话的唯一值
 */
@property(nonatomic, strong, readonly) NSString *callId;

/**
 对方的用户ID
 */
@property(nonatomic, strong, readonly) NSString *clientId;

/**
邀请者用户ID，与initiator的区别是：initiator是当前通话的管理者，全局只有同一个用户，如果initiator退出，会选举出新的initiator；
 inviter为邀请当前用户的邀请者，一直保持不变。
*/
@property(nonatomic, strong, readonly) NSString * _Nullable inviter;

/**
 通话Session的事件监听
 */
@property(nonatomic, weak)id<WFAVCallSessionDelegate> delegate;

/**
 通话状态
 */
@property(nonatomic, assign, readonly) WFAVEngineState state;

/**
 通话的开始时间，unix时间戳，单位为ms
 */
@property(nonatomic, assign, readonly) long long startTime;

/**
 通话的持续时间，unix时间戳，单位为ms
 */
@property(nonatomic, assign, readonly) long long connectedTime;

/**
 通话的结束时间，unix时间戳，单位为ms
 */
@property(nonatomic, assign, readonly) long long endTime;

/**
 通话所在的会话
 */
@property(nonatomic, strong, readonly) WFCCConversation *conversation;

/**
 是否是语音电话
 */
@property(nonatomic, assign, getter=isAudioOnly) BOOL audioOnly;

/**
 通话结束原因
 */
@property(nonatomic, assign, readonly)WFAVCallEndReason endReason;

/**
 是否是扬声器
 */
@property(nonatomic, assign, getter=isSpeaker, readonly)BOOL speaker;

/**
是否是会议
*/
@property(nonatomic, assign, getter=isConference, readonly) BOOL conference;

/**
是否观众，仅当会议有效
*/
@property(nonatomic, assign, getter=isAudience, readonly) BOOL audience;

/**
会议新加入成名缺省状态，是否观众，仅当会议有效
*/
@property(nonatomic, assign) BOOL defaultAudience;

/**
是否高级会议模式，仅当会议有效
*/
@property(nonatomic, assign, getter=isAdvanced, readonly) BOOL advanced;

/**
会议密码，仅当会议有效
*/
@property(nonatomic, strong) NSString * _Nullable pin;

/**
会议主持人，仅当会议有效
*/
@property(nonatomic, strong) NSString * _Nullable host;

/**
会议标题，仅当会议有效
*/
@property(nonatomic, strong) NSString * _Nullable title;

/**
会议描述，仅当会议有效
*/
@property(nonatomic, strong) NSString * _Nullable desc;

/**
 应用内屏幕分享。仅音视频高级版支持
 */
@property(nonatomic, assign, getter=isInAppScreenSharing)BOOL inAppScreenSharing;

/**
呼叫附加信息
*/
@property(nonatomic, strong) NSString * _Nullable callExtra;

/**
通话成员（不包含自己）
*/
@property(nonatomic, assign, readonly)NSArray<NSString *> *participantIds;
@property(nonatomic, assign, readonly)NSString *initiator;

- (BOOL)isParticipant:(NSString *)userId;

/**
通话成员（不包含自己）
*/
@property(nonatomic, assign, readonly) NSArray<WFAVParticipantProfile *> *participants;
@property(nonatomic, assign, readonly) WFAVParticipantProfile *myProfile;
//***兼容高级版音视频***
- (WFAVParticipantProfile *_Nullable)profileOfUser:(NSString *_Nonnull)userId isScreenSharing:(BOOL)isScreenSharing;

- (void)inviteNewParticipants:(NSArray<NSString *>*)targetIds;
/**
是否是关掉视频
*/
@property(nonatomic, assign, getter=isVideoMuted, readonly) BOOL videoMuted;

/**
是否是关掉音频
*/
@property(nonatomic, assign, getter=isAudioMuted, readonly) BOOL audioMuted;

/**
 接听通话
 */
- (void)answerCall:(BOOL)audioOnly callExtra:(NSString *)callExtra;

/**
 挂断通话
 */
- (void)endCall;

/**
 开启或关闭声音

 @param muted 是否关闭
 @return 操作是否成功
 */
- (BOOL)muteAudio:(BOOL)muted;

/**
 开启或关闭扬声器
 
 @param speaker 是否使用扬声器
 @return 操作是否成功
 */
- (BOOL)enableSpeaker:(BOOL)speaker;

/**
 开启或关闭摄像头

 @param muted 是否关闭
 @return 操作是否成功
 */
- (BOOL)muteVideo:(BOOL)muted;

/**
 切换前后摄像头
 */
- (void)switchCamera;

/**
 是否是蓝牙设备连接

 @return 是否是蓝牙设备连接
 */
- (BOOL)isBluetoothSpeaker;

/**
 是否是耳机连接

 @return 是否是耳机连接
 */
- (BOOL)isHeadsetPluggedIn;

/**
 设置本地视频视图Container
 
 @param videoContainerView 本地视频视图Container
 @param scalingType 缩放模式
 */
- (void)setupLocalVideoView:(UIView *)videoContainerView scalingType:(WFAVVideoScalingType)scalingType;

/**
 设置对端视频视图Container
 
 @param videoContainerView 本地视频视图Container
 @param scalingType 缩放模式
 */
- (void)setupRemoteVideoView:(UIView * _Nullable)videoContainerView scalingType:(WFAVVideoScalingType)scalingType forUser:(NSString * _Nonnull)userId screenSharing:(BOOL)screenSharing;


/* 此函数没有意义，仅为了兼容UI代码 */
- (void)leaveConference:(BOOL)destroy;

/* 此函数没有意义，仅为了兼容UI代码 */
- (void)switchAudience:(BOOL)audience;

/* 此函数没有意义，仅为了兼容UI代码 */
- (void)kickoffParticipant:(NSString *_Nonnull)participant
                   success:(void(^_Nullable)(void))successBlock
                     error:(void(^_Nullable)(int error_code))errorBlock;
@end

