//
//  WFCCUtilities.m
//  WFChatClient
//
//  Created by heavyrain on 2017/9/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCUtilities.h"

@implementation WFCCUtilities
+ (UIImage *)generateThumbnail:(UIImage *)image
                     withWidth:(CGFloat)targetWidth
                    withHeight:(CGFloat)targetHeight {
    UIImage *targetImage = nil;
    CGSize imageSize = image.size;
    CGFloat imageWidth = imageSize.width;
    CGFloat imageHeight = imageSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = 0.0;
    CGFloat scaledHeight = 0.0;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
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
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
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
+ (NSString *)getSendBoxFilePath:(NSString *)localPath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
        return localPath;
    } else {
        NSUInteger location = [localPath rangeOfString:@"Containers/Data/Application/"].location;
        if (location != NSNotFound) {
            location =
                MIN(MIN([localPath rangeOfString:@"Documents" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location,
                    [localPath rangeOfString:@"Library" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location),
                [localPath rangeOfString:@"tmp" options:NSCaseInsensitiveSearch range:NSMakeRange(location, localPath.length - location)].location);
        }
        
        if (location != NSNotFound) {
            NSString *relativePath = [localPath substringFromIndex:location];
            return [NSHomeDirectory() stringByAppendingPathComponent:relativePath];
        } else {
            return localPath;
        }
    }
}

+ (NSString *)getDocumentPathWithComponent:(NSString *)componentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *path = [documentDirectory stringByAppendingPathComponent:componentPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

@end
