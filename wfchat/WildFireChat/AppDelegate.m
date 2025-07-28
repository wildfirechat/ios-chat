//
//  AppDelegate.m
//  WildFireChat
//
//  Created by WF Chat on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


//如果您不需要voip功能，请在ChatUIKit工程中关掉voip功能，然后修改WFChat-Prefix-Header.h中WFCU_SUPPORT_VOIP为0
//ChatUIKit关闭voip的方式是，找到ChatUIKit工程下的Predefine.h头文件，定义WFCU_SUPPORT_VOIP为0，
//再删除掉ChatUIKit工程的WebRTC和WFAVEngineKit的依赖。
//删除掉应用工程中的WebRTC.framework和WFAVEngineKit.framework这两个库。

#import "AppDelegate.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#import <WebRTC/WebRTC.h>
#endif
#import "WFCLoginViewController.h"
#import "WFCConfig.h"
#import "WFCBaseTabBarController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "PCLoginConfirmViewController.h"
#import "AppService.h"
#import "UIColor+YH.h"
#import "SharedConversation.h"
#import "SharePredefine.h"
#import "TestRedirector.h"
#ifdef WFC_PTT
#import <PttClient/WFPttClient.h>
#endif

#import "TYHWaterMark.h"

#import "OrgService.h"

#if USE_CALL_KIT
#import "WFCCallKitManager.h"
#endif
#import "MBProgressHUD.h"

#import "SSKeychain.h"

#if USE_GETUI_PUSH
#import <GTSDK/GeTuiSdk.h>
#import "Utils.h"
#endif

#if USE_GETUI_PUSH
// GTSDK 配置信息
#define kGtAppId @"RaamqzvnTmA2xfBBi0Ruy9"
#define kGtAppKey @"W99yuzV8eE6ndQg6VzLPU6"
#define kGtAppSecret @"os7RDFU8uU6UwdTUBSeB58"

#define GTSdkStateNotification @"GtSdkStateChange"
#endif

@interface AppDelegate () <ConnectionStatusDelegate, ConnectToServerDelegate, ReceiveMessageDelegate,
#if WFCU_SUPPORT_VOIP
    WFAVEngineDelegate,
#endif
    UNUserNotificationCenterDelegate, QrCodeDelegate
#ifdef WFC_PTT
,WFPttDelegate
#endif
#if USE_GETUI_PUSH
,PKPushRegistryDelegate
#endif
>
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@property(nonatomic, strong) UILocalNotification *localCallNotification;
#if USE_CALL_KIT
@property(nonatomic, strong) WFCCallKitManager *callKitManager;
#endif

@property(nonatomic, assign) BOOL firstConnected;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    if([IM_SERVER_HOST rangeOfString:@"http"].location != NSNotFound || [IM_SERVER_HOST rangeOfString:@":"].location != NSNotFound) {
        NSLog(@"IM_SERVER_HOST只能填写IP或者域名，不能带HTTP头或者端口！！！");
        exit(-1);
    }
#endif
    
#if WFCU_SUPPORT_VOIP
#if !USE_CALL_KIT
    [WFAVEngineKit notRegisterVoipPushService];
#endif
#endif
    [WFCCNetworkService sharedInstance].sendLogCommand = Send_Log_Command;
    [WFCCNetworkService startLog];
//    [[WFCCNetworkService sharedInstance] useSM4];
    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].connectToServerDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
    [[WFCCNetworkService sharedInstance] setBackupAddressStrategy:0];
    [WFCCNetworkService sharedInstance].defaultPortraitProvider = [AppService sharedAppService];
    [WFCCNetworkService sharedInstance].urlRedirector = [[TestRedirector alloc] init];
//    [[WFCCNetworkService sharedInstance] setProxyInfo:nil ip:@"192.168.1.80" port:1080 username:nil password:nil];
//    [[WFCCNetworkService sharedInstance] setBackupAddress:@"192.168.1.120" port:80];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    //当PC/Web在线时手机端是否静音，默认静音。如果修改为默认不静音，需要打开下面函数。
    //另外需要IM服务配置server.mobile_default_silent_when_pc_online为false。必须保持与服务器同步。
    //[[WFCCIMService sharedWFCIMService] setDefaultSilentWhenPcOnline:NO];

#if WFCU_SUPPORT_VOIP
#if USE_GETUI_PUSH
    //当使用个推时，音视频SDK不再自己注册voip推送。这个方法必须在调用所有音视频SDK的方法之前才行。
    [WFAVEngineKit notRegisterVoipPushService];
#endif
    //多人音视频通话时，是否在会话中现在正在通话让其他人主动加入。
    [WFCUConfigManager globalManager].enableMultiCallAutoJoin = YES;
    
    //多人音视频通话时，是否在显示谁在说话
    [WFCUConfigManager globalManager].displaySpeakingInMultiCall = YES;
    
    //音视频高级版不需要stun/turn服务，请注释掉下面这行。单人版和多人版需要turn服务，请自己部署然后修改配置文件。
    [[WFAVEngineKit sharedEngineKit] addIceServer:ICE_ADDRESS userName:ICE_USERNAME password:ICE_PASSWORD];
    
    [[WFAVEngineKit sharedEngineKit] setVideoProfile:kWFAVVideoProfile360P swapWidthHeight:YES];
    [WFAVEngineKit sharedEngineKit].delegate = self;
    
    // 设置音视频参与者数量。多人音视频默认视频4路，音频9路，如果改成更多可能会导致问题；音视频高级版默认视频9路，音频16路。
//    [WFAVEngineKit sharedEngineKit].maxVideoCallCount = 4;
//    [WFAVEngineKit sharedEngineKit].maxAudioCallCount = 9;
    
    //音视频日志，当需要抓日志分析时可以打开这句话
    //RTCSetMinDebugLogLevel(RTCLoggingSeverityInfo);
