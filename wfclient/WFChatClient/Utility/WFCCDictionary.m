//
//  WFCCDictionary.m
//  WFChatClient
//
//  Created by Rain on 26/5/2025.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCDictionary.h"

@interface WFCCDictionary ()
@property(nonatomic, strong)NSDictionary *dict;
@end

@implementation WFCCDictionary
- (id)objectForKeyedSubscript:(id)key {
    id value = self.dict[key];
    if([value isKindOfClass:[NSNull class]]) {
        return nil;
    }
    return value;
}

+ (WFCCDictionary *)fromData:(nonnull NSData *)data error:(NSError **)error {
    if (!data) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCDictionaryErrorDomain"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Data parameter cannot be nil"}];
        }
        WFCCDictionary *ret = [[WFCCDictionary alloc] init];
        ret.dict = @{};
        return ret;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:error];
    return [self fromDictionary:dictionary];
}

+ (WFCCDictionary *)fromString:(NSString *)str error:(NSError **)error {
    return [self fromData:[str dataUsingEncoding:NSUTF8StringEncoding] error:error];
}

+ (WFCCDictionary *)fromDictionary:(NSDictionary *)dictionary {
    WFCCDictionary *ret = [[WFCCDictionary alloc] init];
    ret.dict = dictionary;
    return ret;
}

@end
