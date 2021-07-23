//
//  AppDelegate.m
//  WildFireChat
//
//  Created by WF Chat on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


//如果您不需要voip功能，请在ChatUIKit工程中关掉voip功能，然后这里定义WFCU_SUPPORT_VOIP为0
//ChatUIKit关闭voip的方式是，找到ChatUIKit工程下的Predefine.h头文件，定义WFCU_SUPPORT_VOIP为0，
//然后找到脚本“xcodescript.sh”，删除掉“cp -af WFChatUIKit/AVEngine/*  ${DST_DIR}/”这句话。
//在删除掉ChatUIKit工程的WebRTC和WFAVEngineKit的依赖。
//删除掉应用工程中的WebRTC.framework和WFAVEngineKit.framework。
#define WFCU_SUPPORT_VOIP 1
//#define WFCU_SUPPORT_VOIP 0

#import "AppDelegate.h"
#import <WFChatClient/WFCChatClient.h>
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#import <WebRTC/WebRTC.h>
#endif
#import "WFCLoginViewController.h"
#import "WFCConfig.h"
#import "WFCBaseTabBarController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import <UserNotifications/UserNotifications.h>
#import "CreateBarCodeViewController.h"
#import "PCLoginConfirmViewController.h"
#import "QQLBXScanViewController.h"
#import "StyleDIY.h"
#import <Bugly/Bugly.h>
#import "AppService.h"
#import "UIColor+YH.h"
#import "SharedConversation.h"
#import "SharePredefine.h"

@interface AppDelegate () <ConnectionStatusDelegate, ReceiveMessageDelegate,
#if WFCU_SUPPORT_VOIP
    WFAVEngineDelegate,
#endif
    UNUserNotificationCenterDelegate, QrCodeDelegate>
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@property(nonatomic, strong) UILocalNotification *localCallNotification;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //替换为您自己的Bugly账户。
    [Bugly startWithAppId:@"6f54460b01"];
    
    [WFCCNetworkService startLog];
//    [[WFCCNetworkService sharedInstance] useSM4];
    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST];
    [[WFCCNetworkService sharedInstance] setBackupAddressStrategy:0];
//    [[WFCCNetworkService sharedInstance] setBackupAddress:@"192.168.1.120" port:80];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    //当PC/Web在线时手机端是否静音，默认静音。如果修改为默认不静音，需要打开下面函数。
    //另外需要IM服务配置server.mobile_default_silent_when_pc_online为false。必须保持与服务器同步。
    //[[WFCCIMService sharedWFCIMService] setDefaultSilentWhenPcOnline:NO];