#endif
    
    
    [WFCUConfigManager globalManager].appServiceProvider = [AppService sharedAppService];
    [WFCUConfigManager globalManager].fileTransferId = FILE_TRANSFER_ID;
    [WFCUConfigManager globalManager].orgServiceProvider = [OrgService sharedOrgService];
    
    [WFCUConfigManager globalManager].asrServiceUrl = ASR_SERVICE_URL;
    
    //可以在WFCUMessageListViewController界面代码中绑定消息和Cell的对应关系（注册Cell），也可以在这里注册。
    //Cell分为2种类型，一种类型是带有头像的，另外一种是没有头像的。写Cell时可以参考下面这2个Cell。
    //[[WFCUConfigManager globalManager] registerCustomCell:[WFCUTextCell class] forContent:[WFCCTextMessageContent class]];
    //[[WFCUConfigManager globalManager] registerCustomCell::[WFCUInformationCell class] forContent:[WFCCTipNotificationContent class]];
#ifdef WFC_PTT
    //初始化对讲SDK
    [WFPttClient sharedClient].delegate = self;
    BOOL keepBackgroundAlive = [[NSUserDefaults standardUserDefaults] boolForKey:@"WFC_PTT_BACKGROUND_KEEPALIVE"];
    if(keepBackgroundAlive) {
        [[WFPttClient sharedClient] setPlaySilent:@(YES)];
    }
    BOOL pttEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"WFC_PTT_ENABLED"];
    [WFPttClient sharedClient].enablePtt = pttEnabled;
#endif //WFC_PTT
    NSString *savedToken = [SSKeychain passwordForWFService:@"savedToken"];
    NSString *savedUserId = [SSKeychain passwordForWFService:@"savedUserId"];
    if (!savedToken || !savedUserId) { //升级兼容
        savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
        savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
        if(savedToken && savedUserId) {
            [SSKeychain setPassword:savedToken forWFService:@"savedToken"];
            [SSKeychain setPassword:savedUserId forWFService:@"savedUserId"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
        }
    }
    
    
    self.window.rootViewController = [WFCBaseTabBarController new];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self setupNavBar];
    
    setQrCodeDelegate(self);
    
    
#if USE_GETUI_PUSH
    // [ GTSDK ]：使用APPID/APPKEY/APPSECRENT启动个推
    [GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret delegate:self launchingOptions:launchOptions];
    
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 注册远程通知
    [GeTuiSdk registerRemoteNotification: (UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge)];
    
#if WFCU_SUPPORT_VOIP
    PKPushRegistry *voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
#endif
#else
    if (@available(iOS 10.0, *)) {
        //第一步：获取推送通知中心
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                  if (!error) {
                                      NSLog(@"succeeded!");
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [application registerForRemoteNotifications];
                                      });
                                  }
                              }];
    } else {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings
                                                settingsForTypes:(UIUserNotificationTypeBadge |
                                                                  UIUserNotificationTypeSound |
                                                                  UIUserNotificationTypeAlert)
                                                categories:nil];
        [application registerUserNotificationSettings:settings];
    }
#endif
    
    if (savedToken.length > 0 && savedUserId.length > 0) {
        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）。
        [[WFCCNetworkService sharedInstance] connect:savedUserId token:savedToken];
        
        if(ENABLE_WATER_MARKER) {
            [self.window addSubview:[TYHWaterMarkView new]];
            [TYHWaterMarkView setCharacter:savedUserId];
            [TYHWaterMarkView autoUpdateDate:YES];
        }
    } else {
        WFCLoginViewController *loginVC = [[WFCLoginViewController alloc] init];
        
        //是否优先密码登录
        loginVC.isPwdLogin = Prefer_Password_Login;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
        self.window.rootViewController = nav;
    }
    
#if USE_CALL_KIT
    self.callKitManager = [[WFCCallKitManager alloc] init];
#endif
    
    return YES;
}


- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:
(UIUserNotificationSettings *)notificationSettings {
    // register to receive notifications
    [application registerForRemoteNotifications];
}

//会议需要支持方向旋转
-(UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if([NSStringFromClass([window.rootViewController class]) isEqualToString:@"WFCUConferenceViewController"]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
#if USE_GETUI_PUSH
    NSLog(@"Received ios device token");
#else
    if ([deviceToken isKindOfClass:[NSData class]]) {
        const unsigned *tokenBytes = [deviceToken bytes];
        NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                              ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                              ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                              ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
        [[WFCCNetworkService sharedInstance] setDeviceToken:hexToken];
    } else {
        NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"
                                                                                 withString:@""]
                            stringByReplacingOccurrencesOfString:@">"
                            withString:@""]
                           stringByReplacingOccurrencesOfString:@" "
                           withString:@""];
        
        [[WFCCNetworkService sharedInstance] setDeviceToken:token];
    }
#endif
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self updateBadgeNumber];
    
    [self prepardDataForShareExtension];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
#if WFCU_SUPPORT_VOIP
    //从后台回到前台时，如果是在来电状态，需要播放来电铃声。
    if([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming) {
        [self shouldStartRing:YES];
    }
#endif
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [WFCCNetworkService stopLog];
}

