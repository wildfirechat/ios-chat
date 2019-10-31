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
#import "GroupInfoViewController.h"
#import <Bugly/Bugly.h>
#import "AppService.h"


@interface AppDelegate () <ConnectionStatusDelegate, ReceiveMessageDelegate,
#if WFCU_SUPPORT_VOIP
    WFAVEngineDelegate,
#endif
    UNUserNotificationCenterDelegate, QrCodeDelegate>
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //替换为您自己的Bugly账户。
    [Bugly startWithAppId:@"b21375e023"];
    
    [WFCCNetworkService startLog];
    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST port:IM_SERVER_PORT];
    
#if WFCU_SUPPORT_VOIP
    [[WFAVEngineKit sharedEngineKit] addIceServer:ICE_ADDRESS userName:ICE_USERNAME password:ICE_PASSWORD];
    [[WFAVEngineKit sharedEngineKit] setVideoProfile:kWFAVVideoProfile360P swapWidthHeight:YES];
    [WFAVEngineKit sharedEngineKit].delegate = self;
#endif
    
    [WFCUConfigManager globalManager].appServiceProvider = [AppService sharedAppService];
    

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
    [UIApplication sharedApplication].applicationIconBadgeNumber = unreadCount.unread;
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [WFCCNetworkService startLog];
}

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
        int count = unreadCount.unread;
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;
        
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
        
    }
}

- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == kConnectionStatusRejected || status == kConnectionStatusTokenIncorrect || status == kConnectionStatusSecretKeyMismatch) {
            [[WFCCNetworkService sharedInstance] disconnect:YES];
        } else if (status == kConnectionStatusLogout) {
            UIViewController *loginVC = [[WFCLoginViewController alloc] init];
            self.window.rootViewController = loginVC;
        } 
    });
}

- (void)setupNavBar {
    [WFCUConfigManager globalManager].naviBackgroudColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    [WFCUConfigManager globalManager].naviTextColor = [UIColor whiteColor];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    UINavigationBar *bar = [UINavigationBar appearance];
    bar.barTintColor = [WFCUConfigManager globalManager].naviBackgroudColor;
    bar.tintColor = [WFCUConfigManager globalManager].naviTextColor;
    bar.titleTextAttributes = @{NSForegroundColorAttributeName : [WFCUConfigManager globalManager].naviTextColor};
    bar.barStyle = UIBarStyleDefault;
    
    [[UITabBar appearance] setBarTintColor:[WFCUConfigManager globalManager].frameBackgroudColor];
    [UITabBar appearance].translucent = NO;
}
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [self handleUrl:[url absoluteString] withNav:application.delegate.window.rootViewController.navigationController];
}

- (BOOL)handleUrl:(NSString *)str withNav:(UINavigationController *)navigator {
    NSLog(@"str scanned %@", str);
    if ([str rangeOfString:@"wildfirechat://user" options:NSCaseInsensitiveSearch].location == 0) {
        NSString *userId = [str lastPathComponent];
        WFCUProfileTableViewController *vc2 = [[WFCUProfileTableViewController alloc] init];
        vc2.userId = userId;
        vc2.hidesBottomBarWhenPushed = YES;
        
        [navigator pushViewController:vc2 animated:YES];
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://group" options:NSCaseInsensitiveSearch].location == 0) {
        NSString *groupId = [str lastPathComponent];
        GroupInfoViewController *vc2 = [[GroupInfoViewController alloc] init];
        vc2.groupId = groupId;
        vc2.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc2 animated:YES];
        return YES;
    } else if ([str rangeOfString:@"wildfirechat://pcsession" options:NSCaseInsensitiveSearch].location == 0) {
        NSString *sessionId = [str lastPathComponent];
        PCLoginConfirmViewController *vc2 = [[PCLoginConfirmViewController alloc] init];
        vc2.sessionId = sessionId;
        vc2.hidesBottomBarWhenPushed = YES;
        [navigator pushViewController:vc2 animated:YES];
        return YES;
    }
    return NO;
}

#if WFCU_SUPPORT_VOIP
#pragma mark - WFAVEngineDelegate
- (void)didReceiveCall:(WFAVCallSession *)session {
    WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithSession:session];
    [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        
        localNote.alertBody = @"来电话了";
        
            WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:session.clientId refresh:NO];
            if (sender.displayName) {
                if (@available(iOS 8.2, *)) {
                    localNote.alertTitle = sender.displayName;
                } else {
                    // Fallback on earlier versions
                    
                }
            }
        
        localNote.soundName = @"ring.caf";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
        });
    }
}

- (void)shouldStartRing:(BOOL)isIncoming {
    
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
#endif
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
