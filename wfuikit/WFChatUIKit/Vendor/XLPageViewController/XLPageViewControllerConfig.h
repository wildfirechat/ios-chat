//
//  XLPageViewControllerConfig.h
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/8.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController
//  显示配置类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 标题栏样式
 Basic 基本样式
 Segmented 分段样式
 */
typedef NS_ENUM(NSInteger, XLPageTitleViewStyle) {
    XLPageTitleViewStyleBasic = 0,
    XLPageTitleViewStyleSegmented = 1
};

/**
 标题对齐，居左，居中，局右
 */
typedef NS_ENUM(NSInteger, XLPageTitleViewAlignment) {
    XLPageTitleViewAlignmentLeft = 0,
    XLPageTitleViewAlignmentCenter = 1,
    XLPageTitleViewAlignmentRight = 2,
};

/**
 文字垂直对齐，居中，居上，局下
 */
typedef NS_ENUM(NSInteger, XLPageTextVerticalAlignment) {
    XLPageTextVerticalAlignmentCenter = 0,
    XLPageTextVerticalAlignmentTop = 1,
    XLPageTextVerticalAlignmentBottom = 2,
};

/**
 阴影末端形状，圆角、直角
 */
typedef NS_ENUM(NSInteger, XLPageShadowLineCap) {
    XLPageShadowLineCapRound = 0,
    XLPageShadowLineCapSquare = 1,
};

/**
 阴影对齐
 */
typedef NS_ENUM(NSInteger, XLPageShadowLineAlignment) {
    XLPageShadowLineAlignmentBottom = 0,
    XLPageShadowLineAlignmentCenter = 1,
    XLPageShadowLineAlignmentTop = 2,
};


/**
 阴影动画类型，平移、缩放、无动画
 */
typedef NS_ENUM(NSInteger, XLPageShadowLineAnimationType) {
    XLPageShadowLineAnimationTypePan = 0,
    XLPageShadowLineAnimationTypeZoom = 1,
    XLPageShadowLineAnimationTypeNone = 2,
};


NS_ASSUME_NONNULL_BEGIN

@interface XLPageViewControllerConfig : NSObject

/**
 标题正常颜色 默认 grayColor
 */
@property (nonatomic, strong) UIColor *titleNormalColor;

/**
 标题选中颜色 默认 blackColor
 */
@property (nonatomic, strong) UIColor *titleSelectedColor;

/**
 标题正常字体 默认 标准字体18
 */
@property (nonatomic, strong) UIFont *titleNormalFont;

/**
 标题选中字体 默认 标准粗体18
 */
@property (nonatomic, strong) UIFont *titleSelectedFont;

/**
 标题间距 默认 10
 */
@property (nonatomic, assign) CGFloat titleSpace;

/**
 标题宽度 默认 文字长度
 */
@property (nonatomic, assign) CGFloat titleWidth;

/**
 标题颜色过渡开关 默认 开
 */
@property (nonatomic, assign) BOOL titleColorTransition;

/**
 文字垂直对齐 默认居中
 */
@property (nonatomic, assign) XLPageTextVerticalAlignment textVerticalAlignment;

/**
 标题栏高度 默认 40
 */
@property (nonatomic, assign) CGFloat titleViewHeight;

/**
 标题栏背景色 默认 透明
 */
@property (nonatomic, strong) UIColor *titleViewBackgroundColor;

/**
 标题栏内容缩进 默认 UIEdgeInsetsMake(0, 10, 0, 10)
 */
@property (nonatomic, assign) UIEdgeInsets titleViewInset;

/**
 标题栏显示位置 默认 XLPageTitleViewAlignmentLeft（只在标题总长度小于屏幕宽度时有效）
 */
@property (nonatomic, assign) XLPageTitleViewAlignment titleViewAlignment;

/**
 标题栏样式 默认 XLPageTitleViewStyleBasic
 */
@property (nonatomic, assign) XLPageTitleViewStyle titleViewStyle;

/**
 是否在NavigationBar上显示标题栏 默认NO
 */
@property (nonatomic, assign) BOOL showTitleInNavigationBar;

/**
 隐藏底部阴影 默认 NO
 */
@property (nonatomic, assign) BOOL shadowLineHidden;

/**
 阴影高度 默认 3.0f
 */
@property (nonatomic, assign) CGFloat shadowLineHeight;


/**
 阴影宽度 默认 30.0f
 */
@property (nonatomic, assign) CGFloat shadowLineWidth;

/**
 阴影颜色 默认 黑色
 */
@property (nonatomic, strong) UIColor *shadowLineColor;

/**
 阴影末端形状 默认 XLPageShadowLineCapRound
 */
@property (nonatomic, assign) XLPageShadowLineCap shadowLineCap;

/**
 默认动画效果 默认 XLPageShadowLineAnimationTypePan
 */
@property (nonatomic, assign) XLPageShadowLineAnimationType shadowLineAnimationType;

/**
 阴影对齐 默认XLPageShadowLineAlignmentBottom
 */
@property (nonatomic, assign) XLPageShadowLineAlignment shadowLineAlignment;

/**
 隐藏底部分割线 默认 NO
 */
@property (nonatomic, assign) BOOL separatorLineHidden;

/**
 底部分割线高度 默认 0.5
 */
@property (nonatomic, assign) CGFloat separatorLineHeight;

/**
 底部分割线颜色 默认 lightGrayColor
 */
@property (nonatomic, strong) UIColor *separatorLineColor;

/**
 分段选择器颜色 默认 黑色
 */
@property (nonatomic, strong) UIColor *segmentedTintColor;

/**
 默认初始化方法
 */
+ (XLPageViewControllerConfig *)defaultConfig;

@end

NS_ASSUME_NONNULL_END
