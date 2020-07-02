//
//  UIViewController+DNImagePicker.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger, DNImagePickerNavigationBarPosition) {
    DNImagePickerNavigationBarPositionLeft,
    DNImagePickerNavigationBarPositionRight
};


@interface UIViewController (DNImagePicker)

/**
 *  根据image创建导航栏左右item
 *
 *  @param position       左右位置
 *  @param normalImage    normal状态image
 *  @param highlightImage highlight状态image
 *  @param action         动作
 */
- (void)createBarButtonItemAtPosition:(DNImagePickerNavigationBarPosition)position
                    statusNormalImage:(UIImage *)normalImage
                 statusHighlightImage:(UIImage *)highlightImage
                               action:(SEL)action;

/**
 *  根据文本创建导航栏左右item
 *
 *  @param position 左右位置
 *  @param text     文本
 *  @param action   动作
 */
- (void)createBarButtonItemAtPosition:(DNImagePickerNavigationBarPosition)position
                                 text:(NSString *)text
                               action:(SEL)action;

/**
 *  根据image创建导航栏左item
 *
 *  @param normalImage    normal状态image
 *  @param highlightImage highlight状态image
 *  @param title  返回按钮title
 *  @param action         动作
 */
- (void)createBackBarButtonItemStatusNormalImage:(UIImage *)normalImage
                            statusHighlightImage:(UIImage *)highlightImage
                                       withTitle:(NSString *)title
                                          action:(SEL)action;


@end
