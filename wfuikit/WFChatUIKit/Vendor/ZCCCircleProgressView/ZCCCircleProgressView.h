//
//  ZCCCircleProgressView.h
//  MOSOBOStudent
//
//  Created by mac on 2017/10/23.
//  Copyright © 2017年 zcc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZCCCircleProgressView : UIView
@property(nonatomic, assign)CGFloat lineWidth;

//跳到进度
- (void)animateToProgress:(CGFloat)progress subProgress:(CGFloat)subProgress;
//进度为0
- (void)animateToZero;

//跳到进度
- (void)setProgress:(CGFloat)progress subProgress:(CGFloat)subProgress;
//进度为0
- (void)reset;

@end
