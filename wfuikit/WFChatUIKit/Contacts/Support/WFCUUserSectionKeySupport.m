//
//  WFCUUserSectionKeySupport.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUUserSectionKeySupport.h"
#import "pinyin.h"
#import "WFCUSelectedUserInfo.h"
static NSMutableDictionary *hanziStringDictory = nil;

@implementation WFCUUserSectionKeySupport
+ (NSMutableDictionary *)userSectionKeys:(NSArray *)userList {
    if (!userList)
        return nil;
    NSArray *_keys = @[
                       @"A",
                       @"B",
                       @"C",
                       @"D",
                       @"E",
                       @"F",
                       @"G",
                       @"H",
                       @"I",
                       @"J",
                       @"K",
                       @"L",
                       @"M",
                       @"N",
                       @"O",
                       @"P",
                       @"Q",
                       @"R",
                       @"S",
                       @"T",
                       @"U",
                       @"V",
                       @"W",
                       @"X",
                       @"Y",
                       @"Z",
                       @"#"
                       ];
    
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *_tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;
    NSMutableDictionary *firstLetterDict = [[NSMutableDictionary alloc] init];
    for (NSString *key in _keys) {
        if ([_tempOtherArr count]) {
            isReturn = YES;
        }
        NSMutableArray *tempArr = [NSMutableArray new];
        for (id user in userList) {
            NSString *firstLetter;

            WFCCUserInfo *userInfo = (WFCCUserInfo*)user;
            NSString *userName = userInfo.displayName;
            if (userInfo.friendAlias.length) {
                userName = userInfo.friendAlias;
            }
            if (userName.length == 0) {
                userInfo.displayName = [NSString stringWithFormat:@"<%@>", userInfo.userId];
                userName = userInfo.displayName;
            }
            
            firstLetter = [firstLetterDict objectForKey:userName];
            if (!firstLetter) {
                firstLetter = [self getFirstUpperLetter:userName];
                [firstLetterDict setObject:firstLetter forKey:userName];
            }
            
            
        
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }
            
            if (isReturn)
                continue;
            char c = [firstLetter characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [infoDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [infoDic setObject:_tempOtherArr forKey:@"#"];
    
    NSArray *keys = [[infoDic allKeys]
                     sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                         
                         return [obj1 compare:obj2 options:NSNumericSearch];
                     }];
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:keys];
    if ([allKeys containsObject:@"#"]) {
        [allKeys removeObject:@"#"];
        [allKeys insertObject:@"#" atIndex:allKeys.count];
    }
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:allKeys forKey:@"allKeys"];
    [infoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray *_tempOtherArr = (NSMutableArray *)obj;
        [_tempOtherArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            WFCUSelectedUserInfo *user1 = (WFCUSelectedUserInfo *)obj1;
            WFCUSelectedUserInfo *user2 = (WFCUSelectedUserInfo *)obj2;
            NSString *user1Pinyin = [[self class] hanZiToPinYinWithString:user1.displayName];
            NSString *user2Pinyin = [[self class] hanZiToPinYinWithString:user2.displayName];
            return [user1Pinyin compare:user2Pinyin];
        }];
    }];
    return resultDic;
}

+ (NSString *)getFirstUpperLetter:(NSString *)hanzi {
    NSString *pinyin = [self hanZiToPinYinWithString:hanzi];
    NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
    if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
        [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
        return firstUpperLetter;
    } else {
        return @"#";
    }
}

+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    if (!hanziStringDictory) {
        hanziStringDictory = [[NSMutableDictionary alloc] init];
    }
    
    NSString *pinYinResult = [hanziStringDictory objectForKey:hanZi];
    if (pinYinResult) {
        return pinYinResult;
    }
    pinYinResult = [NSString string];
    for (int j = 0; j < hanZi.length; j++) {
        NSString *singlePinyinLetter = nil;
        if ([self isChinese:[hanZi substringWithRange:NSMakeRange(j, 1)]]) {
            singlePinyinLetter = [[NSString
                                   stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])]
                                  uppercaseString];
        }else{
            singlePinyinLetter = [hanZi substringWithRange:NSMakeRange(j, 1)];
        }
        
        pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
    }
    [hanziStringDictory setObject:pinYinResult forKey:hanZi];
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}
@end
