//
//  DNTapDetectingImageView.h
//  ImagePicker
//
//  Created by Ding Xiao on 16/1/8.
//  Copyright © 2016年 Dennis. All rights reserved.
//  In order to avoid confilict to MWTapDetectingImageView, Simplifing it to this class

#import <UIKit/UIKit.h>

@protocol DNTapDetectingImageViewDelegate <NSObject>

@optional

- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView tripleTapDetected:(UITouch *)touch;

@end

@interface DNTapDetectingImageView : UIImageView
@property (nonatomic, weak) id <DNTapDetectingImageViewDelegate> tapDelegate;
@end
