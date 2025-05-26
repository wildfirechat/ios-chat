//
//  WFCCDictionary.h
//  WFChatClient
//
//  Created by Rain on 26/5/2025.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCDictionary : NSObject
+ (WFCCDictionary *)fromData:(NSData *)data error:(NSError **)error;
+ (WFCCDictionary *)fromString:(NSString *)str error:(NSError **)error;
+ (WFCCDictionary *)fromDictionary:(NSDictionary *)dictionary;

- (id)objectForKeyedSubscript:(id)key;
@end

NS_ASSUME_NONNULL_END
