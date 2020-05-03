//
//  Device.h
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Device : NSObject
@property(nonatomic, strong)NSString *deviceId;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *token;
@property(nonatomic, strong)NSString *secret;
@property(nonatomic, strong)NSArray *owners;
@end

NS_ASSUME_NONNULL_END
