//
//  ShareLocalizationHelper.m
//  ShareExtension
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "ShareLocalizationHelper.h"
#import "SharePredefine.h"

@implementation ShareLocalizationHelper

+ (NSString *)currentLanguage {
    // 优先从 App Group 的共享 UserDefaults 读取主应用设置的语言
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];
    NSArray *languages = [sharedDefaults objectForKey:@"AppleLanguages"];

    if (languages && languages.count > 0) {
        return languages[0];
    }

    // 如果共享 UserDefaults 中没有，则使用标准 UserDefaults
    languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    if (languages && languages.count > 0) {
        return languages[0];
    }

    // 最后使用系统首选语言
    return [NSLocale preferredLanguages].firstObject;
}

+ (NSDictionary *)localizedStrings {
    static NSDictionary *strings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strings = @{
            // 简体中文
            @"zh-Hans": @{
                @"ConfirmSendTo": @"确认发送给",
                @"Sending": @"正在发送中...",
                @"NotSupportMultiImages": @"不支持发送多张图片",
                @"NotSupportMultiImagesMessage": @"每次只能发送一张。如果您需要一次发送多张，请打开野火IM选择图片发送。",
                @"Sent": @"已发送",
                @"ViewInWildFire": @"您可以在野火IM中查看",
                @"NetworkError": @"网络错误",
                @"NetworkErrorTitle": @"网络错误",
                @"NetworkErrorMessage": @"糟糕！网络出问题了！",
                @"ForgetIt": @"算了吧",
                @"SendToFriend": @"发给朋友",
                @"SendToSelf": @"发给自己",
                @"ShareToMoments": @"分享到朋友圈",
                @"Self": @"自己",
                @"Image": @"[图片]",
                @"ServerResponseError": @"服务器响应错误",
                @"UploadFailed": @"上传失败：%@",
                @"NotLoggedIn": @"未登录",
                @"PleaseLoginWildFireIM": @"请先登录野火IM",
                @"Cancel": @"取消",
                @"Confirm": @"确定",
            },
            // 繁体中文
            @"zh-Hant": @{
                @"ConfirmSendTo": @"確認發送給",
                @"Sending": @"正在發送中...",
                @"NotSupportMultiImages": @"不支持發送多張圖片",
                @"NotSupportMultiImagesMessage": @"每次只能發送一張。如果您需要一次發送多張，請打開野火IM選擇圖片發送。",
                @"Sent": @"已發送",
                @"ViewInWildFire": @"您可以在野火IM中查看",
                @"NetworkError": @"網絡錯誤",
                @"NetworkErrorTitle": @"網絡錯誤",
                @"NetworkErrorMessage": @"糟糕！網絡出問題了！",
                @"ForgetIt": @"算了吧",
                @"SendToFriend": @"發給朋友",
                @"SendToSelf": @"發給自己",
                @"ShareToMoments": @"分享到朋友圈",
                @"Self": @"自己",
                @"Image": @"[圖片]",
                @"ServerResponseError": @"服務器響應錯誤",
                @"UploadFailed": @"上傳失敗：%@",
                @"NotLoggedIn": @"未登錄",
                @"PleaseLoginWildFireIM": @"請先登錄野火IM",
                @"Cancel": @"取消",
                @"Confirm": @"確定",
            },
            // 英文
            @"en": @{
                @"ConfirmSendTo": @"Confirm send to",
                @"Sending": @"Sending...",
                @"NotSupportMultiImages": @"Multiple images not supported",
                @"NotSupportMultiImagesMessage": @"Only one image at a time. If you need to send multiple images, please open WildFire IM and select images to send.",
                @"Sent": @"Sent",
                @"ViewInWildFire": @"You can view it in WildFire IM",
                @"NetworkError": @"Network Error",
                @"NetworkErrorTitle": @"Network Error",
                @"NetworkErrorMessage": @"Oops! Network problem!",
                @"ForgetIt": @"Forget it",
                @"SendToFriend": @"Send to Friend",
                @"SendToSelf": @"Send to Self",
                @"ShareToMoments": @"Share to Moments",
                @"Self": @"Self",
                @"Image": @"[Image]",
                @"ServerResponseError": @"Server response error",
                @"UploadFailed": @"Upload failed: %@",
                @"NotLoggedIn": @"Not logged in",
                @"PleaseLoginWildFireIM": @"Please login to WildFire IM first",
                @"Cancel": @"Cancel",
                @"Confirm": @"Confirm",
            }
        };
    });
    return strings;
}

+ (NSString *)localizedStringForKey:(NSString *)key {
    NSString *currentLang = [self currentLanguage];
    NSDictionary *langDict = [self localizedStrings];

    // 尝试精确匹配
    NSDictionary *strings = langDict[currentLang];
    if (!strings) {
        // 尝试匹配语言前缀（如 zh-Hans-CN -> zh-Hans）
        NSString *langPrefix = [currentLang componentsSeparatedByString:@"-"].firstObject;
        for (NSString *langKey in langDict.allKeys) {
            if ([langKey hasPrefix:langPrefix]) {
                strings = langDict[langKey];
                break;
            }
        }
    }

    // 如果还是找不到，使用英文作为默认
    if (!strings) {
        strings = langDict[@"en"];
    }

    NSString *value = strings[key];
    return value ?: key;
}

@end
