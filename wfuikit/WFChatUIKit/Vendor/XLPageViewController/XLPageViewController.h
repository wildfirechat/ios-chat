//
//  XLPageViewController.h
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/6.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController
//  视图分页控制器

#import <UIKit/UIKit.h>
#import "XLPageViewControllerConfig.h"
#import "XLPageViewControllerUtil.h"
#import "XLPageTitleCell.h"

@class XLPageViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol XLPageViewControllerDelegate <NSObject>

/**
 当页面切换完成时回调该方法，返回切换到的位置

 @param pageViewController 实例
 @param index 切换的位置
 */
- (void)pageViewController:(XLPageViewController *)pageViewController didSelectedAtIndex:(NSInteger)index;

@end

@protocol XLPageViewControllerDataSrouce <NSObject>

@required

/**
 根据index返回对应的ViewController

 @param pageViewController XLPageViewController实例
 @param index 当前位置
 @return 返回要展示的ViewController
 */
- (UIViewController *)pageViewController:(XLPageViewController *)pageViewController viewControllerForIndex:(NSInteger)index;

/**
 根据index返回对应的标题

 @param pageViewController XLPageViewController实例
 @param index 当前位置
 @return 返回要展示的标题
 */
- (NSString *)pageViewController:(XLPageViewController *)pageViewController titleForIndex:(NSInteger)index;

/**
 要展示分页数

 @return 返回分页数
 */
- (NSInteger)pageViewControllerNumberOfPage;

@optional

/**
 自定义cell方法
 */
- (__kindof XLPageTitleCell *)pageViewController:(XLPageViewController *)pageViewController titleViewCellForItemAtIndex:(NSInteger)index;

@end

@interface XLPageViewController : UIViewController

/**
 代理
 */
@property (nonatomic, weak) id <XLPageViewControllerDelegate> delegate;

/**
 数据源
 */
@property (nonatomic, weak) id <XLPageViewControllerDataSrouce> dataSource;

/**
 当前位置 默认是0
 */
@property (nonatomic, assign) NSInteger selectedIndex;

/**
 滚动开关 默认 开
 */
@property (nonatomic, assign) BOOL scrollEnabled;


/**
 滚动到边缘自动回弹 默认 开
 */
@property (nonatomic, assign) BOOL bounces;

/**
 添加识别其它手势的代理类
 */
@property (nonatomic, strong) NSArray <NSString *>* respondOtherGestureDelegateClassList;

/**
 标题栏右侧按钮
 */
@property (nonatomic, strong) UIButton *rightButton;

/**
 初始化方法

 @param config 配置信息
 @return XLPageViewController 实例
 */
- (instancetype)initWithConfig:(XLPageViewControllerConfig *)config;

/**
 刷新方法，当标题改变时，执行此方法
 */
- (void)reloadData;

/**
 自定义标题栏cell时用到
 */
- (void)registerClass:(Class)cellClass forTitleViewCellWithReuseIdentifier:(NSString *)identifier;

/**
 自定义标题栏cell时用到
 返回复用的cell
 */
- (__kindof XLPageTitleCell *)dequeueReusableTitleViewCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