- (void)prepardDataForShareExtension {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    //1. 保存app cookies
    NSString *authToken = [[AppService sharedAppService] getAppServiceAuthToken];
    if(authToken.length) {
        [sharedDefaults setObject:authToken forKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    } else {
        NSData *cookiesdata = [[AppService sharedAppService] getAppServiceCookies];
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] setCookie:cookie];
            }
        } else {
            NSArray *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookiesForURL:[NSURL URLWithString:APP_SERVER_ADDRESS]];
            for (NSHTTPCookie *cookie in cookies) {
                [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:cookie];
            }
        }
    }
    
    //2. 保存会话列表
    NSArray<WFCCConversationInfo*> *infos = [[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
    NSMutableArray<SharedConversation *> *sharedConvs = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> *needComposedGroupIds = [[NSMutableArray alloc] init];
    //最多保存200个会话，再多就没有意义
    for (int i = 0; i < MIN(infos.count, 200); ++i) {
        WFCCConversationInfo *info = infos[i];
        SharedConversation *sc = [SharedConversation from:(int)info.conversation.type target:info.conversation.target line:info.conversation.line];
        if (info.conversation.type == Single_Type) {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:info.conversation.target refresh:NO];
            if (!userInfo) {
                continue;
            }
            sc.title = userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName;
            sc.portraitUrl = userInfo.portrait;
        } else if (info.conversation.type == Group_Type) {
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:info.conversation.target refresh:NO];
            if (!groupInfo) {
                continue;
            }
            sc.title = groupInfo.displayName;
            sc.portraitUrl = groupInfo.portrait;
            if (!groupInfo.portrait.length) {
                [needComposedGroupIds addObject:info.conversation.target];
            }
        } else if (info.conversation.type == Channel_Type) {
            WFCCChannelInfo *ci = [[WFCCIMService sharedWFCIMService] getChannelInfo:info.conversation.target refresh:NO];
            if (!ci) {
                continue;
            }
            sc.title = ci.name;
            sc.portraitUrl = ci.portrait;
        }
        [sharedConvs addObject:sc];
    }
    [sharedDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:sharedConvs] forKey:WFC_SHARE_BACKUPED_CONVERSATION_LIST];
    
    //3. 保存群拼接头像
    //获取分组的共享目录
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
    NSURL *portraitURL = [groupURL URLByAppendingPathComponent:WFC_SHARE_BACKUPED_GROUP_GRID_PORTRAIT_PATH];
    BOOL isDir = NO;
    if(![[NSFileManager defaultManager] fileExistsAtPath:portraitURL.path isDirectory:&isDir]) {
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:portraitURL.path withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Error, cannot create group portrait folder for share extension");
            return;
        }
    } else {
        if(!isDir) {
            NSLog(@"Error, cannot create group portrait folder for share extension");
            return;
        }
    }
    int syncPortraitCount = 0;
    for (NSString *groupId in needComposedGroupIds) {
        //获取已经拼接好的头像，如果没有拼接会返回为空
        NSString *file = [WFCCUtilities getGroupGridPortrait:groupId width:80 generateIfNotExist:NO defaultUserPortrait:^UIImage *(NSString *userId) {
            return nil;
        }];
        
        if (file.length) {
            NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
            
            BOOL needSync = NO;
            if([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
                NSDictionary* extensionPortraitAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
                NSDate *extensionPortraitDate = [extensionPortraitAttribs objectForKey:NSFileCreationDate];
                
                NSDictionary* containerPortraitAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:nil];
                NSDate *containerPortraitDate = [containerPortraitAttribs objectForKey:NSFileCreationDate];
                needSync = extensionPortraitDate.timeIntervalSince1970 < containerPortraitDate.timeIntervalSince1970;
            } else {
                needSync = YES;
            }
            
            if(needSync) {
                syncPortraitCount++;
                NSData *data = [NSData dataWithContentsOfFile:file];
                [data writeToURL:fileURL atomically:YES];
                //群组头像每次同步30个，太多影响性能
                if(syncPortraitCount > 30) {
                    break;
                }
            }
        }
    }
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        NSArray<NSString *> *newRequests = notification.object;
        
        if (!newRequests.count) {
            return;
        }
        
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        if (@available(iOS 8.2, *)) {
            localNote.alertTitle = @"收到好友邀请";
        }
        
        if (newRequests.count == 1) {
            [[WFCCIMService sharedWFCIMService] getUserInfo:newRequests[0] refresh:NO success:^(WFCCUserInfo *userInfo) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    WFCCFriendRequest *request = [[WFCCIMService sharedWFCIMService] getFriendRequest:newRequests[0] direction:1];
                    localNote.alertBody = [NSString stringWithFormat:@"%@:%@", userInfo.displayName, request.reason];
                    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
                });
                        } error:^(int errorCode) {
                            
                        }];
        } else if(newRequests.count > 1) {
            localNote.alertBody = [NSString stringWithFormat:@"您收到 %ld 条好友请求", newRequests.count];
            [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        }
    }
}

