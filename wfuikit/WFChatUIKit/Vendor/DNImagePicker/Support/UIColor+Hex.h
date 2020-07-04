//
//  UIColor+Hex.h
//  imoffice
//
//  Created by zhanghao on 14-9-11.
//  Copyright (c) 2014年 IMO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *)dn_hexStringToColor:(NSString *)stringToConvert;
+ (UIColor *)dn_colorWithHexNumber:(NSUInteger)hexColor;

@end