#if WFCU_SUPPORT_VOIP
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
    

    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    self.window.rootViewController = [WFCBaseTabBarController new];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self setupNavBar];
    
    setQrCodeDelegate(self);
    
    
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
    
    

    
    if (savedToken.length > 0 && savedUserId.length > 0) {
        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。另外不能多次connect，如果需要切换用户请先disconnect，然后3秒钟之后再connect（如果是用户手动登录可以不用等，因为用户操作很难3秒完成，如果程序自动切换请等3秒）。
        [[WFCCNetworkService sharedInstance] connect:savedUserId token:savedToken];
    } else {
        UIViewController *loginVC = [[WFCLoginViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
        self.window.rootViewController = nav;
    }
    
    return YES;
}


- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:
(UIUserNotificationSettings *)notificationSettings {
    // register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
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
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
    int unreadFriendRequest = [[WFCCIMService sharedWFCIMService] getUnreadFriendRequestStatus];
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadCount.unread + unreadFriendRequest;
    
    [self prepardDataForShareExtension];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
    for (WFCCConversationInfo *info in infos) {
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
            sc.title = groupInfo.name;
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
    for (NSString *groupId in needComposedGroupIds) {
        //获取已经拼接好的头像，如果没有拼接会返回为空
        NSString *file = [WFCCUtilities getGroupGridPortrait:groupId width:80 generateIfNotExist:NO defaultUserPortrait:^UIImage *(NSString *userId) {
            return nil;
        }];
        
        if (file.length) {
            NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
            [[NSData dataWithContentsOfFile:file] writeToURL:fileURL atomically:YES];
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

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
        int count = unreadCount.unread;
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;
        
        __block BOOL isNoDisturbing = NO;
        [[WFCCIMService sharedWFCIMService] getNoDisturbingTimes:^(int startMins, int endMins) {
            NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *nowCmps = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date]];
            int nowMins = (int)(nowCmps.hour * 60 + nowCmps.minute);
            if (endMins > startMins) {
                if (endMins > nowMins && nowMins > startMins) {
                    isNoDisturbing = YES;
                }
            } else {
                if (endMins < nowMins || nowMins < startMins) {
                    isNoDisturbing = YES;
                }
            }
            
        } error:^(int error_code) {
            
        }];
        
        //免打扰
        if (isNoDisturbing) {
            return;
        }
        
        //全局静音
        if ([[WFCCIMService sharedWFCIMService] isGlobalSilent]) {
            return;
        }
        
        BOOL pcOnline = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos].count > 0;
        BOOL muteWhenPcOnline = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
        
        
        for (WFCCMessage *msg in messages) {
            //当在后台活跃时收到新消息，需要弹出本地通知。有一种可能时客户端已经收到远程推送，然后由于voip/backgroud fetch在后台拉活了应用，此时会收到接收下来消息，因此需要避免重复通知
            if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) > 3) {
                continue;
            }
            
            if (msg.direction == MessageDirection_Send) {
                continue;
            }
            
            int flag = (int)[msg.content.class performSelector:@selector(getContentFlags)];
            WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:msg.conversation];
            if((flag & 0x03) && !info.isSilent && ![msg.content isKindOfClass:[WFCCCallStartMessageContent class]]) {

                
            if (msg.status != Message_Status_Mentioned && msg.status != Message_Status_AllMentioned && pcOnline && muteWhenPcOnline) {
                continue;
            }
                
              UILocalNotification *localNote = [[UILocalNotification alloc] init];
              
              localNote.alertBody = [msg digest];
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
                  if (sender.displayName && group.name) {
                      if (@available(iOS 8.2, *)) {
                          localNote.alertTitle = [NSString stringWithFormat:@"%@@%@:", sender.displayName, group.name];
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
              }
              
              localNote.applicationIconBadgeNumber = count;
              localNote.userInfo = @{@"conversationType" : @(msg.conversation.type), @"conversationTarget" : msg.conversation.target, @"conversationLine" : @(msg.conversation.line) };
              
                dispatch_async(dispatch_get_main_queue(), ^{
                  [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
                });
            }
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

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect || status == kConnectionStatusSecretKeyMismatch) {
            [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else if (status == kConnectionStatusLogout) {
            UIViewController *loginVC = [[WFCLoginViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            self.window.rootViewController = nav;
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
            [[AppService sharedAppService] clearAppServiceAuthInfos];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } 
    });
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
    }
    return NO;
}

#if WFCU_SUPPORT_VOIP
#pragma mark - WFAVEngineDelegate
//voip 当可以使用pushkit时，如果有来电或者结束，会唤起应用，收到来电通知/电话结束通知，弹出通知。
- (void)didReceiveCall:(WFAVCallSession *)session {
    //收到来电通知后等待200毫秒，检查session有效后再弹出通知。原因是当当前用户不在线时如果有人来电并挂断，当前用户再连接后，会出现先弹来电界面，再消失的画面。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WFAVEngineKit sharedEngineKit].currentSession.state != kWFAVEngineStateIncomming) {
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
            if(self.localCallNotification) {
                [[UIApplication sharedApplication] scheduleLocalNotification:self.localCallNotification];
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
    
}

- (void)shouldStartRing:(BOOL)isIncoming {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming || [WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateOutgoing) {
            if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, systemAudioCallback, NULL);
                AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
            } else {
                AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                //默认情况按静音或者锁屏键会静音
                [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:nil];
                [audioSession setActive:YES error:nil];
                
                if (self.audioPlayer) {
                    [self shouldStopRing];
                }
                
                NSURL *url = [[NSBundle mainBundle] URLForResource:@"ring" withExtension:@"mp3"];
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
}

void systemAudioCallback (SystemSoundID soundID, void* clientData) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            if ([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateIncomming) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            }
        }
    });
}

- (void)shouldStopRing {
    if (self.audioPlayer) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }
}

- (void)didCallEnded:(WFAVCallEndReason)reason duration:(int)callDuration {
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
@end