- (BOOL)shouldMuteNotification {
    BOOL isNoDisturbing = [[WFCCIMService sharedWFCIMService] isNoDisturbing];
    
    
    //免打扰
    if (isNoDisturbing) {
        return YES;
    }
    
    //全局静音
    if ([[WFCCIMService sharedWFCIMService] isGlobalSilent]) {
        return YES;
    }
    
    
    BOOL pcOnline = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos].count > 0;
    BOOL muteWhenPcOnline = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
    
    if(pcOnline && muteWhenPcOnline) {
        return YES;
    }
    
    return NO;
}

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        NSInteger count = [self updateBadgeNumber];
        
        if([self shouldMuteNotification]) {
            return;
        }
        
        for (WFCCMessage *msg in messages) {
            [self notificationForMessage:msg badgeCount:count];
        }
        
    } else if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        WFCCPCLoginRequestMessageContent *pcLoginRequest;
        for (WFCCMessage *msg in messages) {
            if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) < 60) {
                if ([msg.content isKindOfClass:[WFCCPCLoginRequestMessageContent class]]) {
                    pcLoginRequest = (WFCCPCLoginRequestMessageContent *)msg.content;
                }
            }
        }
        if (pcLoginRequest) {
            __block UINavigationController *nav;
            if ([self.window.rootViewController isKindOfClass:[UINavigationController class]]) {
                nav = (UINavigationController *)self.window.rootViewController;
            } else if ([self.window.rootViewController isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tab = (UITabBarController *)self.window.rootViewController;
                [tab.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[UINavigationController class]]) {
                        nav = obj;
                        *stop = YES;
                    }
                }];
            }
            
            if (nav) {
                PCLoginConfirmViewController *vc2 = [[PCLoginConfirmViewController alloc] init];
                vc2.sessionId = pcLoginRequest.sessionId;
                vc2.platform = pcLoginRequest.platform;
                vc2.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.window.rootViewController presentViewController:vc2 animated:YES completion:nil];
            } else {
                NSLog(@"怎么样才能模态弹出PC登录确认画面呢？");
            }
            
        }
    }
}
- (void)notificationForMessage:(WFCCMessage *)msg badgeCount:(NSInteger)count {
    //当在后台活跃时收到新消息，需要弹出本地通知。有一种可能时客户端已经收到远程推送，然后由于voip/backgroud fetch在后台拉活了应用，此时会收到接收下来消息，因此需要避免重复通知
    if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) > 3) {
        return;
    }
    
    if (msg.direction == MessageDirection_Send) {
        return;
    }
    
    int flag = (int)[msg.content.class performSelector:@selector(getContentFlags)];
    WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:msg.conversation];
    if(((flag & 0x03) || [msg.content isKindOfClass:[WFCCRecallMessageContent class]]) && !info.isSilent && ![msg.content isKindOfClass:[WFCCCallStartMessageContent class]]) {

      UILocalNotification *localNote = [[UILocalNotification alloc] init];
        if([[WFCCIMService sharedWFCIMService] isHiddenNotificationDetail] && ![msg.content isKindOfClass:[WFCCRecallMessageContent class]]) {
            localNote.alertBody = @"您收到了新消息";
        } else {
            localNote.alertBody = [msg digest];
        }
        if(msg.conversation.type == SecretChat_Type) {
            localNote.alertBody = @"您收到了新的密聊消息";
        }
      if (msg.conversation.type == Single_Type) {
        WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.conversation.target refresh:NO];
        if (sender.displayName) {
            if (@available(iOS 8.2, *)) {
                localNote.alertTitle = sender.displayName;
            } else {
                // Fallback on earlier versions
            }
        }
      } else if(msg.conversation.type == Group_Type) {
          WFCCGroupInfo *group = [[WFCCIMService sharedWFCIMService] getGroupInfo:msg.conversation.target refresh:NO];
          WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.fromUser refresh:NO];
          if (sender.displayName && group.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = [NSString stringWithFormat:@"%@@%@:", sender.displayName, group.displayName];
              } else {
                  // Fallback on earlier versions
              }
          }else if (sender.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = sender.displayName;
              } else {
                  // Fallback on earlier versions
              }
          }
          if (msg.status == Message_Status_Mentioned || msg.status == Message_Status_AllMentioned) {
              if (sender.displayName) {
                  localNote.alertBody = [NSString stringWithFormat:@"%@在群里@了你", sender.displayName];
              } else {
                  localNote.alertBody = @"有人在群里@了你";
              }
                  
          }
      } else if (msg.conversation.type == SecretChat_Type) {
          NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:msg.conversation.target].userId;
          WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
          if (sender.displayName) {
              if (@available(iOS 8.2, *)) {
                  localNote.alertTitle = sender.displayName;
              } else {
                  // Fallback on earlier versions
              }
          }
      } else if(msg.conversation.type == Channel_Type) {
          WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:msg.conversation.target refresh:NO];
          localNote.alertTitle = channelInfo.name;
      }
        
      localNote.applicationIconBadgeNumber = count;
        localNote.userInfo = @{@"conversationType" : @(msg.conversation.type), @"conversationTarget" : msg.conversation.target, @"conversationLine" : @(msg.conversation.line), @"messageUid":@(msg.messageUid) };
    
      
        dispatch_async(dispatch_get_main_queue(), ^{
          [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        });
    }
}

- (NSInteger)updateBadgeNumber {
    WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
    int unreadFriendRequest = [[WFCCIMService sharedWFCIMService] getUnreadFriendRequestStatus];
    int count = unreadCount.unread + unreadFriendRequest;
    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
    
    //同步到IM服务，IM服务当需要推送时，把这个数字发到推送服务，从而计算较为精确的角标数
    [[WFCCIMService sharedWFCIMService] uploadBadgeNumber:count];
    
    return count;
}

- (void)onRecallMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    NSInteger count = [self updateBadgeNumber];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if([self shouldMuteNotification]) {
            return;
        }
        WFCCMessage *msg = [[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid];
        if(msg) {
            [self notificationForMessage:msg badgeCount:count];
        }
    }
}

- (void)onDeleteMessage:(long long)messageUid {
    [self cancelNotification:messageUid];
    [self updateBadgeNumber];
}

- (BOOL)cancelNotification:(long long)messageUid {
    __block BOOL canceled = NO;
    [[[UIApplication sharedApplication] scheduledLocalNotifications] enumerateObjectsUsingBlock:^(UILocalNotification * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.userInfo[@"messageUid"] longLongValue] == messageUid) {
            [[UIApplication sharedApplication] cancelLocalNotification:obj];
            *stop = YES;
            canceled = YES;
        }
    }];
    return YES;
}

