//
//  GeTuiSdk.h
//  GeTuiSdk
//
//  Created by gexin on 15-5-5.
//  Copyright (c) 2015年 Gexin Interactive (Beijing) Network Technology Co.,LTD. All rights reserved.
//
//  GTSDK-Version: 3.0.9.0

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSUInteger, SdkStatus) {
    SdkStatusStarting, // 正在启动
    SdkStatusStarted,  // 启动、在线
    SdkStatusStoped,   // 停止
    SdkStatusOffline,  // 离线
};

#define kGtResponseBindType @"bindAlias"
#define kGtResponseUnBindType @"unbindAlias"

//SDK Delegate 回调接口
@protocol GeTuiSdkDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface GeTuiSdk : NSObject

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
#error "GeTuiSDK is requested iOS8 or iOS8 above version"
#endif


//MARK: -

/**
 *  启动个推SDK
 *
 *  @param appid     设置app的个推appId，此appId从个推网站获取
 *  @param appKey    设置app的个推appKey，此appKey从个推网站获取
 *  @param appSecret 设置app的个推appSecret，此appSecret从个推网站获取
 *  @param delegate  回调代理delegate
 *  @param launchOptions 传入didFinishLaunchingWithOptions中的launchOptions参数
 */
+ (void)startSdkWithAppId:(NSString *)appid appKey:(NSString *)appKey appSecret:(NSString *)appSecret delegate:(id<GeTuiSdkDelegate>)delegate launchingOptions:(NSDictionary * __nullable)launchOptions;


/**
 *  设置 App Groups Id (如有使用 iOS Extension SDK，请设置该值)
 */
+ (void)setApplicationGroupIdentifier:(NSString*)identifier;

/// 注册远程通知
/// 必须使用个推注册通知，否则可能无法获取APNs回调！！
/// 注意！！！使用个推注册通知， 开发者无需关注DeviceToken相关逻辑，且仅需要关注个推APNs消息通知回调
/// 若不使用此方法，开发者需要自行处理DeviceToken相关逻辑 和 重写系统APNs回调, 可参考Demo版本2.4.6.0 [https://www.getui.com/download/docs/getui/iOS/GETUI_IOS_SDK_2.4.6.0.zip]
/// @param types UNAuthorizationOptions类型的通知选项
+ (void)registerRemoteNotification:(UNAuthorizationOptions)types;

/**
 *  获取SDK版本号
 *
 *  当前GeTuiSdk版本, 当前文件头部(顶部)可见
 *  @return 版本值
 */
+ (NSString *)version;

/**
 *  获取SDK的Cid
 *
 *  @return Cid值
 */
+ (NSString *)clientId;

/**
 *  获取SDK运行状态
 *
 *  @return 运行状态
 */
+ (SdkStatus)status;

/**
 *  设置渠道
 *  备注：SDK可以未启动就调用该方法
 *
 *  SDK-1.5.0+
 *
 *  @param aChannelId 渠道值，可以为空值
 */
+ (void)setChannelId:(NSString *)aChannelId;

/**
 *  设置IDFA
 *
 *  SDK-2.5.6.0+
 *
 *  @param idfa idfa
 */
+ (void)setIDFA:(NSString *)idfa;

/**
 *  设置关闭推送模式（默认值：NO）
 *  需要SDK在线才能调用
 *
 *  @param isValue 消息推送开发，YES.关闭消息推送 NO.开启消息推送
 *
 *  SDK-1.2.1+
 *
 */
+ (void)setPushModeForOff:(BOOL)isValue;

/**
 *  是否允许SDK 后台运行（默认值：NO）
 *  备注：可以未启动SDK就调用该方法
 *  @param isEnable 支持当APP进入后台后，个推是否运行,YES.允许
 *
 *  注意：开启后台运行时，需同时开启Signing & Capabilities > Background Modes > Auido, Airplay and Picture in Picture 才能保持长期后台在线，该功能会和音乐播放冲突，使用时请注意。
 *  本方法有缓存，如果要关闭后台运行，需要调用[GeTuiSdk runBackgroundEnable:NO]
 */
+ (void)runBackgroundEnable:(BOOL)isEnable;

