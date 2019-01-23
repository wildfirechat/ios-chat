//
//  AppDelegate.m
//  WildFireChat
//
//  Created by WF Chat on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "AppDelegate.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFAVengineKit/WFAVengineKit.h>
#import "WFCLoginViewController.h"
#import "WFCConfig.h"
#import "WFCBaseTabBarController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <ConnectionStatusDelegate, ReceiveMessageDelegate, WFAVEngineDelegate, UNUserNotificationCenterDelegate>
@property(nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [WFCCNetworkService startLog];
    [WFCCNetworkService sharedInstance].connectionStatusDelegate = self;
    [WFCCNetworkService sharedInstance].receiveMessageDelegate = self;
    [[WFCCNetworkService sharedInstance] setServerAddress:IM_SERVER_HOST port:IM_SERVER_PORT];
    [[WFAVEngineKit sharedEngineKit] addIceServer:ICE_ADDRESS userName:ICE_USERNAME password:ICE_PASSWORD];
    [[WFAVEngineKit sharedEngineKit] setVideoProfile:kWFAVVideoProfile360P swapWidthHeight:YES];
    [WFAVEngineKit sharedEngineKit].delegate = self;
    

    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedToken"];
    NSString *savedUserId = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedUserId"];
    
    self.window.rootViewController = [WFCBaseTabBarController new];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self setupNavBar];
    
    
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
        
        
        //第二步：设置推送内容
//        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
//        content.title = @"推送中心标题";
//        content.subtitle = @"副标题";
//        content.body  = @"这是UNUserNotificationCenter信息中心";
//        content.badge = @20;
//        content.categoryIdentifier = @"categoryIdentifier";
        
        
        //        需要解锁显示，红色文字。点击不会进app。
        //        UNNotificationActionOptionAuthenticationRequired = (1 << 0),
        //
        //        黑色文字。点击不会进app。
        //        UNNotificationActionOptionDestructive = (1 << 1),
        //
        //        黑色文字。点击会进app。
        //        UNNotificationActionOptionForeground = (1 << 2),
        
        
//        UNNotificationAction *action = [UNNotificationAction actionWithIdentifier:@"enterApp"
//                                                                            title:@"进入应用"
//                                                                          options:UNNotificationActionOptionForeground];
//        UNNotificationAction *clearAction = [UNNotificationAction actionWithIdentifier:@"destructive"
//                                                                                 title:@"忽略2"
//                                                                               options:UNNotificationActionOptionDestructive];
//        UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:@"categoryIdentifier"
//                                                                                  actions:@[action,clearAction]
//                                                                        intentIdentifiers:@[requestID]
//                                                                                  options:UNNotificationCategoryOptionNone];
//        [center setNotificationCategories:[NSSet setWithObject:category]];
//
//        //第三步：设置推送方式
//        UNTimeIntervalNotificationTrigger *timeTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:60 repeats:YES];
//        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requestID content:content trigger:timeTrigger];
//
//        //第四步：添加推送request
//        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
//
//        }];
//
//
//        [center removePendingNotificationRequestsWithIdentifiers:@[requestID]];
//        [center removeAllDeliveredNotifications];
        //        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        //            NSLog(@"settings===%@",settings);
        //        }];
        
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
        //等待2s，以便sdk进行连接/接收等动作，这里也可以去掉
        [NSThread sleepForTimeInterval:2.f];
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
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"
                                                                             withString:@""]
                        stringByReplacingOccurrencesOfString:@">"
                        withString:@""]
                       stringByReplacingOccurrencesOfString:@" "
                       withString:@""];
    
    [[WFCCNetworkService sharedInstance] setDeviceToken:token];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0), @(1)]];
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
        WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0), @(1)]];
        int count = unreadCount.unread;
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;
        
        for (WFCCMessage *msg in messages) {
            //当在后台活跃时收到新消息，需要弹出本地通知。有一种可能时客户端已经收到远程推送，然后由于voip/backgroud fetch在后台拉活了应用，此时会收到接收下来消息，因此需要避免重复通知
            if (([[NSDate date] timeIntervalSince1970] - (msg.serverTime - [WFCCNetworkService sharedInstance].serverDeltaTime)/1000) > 3) {
                continue;
            }
            
            int flag = (int)[msg.content.class performSelector:@selector(getContentFlags)];
            WFCCConversationInfo *info = [[WFCCIMService sharedWFCIMService] getConversationInfo:msg.conversation];
            if((flag & 0x03) && !info.isSilent && ![msg.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
              UILocalNotification *localNote = [[UILocalNotification alloc] init];
              
              localNote.alertBody = [msg.content digest];
              if (msg.conversation.type == Single_Type) {
                WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.conversation.target refresh:NO];
                if (sender.name) {
                    if (@available(iOS 8.2, *)) {
                        localNote.alertTitle = sender.name;
                    } else {
                        // Fallback on earlier versions
                    }
                }
              } else if(msg.conversation.type == Group_Type) {
                  WFCCGroupInfo *group = [[WFCCIMService sharedWFCIMService] getGroupInfo:msg.conversation.target refresh:NO];
                  WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:msg.fromUser refresh:NO];
                  if (sender.name && group.name) {
                      if (@available(iOS 8.2, *)) {
                          localNote.alertTitle = [NSString stringWithFormat:@"%@@%@:", sender.name, group.name];
                      } else {
                          // Fallback on earlier versions
                      }
                  }else if (sender.name) {
                      if (@available(iOS 8.2, *)) {
                          localNote.alertTitle = sender.name;
                      } else {
                          // Fallback on earlier versions
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
        if (status == kConnectionStatusLogout) {
            UIViewController *loginVC = [[WFCLoginViewController alloc] init];
            self.window.rootViewController = loginVC;
        } 
    });
}

- (void)setupNavBar {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    UINavigationBar *bar = [UINavigationBar appearance];
    bar.barTintColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    bar.tintColor = [UIColor whiteColor];
    bar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    bar.barStyle = UIBarStyleBlack;
}

#pragma mark - WFAVEngineDelegate
- (void)didReceiveCall:(WFAVCallSession *)session {
    WFCUVideoViewController *videoVC = [[WFCUVideoViewController alloc] initWithSession:session];
    [[WFAVEngineKit sharedEngineKit] presentViewController:videoVC];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        UILocalNotification *localNote = [[UILocalNotification alloc] init];
        
        localNote.alertBody = @"来电话了";
        
            WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:session.clientId refresh:NO];
            if (sender.name) {
                if (@available(iOS 8.2, *)) {
                    localNote.alertTitle = sender.name;
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
@end
