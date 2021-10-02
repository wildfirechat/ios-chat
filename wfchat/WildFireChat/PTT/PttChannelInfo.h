//
//  PttChannelInfo.h
//  WildFireChat
//
//  Created by Tom Lee on 2021/10/1.
//  Copyright © 2021 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PttChannelInfo : NSObject
@property(nonatomic, strong)NSString *channelId;
@property(nonatomic, strong)NSString *channelTitle;
@property(nonatomic, strong)NSString *channelDesc;
@property(nonatomic, strong)NSString *password;
@property(nonatomic, strong)NSString *pin;
@property(nonatomic, strong)NSString *owner;
@property(nonatomic, assign)BOOL open;

+ (instancetype)fromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
@end

NS_ASSUME_NONNULL_END
