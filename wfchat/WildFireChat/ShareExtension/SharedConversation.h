//
//  SharedConversation.h
//  WildFireChat
//
//  Created by Tom Lee on 2020/10/6.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SharedConversation : NSObject <NSSecureCoding>
@property(nonatomic, assign)int type;
@property(nonatomic, strong)NSString *target;
@property(nonatomic, assign)int line;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, strong)NSString *portraitUrl;
+ (instancetype)from:(int)type target:(NSString *)target line:(int)line;
@end

NS_ASSUME_NONNULL_END
