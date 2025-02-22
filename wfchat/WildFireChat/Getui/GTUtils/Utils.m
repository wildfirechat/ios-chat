//
//  Utils.m
//  GtSdkDemo
//
//  Created by ak on 2020/03/20.
//  Copyright © 2019 Gexin Interactive (Beijing) Network Technology Co.,LTD. All rights reserved.
//
#if USE_GETUI_PUSH
#import "Utils.h"
#import "AppDelegate.h"
#import <GTSDK/GeTuiSdk.h>

@implementation Utils

+ (void)AlertControllerWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alertController  dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertController addAction:sureAction];
    if ([[[UIApplication sharedApplication] delegate] isKindOfClass:[AppDelegate class]]) {
        AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
//        [delegate.homePage presentViewController:alertController animated:YES completion:nil];
    }
}

+ (BOOL)PushModel {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"OffPushMode"];
}
+ (void)SetPushModel:(BOOL)mode {
    [[NSUserDefaults standardUserDefaults] setBool:mode forKey:@"OffPushMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (NSString *)getHexStringForData:(NSData *)data {
    NSUInteger len = [data length];
    char *chars = (char *) [data bytes];
    NSMutableString *hexString = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < len; i++) {
        [hexString appendString:[NSString stringWithFormat:@"%0.2hhx", chars[i]]];
    }
    return hexString;
}

/// 时间转字符串
+ (NSString *)formateTime:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}

+ (void)pushLocalNotification:(NSString *)title userInfo:(NSDictionary *)userInfo {
    /*本地通知无法触发通知扩展， 官网文档：
     A UNNotificationServiceExtension object provides the entry point for a Notification Service app extension, which lets you customize the content of a remote notification before it is delivered to the user.
     */
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = title;
    content.body = title;
    content.userInfo = userInfo;
    UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"id1" content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"addNotificationRequest added");
    }];
}

@end
#endif
