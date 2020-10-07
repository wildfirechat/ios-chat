//
//  WFCCUtilities.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCCIMService.h"

@interface WFCCUtilities : NSObject

/**
 生成缩略图

 @param image 原图
 @param targetWidth 宽度
 @param targetHeight 高度
 @return 缩略图
 */
+ (UIImage *)generateThumbnail:(UIImage *)image
                     withWidth:(CGFloat)targetWidth
                    withHeight:(CGFloat)targetHeight;


/**
 获取对应的沙盒路径

 @param localPath 文件路径
 @return 对应的沙盒路径
 */
+ (NSString *)getSendBoxFilePath:(NSString *)localPath;

/**
 获取资源路径

 @param componentPath 相对路径
 @return 资源路径
 */
+ (NSString *)getDocumentPathWithComponent:(NSString *)componentPath;

+ (CGSize)imageScaleSize:(CGSize)imageSize targetSize:(CGSize)targetSize thumbnailPoint:(CGPoint *)thumbnailPoint;


+ (UIImage *)imageWithRightOrientation:(UIImage *)aImage;

+ (NSString *)getGroupGridPortrait:(NSString *)groupId
                             width:(int)width
                generateIfNotExist:(BOOL)generateIfNotExist
               defaultUserPortrait:(UIImage *(^)(NSString *userId))defaultUserPortraitBlock;
@end
