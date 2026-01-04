//
//  WFCLanguageManager.h
//  WildFireChat
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WFCLanguageType) {
    WFCLanguageTypeSystem = 0,  // 跟随系统
    WFCLanguageTypeSimplifiedChinese = 1,  // 简体中文
    WFCLanguageTypeEnglish = 2,  // 英文
    WFCLanguageTypeTraditionalChinese = 3  // 繁体中文
};

@interface WFCLanguageManager : NSObject

@property (nonatomic, assign) WFCLanguageType currentLanguage;

+ (instancetype)sharedManager;

// 获取当前语言类型
- (WFCLanguageType)getCurrentLanguage;

// 设置语言类型
- (void)setLanguage:(WFCLanguageType)language;

// 获取当前语言代码（用于设置 AppleLanguages）
- (NSString *)getLanguageCode;

// 获取语言显示名称
- (NSString *)getLanguageDisplayName:(WFCLanguageType)language;

// 切换语言并刷新界面
- (void)switchLanguage:(WFCLanguageType)language completion:(void (^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
