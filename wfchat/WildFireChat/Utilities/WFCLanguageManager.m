//
//  WFCLanguageManager.m
//  WildFireChat
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCLanguageManager.h"
#import "SharePredefine.h"

static NSString *const kWFCLanguageKey = @"WFCLanguageKey";

@implementation WFCLanguageManager

+ (instancetype)sharedManager {
    static WFCLanguageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 从 UserDefaults 读取保存的语言设置
        NSInteger savedLanguage = [[NSUserDefaults standardUserDefaults] integerForKey:kWFCLanguageKey];
        _currentLanguage = (WFCLanguageType)savedLanguage;
    }
    return self;
}

- (WFCLanguageType)getCurrentLanguage {
    return self.currentLanguage;
}

- (void)setLanguage:(WFCLanguageType)language {
    self.currentLanguage = language;
    [[NSUserDefaults standardUserDefaults] setInteger:language forKey:kWFCLanguageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)getLanguageCode {
    switch (self.currentLanguage) {
        case WFCLanguageTypeSimplifiedChinese:
            return @"zh-Hans";
        case WFCLanguageTypeEnglish:
            return @"en";
        case WFCLanguageTypeTraditionalChinese:
            return @"zh-Hant";
        case WFCLanguageTypeSystem:
        default:
            // 返回 nil 表示使用系统语言
            return nil;
    }
}

- (NSString *)getLanguageDisplayName:(WFCLanguageType)language {
    switch (language) {
        case WFCLanguageTypeSystem:
            return NSLocalizedStringFromTable(@"FollowSystem", @"InfoPlist", nil);
        case WFCLanguageTypeSimplifiedChinese:
            return @"简体中文";
        case WFCLanguageTypeEnglish:
            return @"English";
        case WFCLanguageTypeTraditionalChinese:
            return @"繁體中文";
        default:
            return NSLocalizedStringFromTable(@"FollowSystem", @"InfoPlist", nil);
    }
}

- (void)switchLanguage:(WFCLanguageType)language completion:(void (^)(void))completion {
    [self setLanguage:language];

    NSString *languageCode = [self getLanguageCode];
    NSArray *languages = nil;

    if (languageCode) {
        languages = @[languageCode];
    } else {
        // 如果是跟随系统，清除设置
        languages = nil;
    }

    // 调试日志
    NSLog(@"[WFCLanguageManager] Switching to language type: %ld, code: %@", (long)language, languageCode);
    NSLog(@"[WFCLanguageManager] Setting AppleLanguages to: %@", languages);

    // 保存到标准 UserDefaults
    if (languages) {
        [[NSUserDefaults standardUserDefaults] setObject:languages forKey:@"AppleLanguages"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"AppleLanguages"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    // 同时保存到 App Group 的共享 UserDefaults，供 ShareExtension 使用
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];
    if (sharedDefaults) {
        [sharedDefaults setObject:languages forKey:@"AppleLanguages"];
        [sharedDefaults synchronize];
        NSLog(@"[WFCLanguageManager] Saved to shared UserDefaults");
    } else {
        NSLog(@"[WFCLanguageManager] WARNING: Shared UserDefaults not available!");
    }

    // 验证保存是否成功
    NSArray *savedLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSLog(@"[WFCLanguageManager] Saved AppleLanguages: %@", savedLanguages);

    // 提示用户需要重启应用
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion();
        }
    });
}

@end