/**
 *  地理围栏功能，设置地理围栏是否运行
 *  备注：SDK可以未启动就调用该方法
 *
 *  @param isEnable 设置地理围栏功能是否运行（默认值：NO）
 *  @param isVerify 设置是否SDK主动弹出用户定位请求（默认值：NO）
 */
+ (void)lbsLocationEnable:(BOOL)isEnable andUserVerify:(BOOL)isVerify;

/**
 *  清空下拉通知栏全部通知,并将角标置“0”，不显示角标
 */
+ (void)clearAllNotificationForNotificationBar;

/**
 *  销毁SDK，并且释放资源
 */
+ (void)destroy;

//MARK: - 注册Token

/**
 *  向个推服务器注册VoipToken
 *  备注：可以未启动SDK就调用该方法
 *
 *  @param voipToken 推送时使用的voipToken NSString
 *  @return voipToken有效判断，YES.有效 NO.无效
 *
 */
+ (BOOL)registerVoipToken:(NSString *)voipToken;

/**
 *  向个推服务器注册VoipToken
 *  备注：可以未启动SDK就调用该方法
 *  注：Xcode11、iOS13 DeviceToken适配，至少使用“SDK-2.4.1.0”版本
 *
 *  @param voipToken 推送时使用的voipToken NSData
 *  @return voipToken有效判断，YES.有效 NO.无效
 *
 */

+ (BOOL)registerVoipTokenCredentials:(NSData *)voipToken;


//MARK: - 注册实时活动Token

/**
 * 注册实时活动PushToStartToken（灵动岛）
 *
 * @param activityAttributes  实时活动的属性
 * @param pushToStartToken 推送时使用的pushToStartToken
 * @param sn 请求序列码, 不为nil
 * @return pushToStartToken有效判断 或 重复请求
 */
+ (BOOL)registerLiveActivity:(NSString *)activityAttributes pushToStartToken:(NSString*)pushToStartToken sequenceNum:(NSString*)sn;

/**
 * 注册实时活动token（灵动岛）
 *
 * @param liveActivityId  业务id，用于绑定token的业务关系
 * @param token liveActivity推送时使用的pushToken
 * @param sn 请求序列码, 不为nil
 * @return activityToken有效判断 或 重复请求
 */
+ (BOOL)registerLiveActivity:(NSString *)liveActivityId activityToken:(NSString*)token sequenceNum:(NSString*)sn;

//MARK: - 控制中心

/// 注册控制中心小组件推送Token
/// - Parameters:
///   - tokens: token字典，key为kind，value为token
///   - sn:序列化
/// - Returns: tokens入参校验是否正确
+ (BOOL)registerControlsTokens:(NSDictionary *)tokens sequenceNum:(NSString*)sn;


//MARK: - 设置标签

/**
 *  给用户打标签, 后台可以根据标签进行推送
 *
 *  @param tags 别名数组
 *  tag: 只能包含中文字符、英文字母、0-9、+-*_.的组合（不支持空格）
 *
 *  @return 提交结果，YES表示尝试提交成功，NO表示尝试提交失败
 */
+ (BOOL)setTags:(NSArray *)tags;

/**
 *  给用户打标签, 后台可以根据标签进行推送
 *
 *  @param tags 别名数组
 *  tag: 只能包含中文字符、英文字母、0-9、+-*_.的组合（不支持空格）
 *  @param sn  绑定序列码, 不为nil
 *  @return 提交结果，YES表示尝试提交成功，NO表示尝试提交失败
 */
+ (BOOL)setTags:(NSArray *)tags andSequenceNum:(NSString *)sn;

//MARK: - 设置角标

/**
 *  同步角标值到个推服务器
 *  该方法只是同步角标值到个推服务器，本地仍须调用setApplicationIconBadgeNumber函数
 *
 *  SDK-1.4.0+
 *
 *  @param badge 角标数值
 */
+ (void)setBadge:(NSUInteger)badge;

/**
 *  复位角标，等同于"setBadge:0"
 *
 *  SDK-1.4.0+
 *
 */
+ (void)resetBadge;

//MARK: - 设置别名

/**
 *  绑定别名功能:后台可以根据别名进行推送
 *  需要SDK在线才能调用
 *
 *  @param alias 别名字符串
 *  @param sn   绑定序列码, 不为nil
 */
