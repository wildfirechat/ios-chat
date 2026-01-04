//
//  ShareLocalizationHelper.h
//  ShareExtension
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ShareExtension 专用的简单多语言帮助类
 * 直接在代码中定义多语言字典，避免依赖 .strings 文件
 */
@interface ShareLocalizationHelper : NSObject

/**
 * 获取本地化字符串
 * @param key 字符串的键
 * @return 本地化后的字符串
 */
+ (NSString *)localizedStringForKey:(NSString *)key;

@end

// 简化的宏定义
#define ShareLocalizedString(key) [ShareLocalizationHelper localizedStringForKey:key]

NS_ASSUME_NONNULL_END
