//
//  DNAsset.h
//  ImagePicker
//
//  Created by DingXiao on 15/3/6.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAsset;

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE_IOS(8.0) @interface DNAsset : NSObject

@property (nonatomic, copy) NSString *assetIdentifier;
@property (nonatomic, readonly) PHAsset *asset;
@property (nonatomic, strong) UIImage *cacheImage;

+ (DNAsset *)assetWithPHAsset:(PHAsset *)asset;


@end

NS_ASSUME_NONNULL_END