- (void)jumpToLoginViewController:(BOOL)isKickedOff {
    WFCLoginViewController *loginVC = [[WFCLoginViewController alloc] init];
    loginVC.isKickedOff = isKickedOff;
    loginVC.isPwdLogin = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    self.window.rootViewController = nav;
    
    //移除水印
    if(ENABLE_WATER_MARKER) {
        [self.window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[TYHWaterMarkView class]]) {
                [obj removeFromSuperview];
                [TYHWaterMarkView autoUpdateDate:NO];
                *stop = YES;
            }
        }];
    }
}

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect || status == kConnectionStatusSecretKeyMismatch || status == kConnectionStatusKickedoff) {
            if(status == kConnectionStatusKickedoff) {
                [self jumpToLoginViewController:YES];
            }
            
            [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
            
            [SSKeychain deletePasswordForWFService:@"savedToken"];
            [SSKeychain deletePasswordForWFService:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else if (status == kConnectionStatusLogout) {
            BOOL alreadyShowLoginVC = NO;
            if([self.window.rootViewController isKindOfClass:UINavigationController.class]) {
                UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                if(nav.viewControllers.count == 1 && [nav.viewControllers[0] isKindOfClass:WFCLoginViewController.class]) {
                    alreadyShowLoginVC = YES;
                }
            }
            
            if(!alreadyShowLoginVC) {
                [self jumpToLoginViewController:NO];
            }
            
            [SSKeychain deletePasswordForWFService:@"savedToken"];
            [SSKeychain deletePasswordForWFService:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.firstConnected = NO;
        } else if(status == kConnectionStatusConnected) {
            if(!self.firstConnected) {
                self.firstConnected = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self prepardDataForShareExtension];
                });
                
                [[OrgService sharedOrgService] login:^{
                    NSLog(@"on org service login success");
                    [[WFCUOrganizationCache sharedCache] loadMyOrganizationInfos];
                } error:^(int errCode) {
                    NSLog(@"on org service login failure");
                }];
            }
        } else if(status == kConnectionStatusNotLicensed) {
            NSLog(@"专业版IM服务没有授权或者授权过期！！！");
            [self.window.rootViewController.view makeToast:@"专业版IM服务没有授权或者授权过期！！！" duration:3 position:CSToastPositionCenter];
        } else if(status == kConnectionStatusTimeInconsistent) {
            NSLog(@"服务器和客户端时间相差太大！！！");
            [self.window.rootViewController.view makeToast:@"服务器和客户端时间相差太大！！！" duration:3 position:CSToastPositionCenter];
        }
    });
}

- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port {
    NSLog(@"connecting to server %@,%@,%d", host, ip, port);
}

- (void)onConnected:(NSString *)host ip:(NSString *)ip port:(int)port mainNw:(BOOL)mainNw {
    NSLog(@"connected to server %@,%@,%d,%d", host, ip, port, mainNw);
}

- (void)setupNavBar {
    [[WFCUConfigManager globalManager] setupNavBar];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self handleUrl:[url absoluteString] withNav:application.delegate.window.rootViewController.navigationController];
}

- (BOOL)handleUrl:(NSString *)str withNav:(UINavigationController *)navigator {
    NSLog(@"str scanned %@", str);
    if ([str rangeOfString:@"wildfirechat://user" options:NSCaseInsensitiveSearch].location == 0) {
        //wildfirechat://user/userId?from=fromUserId
        NSURLComponents *components = [NSURLComponents componentsWithString:str];
        NSString *fromUserId;
        for (NSURLQueryItem *item in components.queryItems) {
            if([@"from" isEqualToString:item.name]) {
                fromUserId = item.value;
                break;
            }
        }
        NSString *userId = components.path.lastPathComponent;
        WFCUProfileTableViewController *vc2 = [[WFCUProfileTableViewController alloc] init];
        vc2.userId = userId;
        vc2.sourceType = FriendSource_QrCode;
        vc2.sourceTargetId = fromUserId;
        vc2.hidesBottomBarWhenPushed = YES;
        
        [navigator pushViewController:vc2 animated:YES];
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://group" options:NSCaseInsensitiveSearch].location == 0) {
        //wildfirechat://group/groupId?from=fromUserId
        NSURLComponents *components = [NSURLComponents componentsWithString:str];
        NSString *fromUserId;
        for (NSURLQueryItem *item in components.queryItems) {
            if([@"from" isEqualToString:item.name]) {
                fromUserId = item.value;
                break;
            }
        }
        NSString *groupId = components.path.lastPathComponent;

        WFCUGroupInfoViewController *vc2 = [[WFCUGroupInfoViewController alloc] init];
        vc2.groupId = groupId;
        vc2.sourceType = GroupMemberSource_QrCode;
        vc2.sourceTargetId = fromUserId;
        vc2.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc2 animated:YES];
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://pcsession" options:NSCaseInsensitiveSearch].location == 0) {
//        str = @"wildfirechat://pcsession/mysessionid?platform=3";
        NSURL *URL = [NSURL URLWithString:str];
        
        NSString *sessionId = [URL lastPathComponent];
        NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithCapacity:2];
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:str];
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [params setObject:obj.value forKey:obj.name];
        }];
        int platform = [params[@"platform"] intValue];
        
        
        PCLoginConfirmViewController *vc2 = [[PCLoginConfirmViewController alloc] init];
        vc2.sessionId = sessionId;
        vc2.platform = platform;
        vc2.modalPresentationStyle = UIModalPresentationFullScreen;
        [navigator presentViewController:vc2 animated:YES completion:nil];
        return YES;
    } else
#if WFCU_SUPPORT_VOIP
        if ([str rangeOfString:@"wildfirechat://conference" options:NSCaseInsensitiveSearch].location == 0) {
//        str = @"wildfirechat://conference/conferenceid?password=123456";
        NSURL *URL = [NSURL URLWithString:str];
        
        NSString *conferenceId = [URL lastPathComponent];
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:str];
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [params setObject:obj.value forKey:obj.name];
        }];
        NSString *password = params[@"password"];
        
        
        __weak typeof(self)ws = self;
        __block MBProgressHUD *hud = [self startProgress:@"会议加载中" inView:navigator.view];
        if ([WFAVEngineKit sharedEngineKit].supportConference) {
            [[WFCUConfigManager globalManager].appServiceProvider queryConferenceInfo:conferenceId password:password success:^(WFZConferenceInfo * _Nonnull conferenceInfo) {
                [ws stopProgress:hud inView:navigator.view finishText:nil];
                WFZConferenceInfoViewController *vc = [[WFZConferenceInfoViewController alloc] init];
                vc.conferenceId = conferenceInfo.conferenceId;
                vc.password = conferenceInfo.password;
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                nav.modalPresentationStyle = UIModalPresentationFullScreen;
                [navigator presentViewController:nav animated:YES completion:nil];
            } error:^(int errorCode, NSString * _Nonnull message) {
                if (errorCode == 16) {
                    [ws stopProgress:hud inView:navigator.view finishText:@"会议已结束！"];
                } else {
                    [ws stopProgress:hud inView:navigator.view finishText:@"网络错误"];
                }
            }];
        } else {
            [ws stopProgress:hud inView:navigator.view finishText:@"不支持会议"];
        }
        return YES;
    }
