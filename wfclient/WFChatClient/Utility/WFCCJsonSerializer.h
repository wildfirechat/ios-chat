//
//  WFCCJsonSerializer.h
//  WFChatClient
//
//  Created by Rain on 2022/5/31.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCJsonSerializer : NSObject
//子类需要实现此方法
- (id)toJsonObj;

//子类不要实现此方法
- (NSString *)toJsonStr;
- (void)setDict:(NSMutableDictionary *)dict key:(NSString *)key longlongValue:(long long)longValue;
@end

NS_ASSUME_NONNULL_END