+ (void)bindAlias:(NSString *)alias andSequenceNum:(NSString *)sn;

/**
 *  取消绑定别名功能
 *  需要SDK在线才能调用
 *
 *  @param alias   别名字符串
 *  @param sn     绑定序列码, 不为nil
 *  @param isSelf  是否只对当前cid有效，如果是true，只对当前cid做解绑；如果是false，对所有绑定该别名的cid列表做解绑
 */
+ (void)unbindAlias:(NSString *)alias andSequenceNum:(NSString *)sn andIsSelf:(BOOL)isSelf;


//MARK: - 处理回执

/**
 *  远程推送消息处理（手动上报回执）
 *
 *  @param userInfo 远程推送消息
 *
 *  - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
 *
 */
+ (void)handleRemoteNotification:(NSDictionary *)userInfo;


/**
 *  VOIP消息回执
 *
 *  @param payload VOIP 推送内容
 */
+ (void)handleVoipNotification:(NSDictionary *)payload;

/**
 *  APPLink 回执
 *  @param webUrl applink Url
 *  @return applink 中用户的 payload 信息
 */
+ (NSString *)handleApplinkFeedback:(NSURL *)webUrl;

/**
 *  SDK发送上行消息结果
 *
 *  @param body  需要发送的消息数据
 *
 *  @return 消息的msgId
 */
+ (NSString *)sendMessage:(NSData *)body;

/**
 *  SDK发送上行消息结果
 *
 *  @param body  需要发送的消息数据
 *  @param taskId  任务ID, UUID String
 *  @param error 错误信息
 *
 *  @return 如果发送成功返回messageid，发送失败返回nil
*/
+ (NSString *)sendMessage:(NSData *)body taskId:(NSString *)taskId error:(NSError **)error;

/**
 *  上行第三方自定义回执actionid
 *
 *  @param actionId 用户自定义的actionid，int类型，取值90001-90999。
 *  @param taskId   下发任务的任务ID
 *  @param msgId    下发任务的消息ID
 *
 *  @return BOOL，YES表示尝试提交成功，NO表示尝试提交失败。注：该结果不代表服务器收到该条数据
 *  该方法需要在回调方法“GeTuiSdkDidReceivePayload:andTaskId:andMessageId:andOffLine:fromApplication:”使用
 */
+ (BOOL)sendFeedbackMessage:(NSInteger)actionId andTaskId:(NSString *)taskId andMsgId:(NSString *)msgId;


//MARK: - 已废弃

/**
 *  恢复SDK运行,IOS7 以后支持Background Fetch方式，后台定期更新数据,该接口需要在Fetch起来后被调用，保证SDK 数据获取。
 */
+ (void)resume DEPRECATED_MSG_ATTRIBUTE("已废弃");

/**
 *  向个推服务器注册DeviceToken
 *  备注：可以未启动SDK就调用该方法
 *
 *  @param deviceToken 推送时使用的deviceToken NSString
 *  @return deviceToken有效判断，YES.有效 NO.无效
 *
 */
+ (BOOL)registerDeviceToken:(NSString *)deviceToken DEPRECATED_MSG_ATTRIBUTE("已废弃");

/**
 *  向个推服务器注册DeviceToken
 *  备注：可以未启动SDK就调用该方法
 *  注：Xcode11、iOS13 DeviceToken适配，至少使用“SDK-2.4.1.0”版本
 *
 *  @param deviceToken 推送时使用的deviceToken NSData
 *  @return deviceToken有效判断，YES.有效 NO.无效
 *
 */
+ (BOOL)registerDeviceTokenData:(NSData *)deviceToken DEPRECATED_MSG_ATTRIBUTE("已废弃");

//MARK: - 已废弃

/**
 *  SDK发送上行消息结果
 *
 *  @param body  需要发送的消息数据
 *  @param error 如果发送成功返回messageid，发送失败返回nil
 *
 *  @return 消息的msgId
 */
+ (NSString *)sendMessage:(NSData *)body error:(NSError **)error DEPRECATED_MSG_ATTRIBUTE("Please use -[GeTuiSdk sendMessage:taskId:error:]");

@end


//MARK: - SDK Delegate

