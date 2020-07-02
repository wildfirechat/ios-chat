//
//  DNImagePickerHelper.h
//  DNImagePicker
//
//  Created by Ding Xiao on 16/8/23.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DNAlbumAuthorizationStatus) {
    // User has not yet made a choice with regards to this application
    DNAlbumAuthorizationStatusNotDetermined = 0,
    // This application is not authorized to access photo data.
    // The user cannot change this application’s status, possibly due to active restrictions
    // such as parental controls being in place.
    DNAlbumAuthorizationStatusRestricted,
    // User has explicitly denied this application access to photos data.
    DNAlbumAuthorizationStatusDenied,
    // User has authorized this application to access photos data.
    DNAlbumAuthorizationStatusAuthorized
};

typedef NS_ENUM(NSUInteger, DNImagePickerFitlerType) {
    DNImagePickerFitlerTypeUnknown = 0,
    DNImagePickerFitlerTypeImage   = 1,
    DNImagePickerFitlerTypeVideo   = 2,
    DNImagePickerFitlerTypeAudio   = 3,
};


@class DNAlbum;
@class DNAsset;

NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXTERN NSString * const DNImagePickerPhotoLibraryChangedNotification;
NS_CLASS_AVAILABLE_IOS(8.0) @interface DNImagePickerHelper : NSObject

+ (instancetype)sharedHelper;


+ (void)cancelFetchWithAssets:(DNAsset *)asset;

/**
 *  Returns information about your app’s authorization for accessing the user’s Photos library.
 The current authorization status. See `DNAlbumAuthorizationStatus`.
 *
 *  @return The current authorization status.
 */
+ (DNAlbumAuthorizationStatus)authorizationStatus;

/**
 *  Fetch the albumlist
 *
 */
+ (void)requestAlbumListWithCompleteHandler:(void(^)(NSArray<DNAlbum *>* anblumList))competeHandler;

/**
 *  Fetch the album which is stored by identifier; if not stored, it'll return the album without anything.
 *
 *  @return the stored album
 */
+ (void)requestCurrentAblumWithCompleteHandler:(void(^)(DNAlbum * album))completeHandler;


/**
 fetch images in the specific ablum
 
 @param album target album
 @param completeHandler callbacks with imageArray
 */
+ (void)fetchImageAssetsInAlbum:(DNAlbum *)album completeHandler:(void(^)(NSArray<DNAsset *>* imageArray))completeHandler;


+ (void)fetchImageSizeWithAsset:(DNAsset *)asset
         imageSizeResultHandler:(void (^)(CGFloat imageSize, NSString * sizeString))handler;


/**
 fetch Image with assets
 
 @param asset target assets
 @param targetSize target size
 @param isHighQuality is need highQuality
 @param handler callback with image
 */
+ (void)fetchImageWithAsset:(DNAsset *)asset
                 targetSize:(CGSize)targetSize
            needHighQuality:(BOOL)isHighQuality
          imageResutHandler:(void (^)(UIImage * image))handler;
/**
 fetch Image with assets
 same as `fetchImageWithAsset:targetSize:needHighQuality:imageResutHandler:` param `isHighQuality` is NO
 */
+ (void)fetchImageWithAsset:(DNAsset *)asset
                 targetSize:(CGSize)targetSize
          imageResutHandler:(void (^)(UIImage *))handler;

// storeage
+ (void)saveAblumIdentifier:(NSString *)identifier;

+ (NSString *)albumIdentifier;


@end
NS_ASSUME_NONNULL_END
