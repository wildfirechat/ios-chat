//
//  XLPageViewControllerUtil.h
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/8.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController
//  工具类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XLPageViewControllerConfig.h"

NS_ASSUME_NONNULL_BEGIN

//------------------------------CUT------------------------------

@interface XLPageViewControllerUtil : NSObject

//文字宽度
+ (CGFloat)widthForText:(NSString *)text font:(UIFont *)font size:(CGSize)size;

//颜色过渡
+ (UIColor *)colorTransformFrom:(UIColor*)fromColor to:(UIColor *)toColor progress:(CGFloat)progress;

//执行阴影动画
+ (void)showAnimationToShadow:(UIView *)shadow shadowWidth:(CGFloat)shadowWidth fromItemRect:(CGRect)fromItemRect toItemRect:(CGRect)toItemRect type:(XLPageShadowLineAnimationType)type progress:(CGFloat)progress;

@end

//------------------------------CUT------------------------------
/**
 兼容子view滚动，添加"让我先滚"属性
 */
@interface UIView (LetMeScroll)

/**
 让我先滚 默认 NO
 */
@property (nonatomic, assign) BOOL xl_letMeScrollFirst;

@end

//------------------------------CUT------------------------------
/**
 子视图控制器的缓存，添加扩展标题
 */
@interface UIViewController (Title)

/**
 添加扩展标题
 */
@property (nonatomic, copy) NSString *xl_title;

@end


//------------------------------CUT------------------------------

typedef BOOL(^XLOtherGestureRecognizerBlock)(UIGestureRecognizer *otherGestureRecognizer);

@interface UIScrollView (GestureRecognizer)<UIGestureRecognizerDelegate>

@property (nonatomic, copy) XLOtherGestureRecognizerBlock xl_otherGestureRecognizerBlock;

@end

NS_ASSUME_NONNULL_END
