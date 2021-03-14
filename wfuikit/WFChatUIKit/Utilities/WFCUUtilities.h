//
//  Utilities.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUUtilities : NSObject
+ (CGSize)getTextDrawingSize:(NSString *)text
                        font:(UIFont *)font
             constrainedSize:(CGSize)constrainedSize;
+ (NSString *)formatTimeLabel:(int64_t)timestamp;
+ (NSString *)formatTimeDetailLabel:(int64_t)timestamp;
+ (UIImage *)thumbnailWithImage:(UIImage *)originalImage maxSize:(CGSize)size;
+ (NSString *)formatSizeLable:(int64_t)size;
+ (UIImage *)imageForExt:(NSString *)extName;
+ (NSString *)getUnduplicatedPath:(NSString *)path;
+ (BOOL)isFileExist:(NSString *)filePath;
@end
