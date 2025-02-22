//
//  Utils.h
//  GtSdkDemo
//
//  Created by ak on 2020/03/20.
//  Copyright © 2019 Gexin Interactive (Beijing) Network Technology Co.,LTD. All rights reserved.
//
#if USE_GETUI_PUSH
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (void)AlertControllerWithTitle:(NSString *)title andMessage:(NSString *)message;
+ (BOOL)PushModel;
+ (void)SetPushModel:(BOOL)mode;

+ (NSString *)getHexStringForData:(NSData *)data;
+ (NSString *)formateTime:(NSDate *)date;
+ (void)pushLocalNotification:(NSString *)title userInfo:(NSDictionary *)userInfo;
@end

NS_ASSUME_NONNULL_END
#endif
