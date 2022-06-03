//
//  WFCCJsonSerializer.m
//  WFChatClient
//
//  Created by Rain on 2022/5/31.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCCJsonSerializer.h"

@implementation WFCCJsonSerializer
- (id)toJsonObj {
    return nil;
}

- (void)setDict:(NSMutableDictionary *)dict key:(NSString *)key longlongValue:(long long)longlongValue {
    if (longlongValue > 9007199254740991LL) {
        dict[key] = [NSString stringWithFormat:@"%lldL", longlongValue];
    } else {
        dict[key] = @(longlongValue);
    }
}

- (NSString *)toJsonStr {
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:[self toJsonObj] options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
}
@end