#endif
    return NO;
}
- (MBProgressHUD *)startProgress:(NSString *)text inView:(UIView *)view {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = text;
    [hud showAnimated:YES];
    return hud;
}

- (MBProgressHUD *)stopProgress:(MBProgressHUD *)hud inView:(UIView *)view finishText:(NSString *)text {
    [hud hideAnimated:YES];
    if(text) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = text;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }
    return hud;
}

#if WFCU_SUPPORT_VOIP
#pragma mark - WFAVEngineDelegate
//voip 当可以使用pushkit时，如果有来电或者结束，会唤起应用，收到来电通知/电话结束通知，弹出通知。
- (void)didReceiveCall:(WFAVCallSession *)session {
#if !USE_CALL_KIT
    //收到来电通知后等待200毫秒，检查session有效后再弹出通知。原因是当当前用户不在线时如果有人来电并挂断，当前用户再连接后，会出现先弹来电界面，再消失的画面。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WFAVEngineKit sharedEngineKit].currentSession.state != kWFAVEngineStateIncomming && [WFAVEngineKit sharedEngineKit].currentSession.state != kWFAVEngineStateConnected && [WFAVEngineKit sharedEngineKit].currentSession.state != kWFAVEngineStateConnecting) {
            return;
        }
        
        UIViewController *videoVC;
        if (session.conversation.type == Group_Type && [WFAVEngineKit sharedEngineKit].supportMultiCall) {
            videoVC = [[WFCUMultiVideoViewController alloc] initWithSession:session];
        } else {
            videoVC = [[WFCUVideoViewController alloc] initWithSession:session];
        }
        
        [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            if([[WFCCIMService sharedWFCIMService] isVoipNotificationSilent]) {
                NSLog(@"用户设置禁止voip通知，忽略来电提醒");
                return;
            }
            self.localCallNotification = [[UILocalNotification alloc] init];
            
            self.localCallNotification.alertBody = @"来电话了";
            
                WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:session.inviter refresh:NO];
                if (sender.displayName) {
                    if (@available(iOS 8.2, *)) {
                        self.localCallNotification.alertTitle = sender.displayName;
                    } else {
                        // Fallback on earlier versions
                        
                    }
                }
            
            self.localCallNotification.soundName = @"ring.caf";
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] scheduleLocalNotification:self.localCallNotification];
            });
        } else {
            self.localCallNotification = nil;
        }
    });
#else
    [self.callKitManager didReceiveCall:session];
#endif
}

- (void)shouldStartRing:(BOOL)isIncoming {
#if !USE_CALL_KIT
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming || [WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateOutgoing) {
            if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                if([[WFCCIMService sharedWFCIMService] isVoipNotificationSilent]) {
                    NSLog(@"用户设置禁止voip通知，忽略来电震动");
                    return;
                }
                AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, systemAudioCallback, NULL);
                AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
            } else {
                if (self.audioPlayer) {
                    [self shouldStopRing];
                }
        
                if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming) {
                    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, systemAudioCallback, NULL);
                    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
                }
                
                NSURL *url = [[NSBundle mainBundle] URLForResource:@"ring" withExtension:@"caf"];
                NSError *error = nil;
                self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
                if (!error) {
                    self.audioPlayer.numberOfLoops = -1;
                    self.audioPlayer.volume = 1.0;
                    [self.audioPlayer prepareToPlay];
                    [self.audioPlayer play];
                }
            }
        }
    });
#endif
}

void systemAudioCallback (SystemSoundID soundID, void* clientData) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    });
}

- (void)shouldStopRing {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
    }
}

- (void)didCallEnded:(WFAVCallEndReason)reason duration:(int)callDuration {
#if !USE_CALL_KIT
    //在后台时，如果电话挂断，清除掉来电通知，如果未接听超时或者未接通对方挂掉，弹出结束本地通知。
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        if(self.localCallNotification) {
            [[UIApplication sharedApplication] cancelLocalNotification:self.localCallNotification];
            self.localCallNotification = nil;
        }
        
        if(reason == kWFAVCallEndReasonTimeout || (reason == kWFAVCallEndReasonRemoteHangup && callDuration == 0)) {
            UILocalNotification *callEndNotification = [[UILocalNotification alloc] init];
            if(reason == kWFAVCallEndReasonTimeout) {
                callEndNotification.alertBody = @"来电未接听";
            } else {
                callEndNotification.alertBody = @"来电已取消";
            }
            if (@available(iOS 8.2, *)) {
                self.localCallNotification.alertTitle = @"网络通话";
                if([WFAVEngineKit sharedEngineKit].currentSession.inviter) {
                    WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFAVEngineKit sharedEngineKit].currentSession.inviter refresh:NO];
                    if (sender.displayName) {
                        self.localCallNotification.alertTitle = sender.displayName;
                    }
                }
            }
            
            //应该播放挂断的声音
//            self.localCallNotification.soundName = @"ring.caf";
            [[UIApplication sharedApplication] scheduleLocalNotification:callEndNotification];
        }
    }
#else
    [self.callKitManager didCallEnded:reason duration:callDuration];
#endif
}


/// [ 系统回调 ] 系统返回VOIPToken，并提交个推服务器
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    // [ GTSDK ]：（新版）向个推服务器注册 VoipToken
#if USE_GETUI_PUSH
    [GeTuiSdk registerVoipTokenCredentials:credentials.token];
#endif

}

