//
//  UIImage+ERCategory.h
//  ErHuDemo
//
//  Created by 胡广宇 on 2017/7/11.
//  Copyright © 2017年 胡广宇. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ERCategory)

//通过颜色生成一张图片
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;
//给图片切割圆角
+ (UIImage *)setCornerWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius;
//根据颜色生成一张带圆角的图片
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;
@end
