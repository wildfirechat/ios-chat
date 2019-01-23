//
//  KZVideoViewController.h
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/18.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZVideoConfig.h"
@protocol KZVideoViewControllerDelegate;

// 主类  更多自定义..修改KZVideoConfig.h里面的define
@interface KZVideoViewController : NSObject

@property (nonatomic, strong, readonly) UIView *view;

@property (nonatomic, strong, readonly) UIView *actionView;

//保存到相册
@property (nonatomic, assign) BOOL savePhotoAlbum;

@property (nonatomic, assign) id<KZVideoViewControllerDelegate> delegate;

- (void)startAnimationWithType:(KZVideoViewShowType)showType selectExist:(BOOL)selectExist;

//- (void)endAniamtion;

@end

@protocol KZVideoViewControllerDelegate <NSObject>

@required
- (void)videoViewController:(KZVideoViewController *)videoController didCaptureImage:(UIImage *)image;

- (void)videoViewController:(KZVideoViewController *)videoController didRecordVideo:(KZVideoModel *)videoModel;

@optional
- (void)videoViewControllerDidCancel:(KZVideoViewController *)videoController;

@end