@protocol GeTuiSdkDelegate <NSObject>

@optional

/**
 *  SDK登入成功返回clientId
 *
 *  @param clientId 标识用户的clientId
 *  说明:启动GeTuiSdk后，SDK会自动向个推服务器注册SDK，当成功注册时，SDK通知应用注册成功。
 *  注意: 注册成功仅表示推送通道建立，如果appid/appkey/appSecret等验证不通过，依然无法接收到推送消息，请确保验证信息正确。
 */
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId;

/**
 *  SDK运行状态通知
 *
 *  @param status 返回SDK运行状态
 */
- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)status;

/**
 *  SDK遇到错误消息返回error
 *
 *  @param error SDK内部发生错误，通知第三方，返回错误
 */
- (void)GeTuiSdkDidOccurError:(NSError *)error;


//MARK: - 通知回调

/// 通知授权结果（iOS10及以上版本）
/// @param granted 用户是否允许通知
/// @param error 错误信息
- (void)GetuiSdkGrantAuthorization:(BOOL)granted error:(nullable NSError*)error;

/// 通知展示（iOS10及以上版本）
/// @param center center
/// @param notification notification
/// @param completionHandler completionHandler
- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center
           willPresentNotification:(UNNotification * )notification
             completionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
              __API_AVAILABLE(macos(10.14), ios(10.0), watchos(3.0), tvos(10.0));

 
/// 收到通知信息
/// @param userInfo apns通知内容
/// @param center UNUserNotificationCenter（iOS10及以上版本）
/// @param response UNNotificationResponse（iOS10及以上版本）
/// @param completionHandler 用来在后台状态下进行操作（iOS10以下版本）
- (void)GeTuiSdkDidReceiveNotification:(NSDictionary *)userInfo
                    notificationCenter:(nullable UNUserNotificationCenter *)center
                              response:(nullable UNNotificationResponse *)response
                fetchCompletionHandler:(nullable void (^)(UIBackgroundFetchResult))completionHandler;


/// 收到透传消息
/// @param userInfo    推送消息内容,  {"payload": 消息内容}
/// @param fromGetui   YES: 个推通道  NO：苹果apns通道
/// @param offLine     是否是离线消息，YES.是离线消息
/// @param appId       应用的appId
/// @param taskId      推送消息的任务id
/// @param msgId       推送消息的messageid
/// @param completionHandler 用来在后台状态下进行操作（通过苹果apns通道的消息 才有此参数值）
- (void)GeTuiSdkDidReceiveSlience:(NSDictionary *)userInfo
                        fromGetui:(BOOL)fromGetui
                          offLine:(BOOL)offLine
                            appId:(nullable NSString *)appId
                           taskId:(nullable NSString *)taskId
                            msgId:(nullable NSString *)msgId
           fetchCompletionHandler:(nullable void (^)(UIBackgroundFetchResult))completionHandler;


- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center
       openSettingsForNotification:(nullable UNNotification *)notification
        __API_AVAILABLE(macos(10.14), ios(12.0)) __API_UNAVAILABLE(watchos, tvos);


//MARK: - 发送上行消息
/**
 *  SDK通知发送上行消息结果，收到sendMessage消息回调
 *
 *  @param messageId “sendMessage:error:”返回的id
 *  @param isSuccess    成功返回 YES, 失败返回 NO
 *  @param error       成功返回nil, 错误返回相应error信息
 *  说明: 当调用sendMessage:error:接口时，消息推送到个推服务器，服务器通过该接口通知sdk到达结果，isSuccess为 YES 说明消息发送成功
 *  注意: 需第三方服务器接入个推,SendMessage 到达第三方服务器后返回 1
 */
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(BOOL)isSuccess error:(nullable NSError *)error;


//MARK: - 开关设置

/**
 *  SDK设置关闭推送模式回调
 *
 *  @param isModeOff 关闭模式，YES.服务器关闭推送功能 NO.服务器开启推送功能
 *  @param error     错误回调，返回设置时的错误信息
 */
- (void)GeTuiSdkDidSetPushMode:(BOOL)isModeOff error:(nullable NSError *)error;


