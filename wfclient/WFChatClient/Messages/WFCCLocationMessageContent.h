//
//  WFCCTextMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

/**
 位置消息
 */
@interface WFCCLocationMessageContent : WFCCMessageContent

/**
 构造消息

 @param coordinate 坐标值
 @param title 位置信息
 @param thumbnail 缩略图
 @return 位置消息
 */
+ (instancetype)contentWith:(CLLocationCoordinate2D) coordinate
                      title:(NSString *)title
                  thumbnail:(UIImage *)thumbnail;

/**
 位置坐标
 */
@property (nonatomic, assign)CLLocationCoordinate2D coordinate;

/**
 位置信息
 */
@property (nonatomic, strong)NSString *title;

/**
 缩略图
 */
@property (nonatomic, strong)UIImage *thumbnail;

@end
