//
//  DNImageFetchOperation.h
//  DNImagePicker
//
//  Created by dingxiao on 2018/10/9.
//  Copyright © 2018 Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class PHAsset;

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE_IOS(8.0) @interface DNImageFetchOperation : NSOperation

@property (nonatomic, strong, nullable) PHAsset *asset;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

- (instancetype)initWithAsset:(PHAsset *)asset;

- (void)fetchImageWithTargetSize:(CGSize)size
                 needHighQuality:(BOOL)isHighQuality
               imageResutHandler:(void (^)(UIImage * image))handler;

@end

NS_ASSUME_NONNULL_END
