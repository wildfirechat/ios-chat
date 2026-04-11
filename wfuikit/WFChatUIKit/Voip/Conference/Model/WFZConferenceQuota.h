//
//  WFZConferenceQuota.h
//  WFChatUIKit
//
//  Created by WildFireChat on 2025/4/11.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFZConferenceQuota : NSObject

// 用户月度额度（分钟）
@property (nonatomic, assign) int totalQuota;

// 当月已使用额度（分钟）
@property (nonatomic, assign) int usedMinutes;

// 当月剩余额度（分钟）
@property (nonatomic, assign) int remainingMinutes;

// 是否不限制（true表示无额度限制）
@property (nonatomic, assign) BOOL unlimited;

// 当前年月（yyyyMM格式）
@property (nonatomic, strong) NSString *yearMonth;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