- (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
                                  forType:(NSString *)type {
    NSLog(@"didReceiveIncomingPushWithPayload");
#if USE_CALL_KIT
    [self.callKitManager didReceiveIncomingPushWithPayload:payload forType:type];
#endif
}
#endif

//voip 当无法使用pushkit时，需要使用backgroup推送，在这里弹出来电通知和取消来电通知
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if([userInfo[@"voip"] boolValue]) {
        if([userInfo[@"voip_type"] intValue] == 1) { //incomming call
            NSDictionary *aps = userInfo[@"aps"];
            if(aps && aps[@"alert"]) {
                NSString *title = aps[@"alert"][@"title"];
                NSString *body = aps[@"alert"][@"body"];
                NSString *sound = aps[@"sound"];
                
                self.localCallNotification = [[UILocalNotification alloc] init];
                
                self.localCallNotification.alertBody = body;
                if (@available(iOS 8.2, *)) {
                    self.localCallNotification.alertTitle = title;
                } else {
                    // Fallback on earlier versions
                }
                
                self.localCallNotification.soundName = @"ring.caf";
                [[UIApplication sharedApplication] scheduleLocalNotification:self.localCallNotification];
            }
        } else if([userInfo[@"voip_type"] intValue] == 2) {
            if(self.localCallNotification) {
                [[UIApplication sharedApplication] cancelLocalNotification:self.localCallNotification];
                self.localCallNotification = nil;
            }
            
            NSDictionary *aps = userInfo[@"aps"];
            if(aps && aps[@"alert"]) {
                NSString *title = aps[@"alert"][@"title"];
                NSString *body = aps[@"alert"][@"body"];
                NSString *sound = aps[@"sound"];
                UILocalNotification *callEndNotification = [[UILocalNotification alloc] init];
                callEndNotification.alertBody = body;
                    
                if (@available(iOS 8.2, *)) {
                    self.localCallNotification.alertTitle = title;
                }
                    
                    //应该播放挂断的声音
        //            self.localCallNotification.soundName = @"ring.caf";
                [[UIApplication sharedApplication] scheduleLocalNotification:callEndNotification];
            }
        }
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

#pragma mark - UNUserNotificationCenterDelegate
//将要推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler API_AVAILABLE(ios(10.0)){
    NSLog(@"----------willPresentNotification");
}
//已经完成推送
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)){
    NSLog(@"============didReceiveNotificationResponse");
    NSString *categoryID = response.notification.request.content.categoryIdentifier;
    if ([categoryID isEqualToString:@"categoryIdentifier"]) {
        if ([response.actionIdentifier isEqualToString:@"enterApp"]) {
            if (@available(iOS 10.0, *)) {
                
            } else {
                // Fallback on earlier versions
            }
        }else{
            NSLog(@"No======");
        }
    }
    completionHandler();
}


#pragma mark - QrCodeDelegate
- (void)showQrCodeViewController:(UINavigationController *)navigator type:(int)type target:(NSString *)target {
    CreateBarCodeViewController *vc = [CreateBarCodeViewController new];
    vc.qrType = type;
    vc.target = target;
    [navigator pushViewController:vc animated:YES];
}

- (void)scanQrCode:(UINavigationController *)navigator {
    QQLBXScanViewController *vc = [QQLBXScanViewController new];
    vc.libraryType = SLT_Native;
    vc.scanCodeType = SCT_QRCode;
    
    vc.style = [StyleDIY qqStyle];
    
    //镜头拉远拉近功能
    vc.isVideoZoom = YES;
    
    vc.hidesBottomBarWhenPushed = YES;
    __weak typeof(self)ws = self;
    vc.scanResult = ^(NSString *str) {
        [ws handleUrl:str withNav:navigator];
    };
    
    [navigator pushViewController:vc animated:YES];
}

#ifdef WFC_PTT
- (void)playPttRing:(NSString *)ring {
    NSURL *url = [[NSBundle mainBundle] URLForResource:ring withExtension:@"m4a"];
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (!error) {
        self.audioPlayer.numberOfLoops = 0;
        self.audioPlayer.volume = 1.0;
        [self.audioPlayer prepareToPlay];
        [self.audioPlayer play];
    }
}

#pragma - mark WFPttDelegate
- (void)didConversation:(WFCCConversation *)conversation startTalkingUser:(NSString *)userId {
    [self playPttRing:@"ptt_begin"];
}

- (void)didConversation:(WFCCConversation *)conversation endTalkingUser:(NSString *)userId {
    [self playPttRing:@"ptt_end"];
}
- (void)didConversation:(WFCCConversation *)conversation amplitudeUpdate:(int)amplitude ofUser:(NSString *)userId {
    NSLog(@"on ptt user %@ speak %d", userId, amplitude);
}
#endif
#if USE_GETUI_PUSH
//MARK: - GeTuiSdkDelegate


/// [ GTSDK回调 ] SDK启动成功返回cid
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    [[WFCCNetworkService sharedInstance] setDeviceToken:clientId pushType:7];
}

/// [ GTSDK回调 ] SDK运行状态通知
- (void)GeTuiSDkDidNotifySdkState:(SdkStatus)aStatus {
    [[NSNotificationCenter defaultCenter] postNotificationName:GTSdkStateNotification object:self];
}

- (void)GeTuiSdkDidOccurError:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [GeTuiSdk GeTuiSdkDidOccurError]:%@\n\n",error.localizedDescription];
    NSLog(msg);
}

//MARK: - 通知回调

/// 通知授权结果（iOS10及以上版本）
/// @param granted 用户是否允许通知
/// @param error 错误信息
- (void)GetuiSdkGrantAuthorization:(BOOL)granted error:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [APNs] %@ \n%@ %@", NSStringFromSelector(_cmd), @(granted), error];
    NSLog(msg);
}

/// 通知展示（iOS10及以上版本）
/// @param center center
/// @param notification notification
/// @param completionHandler completionHandler
- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification completionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [APNs] %@ \n%@", NSStringFromSelector(_cmd), notification.request.content.userInfo];
    NSLog(msg);
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要，判断是否要提示用户Badge、Sound、Alert等
    //completionHandler(UNNotificationPresentationOptionNone); 若不显示通知，则无法点击通知
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

