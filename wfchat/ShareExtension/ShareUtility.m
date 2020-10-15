//
//  ShareUtility.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/8.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ShareUtility.h"
#import "SharePredefine.h"

@implementation ShareUtility
+ (CGSize)imageScaleSize:(CGSize)imageSize targetSize:(CGSize)targetSize thumbnailPoint:(CGPoint *)thumbnailPoint {
    
    if (imageSize.width == 0 && imageSize.height == 0) {
        return targetSize;
    }
    
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = 0.0;
    CGFloat scaledHeight = 0.0;
    
    if (imageWidth/imageHeight < 2.4 && imageHeight/imageWidth < 2.4) {
        CGFloat widthFactor = targetWidth / imageWidth;
        CGFloat heightFactor = targetHeight / imageHeight;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        scaledWidth = imageWidth * scaleFactor;
        scaledHeight = imageHeight * scaleFactor;
        
        if (widthFactor > heightFactor) {
            if (thumbnailPoint) {
                thumbnailPoint->y = (targetHeight - scaledHeight) * 0.5;
            }
        } else if (widthFactor < heightFactor) {
            if (thumbnailPoint) {
                thumbnailPoint->x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    } else {
        if(imageWidth/imageHeight > 2.4) {
            scaleFactor = 100 * targetHeight / imageHeight / 240;
        } else {
            scaleFactor = 100 * targetWidth / imageWidth / 240;
        }
        scaledWidth = imageWidth * scaleFactor;
        scaledHeight = imageHeight * scaleFactor;
    }
    return CGSizeMake(scaledWidth, scaledHeight);
}

+ (UIImage *)generateThumbnail:(UIImage *)image
                     withWidth:(CGFloat)targetWidth
                    withHeight:(CGFloat)targetHeight {
    UIImage *targetImage = nil;
    
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    CGSize targetSize = [ShareUtility imageScaleSize:image.size targetSize:CGSizeMake(targetWidth, targetHeight) thumbnailPoint:&thumbnailPoint];
    
    CGFloat scaledWidth = targetSize.width;
    CGFloat scaledHeight = targetSize.height;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    UIGraphicsBeginImageContext(CGSizeMake(scaledWidth, scaledHeight));
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    [image drawInRect:thumbnailRect];
    
    targetImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(imageWidth/imageHeight > 2.4) {
        CGRect rect = CGRectZero;
        rect.origin.x = ( targetImage.size.width - 240)/2;
        rect.size.width = 240;
        rect.origin.y = 0;
        rect.size.height =  targetImage.size.height;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([ targetImage CGImage], rect);
        targetImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    } else if(imageHeight/imageWidth > 2.4) {
        CGRect rect = CGRectZero;
        rect.origin.y = ( targetImage.size.height - 240)/2;
        rect.size.height = 240;
        rect.origin.x = 0;
        rect.size.width =  targetImage.size.width;
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([ targetImage CGImage], rect);
        targetImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    if ( targetImage == nil)
        NSLog(@"could not scale image");
    
    UIGraphicsEndImageContext();
    return  targetImage;
    
}

+ (NSURL *)getSavedGroupGridPortrait:(NSString *)groupId {
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:WFC_SHARE_APP_GROUP_ID];
    NSURL *portraitURL = [groupURL URLByAppendingPathComponent:WFC_SHARE_BACKUPED_GROUP_GRID_PORTRAIT_PATH];
    NSURL *fileURL = [portraitURL URLByAppendingPathComponent:groupId];
    
    return fileURL;
}

@end
