//
//  ShareUtility.h
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/8.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShareUtility : NSObject
+ (UIImage *)generateThumbnail:(UIImage *)image
                     withWidth:(CGFloat)targetWidth
                    withHeight:(CGFloat)targetHeight;

+ (NSURL *)getSavedGroupGridPortrait:(NSString *)groupId;
@end

NS_ASSUME_NONNULL_END
