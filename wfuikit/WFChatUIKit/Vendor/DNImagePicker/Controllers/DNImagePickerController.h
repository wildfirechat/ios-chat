//
//  DNImagePickerController.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ALAssetsLibrary;
@class ALAssetsFilter;
FOUNDATION_EXTERN NSString *kDNImagePickerStoredGroupKey;
typedef NS_ENUM(NSUInteger, DNImagePickerFilterType) {
    DNImagePickerFilterTypeNone,
    DNImagePickerFilterTypePhotos,
    DNImagePickerFilterTypeVideos,
};



@class DNImagePickerController;
@protocol DNImagePickerControllerDelegate <NSObject>
@optional
/**
 *  imagePickerController‘s seleted photos
 *
 *  @param imagePicker picker
 *  @param images           the seleted photos
 *  @param fullImage             if the value is yes, the seleted photos is full image
 */
- (void)dnImagePickerController:(DNImagePickerController *)imagePicker
                     sendImages:(NSArray *)images
                    isFullImage:(BOOL)fullImage;

- (void)dnImagePickerControllerDidCancel:(DNImagePickerController *)imagePicker;
@end


@interface DNImagePickerController : UINavigationController

@property (nonatomic, assign) DNImagePickerFilterType filterType;
@property (nonatomic, weak) id<DNImagePickerControllerDelegate> imagePickerDelegate;

//@property (nonatomic, readonly) ALAssetsLibrary *assetsLibrary;

@end
