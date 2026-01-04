//
//  WFCLocalization.m
//  WildFireChat
//
//  Created by WildFire Chat on 2025/01/04.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCLocalization.h"

@implementation WFCLocalization

+ (NSString *)localizedStringForKey:(NSString *)key {
    return [self localizedStringForKey:key table:nil];
}

+ (NSString *)localizedStringForKey:(NSString *)key table:(nullable NSString *)table {
    // 如果没有指定 table，使用 InfoPlist
    NSString *tableName = table ?: @"InfoPlist";

    // 优先从 mainBundle 获取（Extension 的 mainBundle 就是 Extension 的 bundle）
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *localizedString = [bundle localizedStringForKey:key
                                                         value:nil
                                                         table:tableName];

    // 如果 mainBundle 找不到且返回的是 key 本身，说明没有找到对应的本地化
    // 这种情况对于 Extension 可能是多语言文件没有被正确包含
    if (localizedString == nil || [localizedString isEqualToString:key]) {
        // 尝试直接从 bundle 中查找本地化资源
        NSArray *preferredLocalizations = [NSBundle preferredLocalizationsFromArray:@[@"zh-Hans", @"zh-Hant", @"en"]];

        for (NSString *lang in preferredLocalizations) {
            NSString *lprojPath = [bundle pathForResource:lang ofType:@"lproj"];
            if (lprojPath) {
                NSString *stringsPath = [lprojPath stringByAppendingPathComponent:@"InfoPlist.strings"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:stringsPath]) {
                    // 加载 strings 文件
                    NSDictionary *stringsDict = [NSDictionary dictionaryWithContentsOfFile:stringsPath];
                    if (stringsDict[key]) {
                        localizedString = stringsDict[key];
                        break;
                    }
                }
            }
        }
    }

    // 如果仍然找不到，返回 key 本身
    if (!localizedString || [localizedString length] == 0) {
        localizedString = key;
    }

    return localizedString;
}

+ (NSString *)localizedStringForKey:(NSString *)key arguments:(NSArray *)arguments {
    NSString *format = [self localizedStringForKey:key];

    // 使用格式化字符串
    switch (arguments.count) {
        case 0:
            return format;
        case 1: {
            NSString *arg0 = arguments[0];
            return [NSString stringWithFormat:format, arg0];
        }
        case 2: {
            NSString *arg0 = arguments[0];
            NSString *arg1 = arguments[1];
            return [NSString stringWithFormat:format, arg0, arg1];
        }
        case 3: {
            NSString *arg0 = arguments[0];
            NSString *arg1 = arguments[1];
            NSString *arg2 = arguments[2];
            return [NSString stringWithFormat:format, arg0, arg1, arg2];
        }
        default: {
            // 对于更多参数的情况，使用可变参数
            NSMutableString *result = [format mutableCopy];
            for (id arg in arguments) {
                [result replaceOccurrencesOfString:@"%@" withString:[arg description] options:0 range:NSMakeRange(0, result.length)];
            }
            return result;
        }
    }
}

@end
