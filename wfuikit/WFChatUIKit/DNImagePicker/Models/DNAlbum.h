//
//  DNAlbum.h
//  DNImagePicker
//
//  Created by Ding Xiao on 16/7/6.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAssetCollection;
@class PHFetchResult;

NS_ASSUME_NONNULL_BEGIN

NS_AVAILABLE_IOS(8.0) @interface DNAlbum : NSObject

+ (DNAlbum *)albumWithAssetCollection:(PHAssetCollection *)collection
                              results:(PHFetchResult *)results;

/*
 @note use this model to store the album's 'result, 'count, 'name, 'startDate
 to avoid request and reserve too much times.
 */
@property (nonatomic, strong, nullable) PHFetchResult *results;

@property (nonatomic, copy, nullable) NSString *identifier;

@property (nonatomic, copy, nullable) NSString *albumTitle;

@property (nonatomic, assign) NSInteger count;

@property (nonatomic, readonly, nullable) NSAttributedString *albumAttributedString;

- (void)fetchPostImageWithSize:(CGSize)size imageResutHandler:(void (^)(UIImage *))handler;

@end


NS_ASSUME_NONNULL_END