/// 收到通知信息
/// @param userInfo apns通知内容
/// @param center UNUserNotificationCenter（iOS10及以上版本）
/// @param response UNNotificationResponse（iOS10及以上版本）
/// @param completionHandler 用来在后台状态下进行操作（iOS10以下版本）
- (void)GeTuiSdkDidReceiveNotification:(NSDictionary *)userInfo notificationCenter:(UNUserNotificationCenter *)center response:(UNNotificationResponse *)response fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [APNs] %@ \n%@", NSStringFromSelector(_cmd), userInfo];
    NSLog(msg);
    if(completionHandler) {
        // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要自行修改参数值
        completionHandler(UIBackgroundFetchResultNoData);
    }
}


/// 收到透传消息
/// @param userInfo    推送消息内容
/// @param fromGetui   YES: 个推通道  NO：苹果apns通道
/// @param offLine     是否是离线消息，YES.是离线消息
/// @param appId       应用的appId
/// @param taskId      推送消息的任务id
/// @param msgId       推送消息的messageid
/// @param completionHandler 用来在后台状态下进行操作（通过苹果apns通道的消息 才有此参数值）
- (void)GeTuiSdkDidReceiveSlience:(NSDictionary *)userInfo fromGetui:(BOOL)fromGetui offLine:(BOOL)offLine appId:(NSString *)appId taskId:(NSString *)taskId msgId:(NSString *)msgId fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // [ GTSDK ]：汇报个推自定义事件(反馈透传消息)，开发者可以根据项目需要决定是否使用, 非必须
    // [GeTuiSdk sendFeedbackMessage:90001 andTaskId:taskId andMsgId:msgId];
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [APN] %@ \nReceive Slience: fromGetui:%@ appId:%@ offLine:%@ taskId:%@ msgId:%@ userInfo:%@ ", NSStringFromSelector(_cmd), fromGetui ? @"个推消息" : @"APNs消息", appId, offLine ? @"离线" : @"在线", taskId, msgId, userInfo];
    NSLog(msg);
    
    //本地通知UserInfo参数
    NSDictionary *dic = nil;
    if (fromGetui) {
        //个推在线透传
        //个推进行本地通知统计 userInfo中必须要有_gmid_参数
        dic = @{@"_gmid_": [NSString stringWithFormat:@"%@:%@", taskId ?: @"", msgId ?: @""]};
    } else {
        //APNs静默通知
        dic = userInfo;
    }
    if (fromGetui && offLine == NO) {
        //个推通道+在线，发起本地通知
        [Utils pushLocalNotification:userInfo[@"payload"] userInfo:dic];
    }
    if(completionHandler) {
        // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要自行修改参数值
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

- (void)GeTuiSdkNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(UNNotification *)notification {
    // [ 参考代码，开发者注意根据实际需求自行修改 ] 根据APP需要自行修改参数值
}

//MARK: - 发送上行消息

/// [ GTSDK回调 ] SDK收到sendMessage消息回调
- (void)GeTuiSdkDidSendMessage:(NSString *)messageId result:(BOOL)isSuccess error:(NSError *)aError {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] [GeTuiSdk DidSendMessage]: \nReceive sendmessage:%@ result:%d error:%@", messageId, isSuccess, aError];
    NSLog(msg);
}


//MARK: - 开关设置

/// [ GTSDK回调 ] SDK设置推送模式回调
- (void)GeTuiSdkDidSetPushMode:(BOOL)isModeOff error:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@">>>[GexinSdkSetModeOff]: %@ %@", isModeOff ? @"开启" : @"关闭", [error localizedDescription]];
    NSLog(msg);
}


//MARK: - 别名设置

- (void)GeTuiSdkDidAliasAction:(NSString *)action result:(BOOL)isSuccess sequenceNum:(NSString *)aSn error:(NSError *)aError {
    /*
     参数说明
     isSuccess: YES: 操作成功 NO: 操作失败
     aError.code:
     30001：绑定别名失败，频率过快，两次调用的间隔需大于 5s
     30002：绑定别名失败，参数错误
     30003：绑定别名请求被过滤
     30004：绑定别名失败，未知异常
     30005：绑定别名时，cid 未获取到
     30006：绑定别名时，发生网络错误
     30007：别名无效
     30008：sn 无效 */
    NSString *msg = nil;
    if([action isEqual:kGtResponseBindType]) {
        msg = [NSString stringWithFormat:@"[ TestDemo ] bind alias result sn = %@, code = %@", aSn, @(aError.code)];
    }
    if([action isEqual:kGtResponseUnBindType]) {
        msg = [NSString stringWithFormat:@"[ TestDemo ] unbind alias result sn = %@, code = %@", aSn, @(aError.code)];
    }
    NSLog(msg);
}


//MARK: - 标签设置

- (void)GeTuiSdkDidSetTagsAction:(NSString *)sequenceNum result:(BOOL)isSuccess error:(NSError *)aError {
    /*
     参数说明
     sequenceNum: 请求的序列码
     isSuccess: 操作成功 YES, 操作失败 NO
     aError.code:
     20001：tag 数量过大（单次设置的 tag 数量不超过 100)
     20002：调用次数超限（默认一天只能成功设置一次）
     20003：标签重复
     20004：服务初始化失败
     20005：setTag 异常
     20006：tag 为空
     20007：sn 为空
     20008：离线，还未登陆成功
     20009：该 appid 已经在黑名单列表（请联系技术支持处理）
     20010：已存 tag 数目超限
     20011：tag 内容格式不正确
     */
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] GeTuiSdkDidSetTagAction sequenceNum:%@ isSuccess:%@ error: %@", sequenceNum, @(isSuccess), aError];
    NSLog(msg);
}


//MARK: - 应用内弹窗

// 展示回调
- (void)GeTuiSdkPopupDidShow:(NSDictionary *)info {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] GeTuiSdkPopupDidShow%@", info];
    NSLog(msg);
}

// 点击回调
- (void)GeTuiSdkPopupDidClick:(NSDictionary *)info {
    NSString *msg = [NSString stringWithFormat:@"[ TestDemo ] GeTuiSdkPopupDidClick%@", info];
    NSLog(msg);
}

#endif
@end
