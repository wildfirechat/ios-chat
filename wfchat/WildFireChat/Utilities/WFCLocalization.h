//
//  WFCLocalization.h
//  WildFireChat
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 共享的多语言工具类
 * 主项目和 ShareExtension 都可以使用此类来获取本地化字符串
 */
@interface WFCLocalization : NSObject

/**
 * 获取本地化字符串
 * @param key 字符串的键
 * @return 本地化后的字符串
 */
+ (NSString *)localizedStringForKey:(NSString *)key;

/**
 * 获取本地化字符串（带格式化参数）
 * @param key 字符串的键
 * @param arguments 格式化参数
 * @return 本地化并格式化后的字符串
 */
+ (NSString *)localizedStringForKey:(NSString *)key arguments:(NSArray *)arguments;

@end

// 为了兼容性，定义一个宏
#define WLocalizedString(key) [WFCLocalization localizedStringForKey:key]

NS_ASSUME_NONNULL_END