//MARK: - 别名设置
/**
 *  SDK绑定、解绑回调
 *
 *  @param action       回调动作类型 kGtResponseBindType 或 kGtResponseUnBindType
 *  @param isSuccess    成功返回 YES, 失败返回 NO
 *  @param sn          返回请求的序列码
 *  @param error       成功返回nil, 错误返回相应error信息
 */
- (void)GeTuiSdkDidAliasAction:(NSString *)action result:(BOOL)isSuccess sequenceNum:(NSString *)sn error:(nullable NSError *)error;


//MARK: - 标签设置
/**
 *  设置标签回调
 *
 *  @param sequenceNum  请求序列码
 *  @param isSuccess    成功返回 YES, 失败返回 NO
 *  @param error       成功返回 nil, 错误返回相应error信息
 */
- (void)GeTuiSdkDidSetTagsAction:(NSString *)sequenceNum result:(BOOL)isSuccess error:(nullable NSError *)error;

/**
 * 查询当前绑定tag结果返回
 * @param tags   当前绑定的 tag 信息
 * @param sn     返回 queryTag 接口中携带的请求序列码，标识请求对应的结果返回
 * @param error  成功返回nil,错误返回相应error信息
 */
- (void)GetuiSdkDidQueryTag:(NSArray *)tags sequenceNum:(NSString *)sn error:(nullable NSError *)error;


//MARK: - 实时活动

/// 设置实时活动PushToStartToken回调（灵动岛）
/// - Parameters:
///   - sequenceNum: 请求序列码
///   - isSuccess: 成功返回 YES, 失败返回 NO
///   - error: 成功返回nil,错误返回相应error信息
- (void)GeTuiSdkDidRegisterPushToStartToken:(NSString *)sequenceNum result:(BOOL)isSuccess error:(nullable NSError *)error;

/// 设置实时活动Token回调（灵动岛）
/// - Parameters:
///   - sequenceNum: 请求序列码
///   - isSuccess: 成功返回 YES, 失败返回 NO
///   - error: 成功返回nil,错误返回相应error信息
- (void)GeTuiSdkDidRegisterLiveActivity:(NSString *)sequenceNum result:(BOOL)isSuccess error:(nullable NSError *)error;

//MARK: - 控制中心

/// 控制中心注册token回调
/// - Parameters:
///   - sequenceNum: 请求序列码
///   - isSuccess: 成功返回 YES, 失败返回 NO
///   - error: 成功返回nil,错误返回相应error信息
- (void)GeTuiSdkDidRegisterControlsTokens:(NSString *)sequenceNum result:(BOOL)isSuccess error:(nullable NSError *)error;

//MARK: - 应用内弹窗

// 展示回调
- (void)GeTuiSdkPopupDidShow:(NSDictionary *)info;

// 点击回调
- (void)GeTuiSdkPopupDidClick:(NSDictionary *)info;


//MARK: - 已废弃

/**
 *  SDK通知收到个推推送的透传消息
 *
 *  @param payloadData 推送消息内容
 *  @param taskId      推送消息的任务id
 *  @param msgId       推送消息的messageid
 *  @param offLine     是否是离线消息，YES.是离线消息
 *  @param appId       应用的appId
 */
- (void)GeTuiSdkDidReceivePayloadData:(NSData *)payloadData
                            andTaskId:(NSString *)taskId
                             andMsgId:(NSString *)msgId
                           andOffLine:(BOOL)offLine
                          fromGtAppId:(NSString *)appId DEPRECATED_MSG_ATTRIBUTE("使用GeTuiSdkDidReceiveSlience:fromGetui:offLine:appId:taskId:msgId:fetchCompletionHandler:");

/**
 *  SDK通知发送上行消息结果，收到sendMessage消息回调 (已废弃)
 *
 *  @param messageId “sendMessage:error:”返回的id
 *  @param result    成功返回1, 失败返回0
 *  说明: 当调用sendMessage:error:接口时，消息推送到个推服务器，服务器通过该接口通知sdk到达结果，result为 1 说明消息发送成功
 *  注意: 需第三方服务器接入个推,SendMessage 到达第三方服务器后返回 1
 */;
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(int)result DEPRECATED_MSG_ATTRIBUTE("Please use -[delegate GeTuiSdkDidSendMessage:msg result: error:]");

@end

NS_ASSUME_NONNULL_END
