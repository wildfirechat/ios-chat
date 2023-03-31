//
//  XLPageViewController.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/6.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController

#import "XLPageViewController.h"
#import "XLPageBasicTitleView.h"
#import "XLPageSegmentedTitleView.h"
#import "WFCUUtilities.h"

//调用setViewControllers方法时，可能会用到延时
static float SetViewControllersMethodDelay = 0.1;

typedef void(^XLContentScollBlock)(BOOL scrollEnabled);

@interface XLPageContentView : UIView

@property (nonatomic, strong) XLContentScollBlock scrollBlock;

@end

@implementation XLPageContentView

//兼容和子view滚动冲突问题
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view =  [super hitTest:point withEvent:event];
    BOOL pageViewScrollEnabled = !view.xl_letMeScrollFirst;
    if (self.scrollBlock) {
        self.scrollBlock(pageViewScrollEnabled);
    }
    return view;
}

@end

@interface XLPageViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource,UIScrollViewDelegate,XLPageTitleViewDataSrouce,XLPageTitleViewDelegate>

//所有的子视图，都加载在contentView上
@property (nonatomic, strong) XLPageContentView *contentView;
//标题
@property (nonatomic, strong) XLPageBasicTitleView *titleView;
//分页控制器
@property (nonatomic, strong) UIPageViewController *pageVC;
//ScrollView
@property (nonatomic, strong) UIScrollView *scrollView;
//显示过的vc数组，用于试图控制器缓存
@property (nonatomic, strong) NSMutableArray *shownVCArr;
//所有标题集合
@property (nonatomic, strong) NSMutableArray *allTitleArr;
//是否加载了pageVC
@property (nonatomic, assign) BOOL pageVCDidLoad;
//判断pageVC是否在切换中
@property (nonatomic, assign) BOOL pageVCAnimating;
//当前配置信息
@property (nonatomic, strong) XLPageViewControllerConfig *config;
//上一次代理返回的index
@property (nonatomic, assign) NSInteger lastDelegateIndex;
//手指拖拽距离
@property (nonatomic, assign) CGFloat dragStartX;

@end

@implementation XLPageViewController

#pragma mark -
#pragma mark 初始化方法
//初始化需要使用initWithConfig方法
- (instancetype)init {
    if (self = [super init]) {
        [NSException raise:@"Do not use this method" format:@"Must be initialized by initWithConfig"];
    }
    return self;
}

- (instancetype)initWithConfig:(XLPageViewControllerConfig *)config {
    if (self = [super init]) {
        [self initUIWithConfig:config];
        [self initData];
    }
    return self;
}

- (void)initUIWithConfig:(XLPageViewControllerConfig *)config {
    
    //保存配置
    self.config = config;
    
    //创建contentview
    self.contentView = [[XLPageContentView alloc] init];
    [self.view addSubview:self.contentView];
    __weak typeof(self)weakSelf = self;
    self.contentView.scrollBlock = ^(BOOL scrollEnabled) {
        if (weakSelf.scrollEnabled) {
            weakSelf.scrollView.scrollEnabled = scrollEnabled;
        }
    };
    
    //防止Navigation引起的缩进
    UIView *topView = [[UIView alloc] init];
    [self.contentView addSubview:topView];
    
    //创建标题
    self.titleView = [[XLPageBasicTitleView alloc] initWithConfig:config];
    if (config.titleViewStyle == XLPageTitleViewStyleSegmented) {
        self.titleView = [[XLPageSegmentedTitleView alloc] initWithConfig:config];
    }
    self.titleView.dataSource = self;
    self.titleView.delegate = self;
    [self.contentView addSubview:self.titleView];
    
    //创建PageVC
    self.pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageVC.delegate = self;
    self.pageVC.dataSource = self;
    [self.contentView addSubview:self.pageVC.view];
    [self addChildViewController:self.pageVC];
    
    //设置ScrollView代理
    for (UIScrollView *scrollView in self.pageVC.view.subviews) {
        if ([scrollView isKindOfClass:[UIScrollView class]]) {
            self.scrollView = scrollView;
            self.scrollView.delegate = self;
        }
    }
    
    //默认可以滚动
    self.scrollEnabled = YES;
    
    //默认打开自动回答弹
    self.bounces = YES;
    
    //初始化上一次返回的index
    self.lastDelegateIndex = -1;
    
    //兼容全屏返回手势识别
    self.scrollView.xl_otherGestureRecognizerBlock = ^BOOL(UIGestureRecognizer * _Nonnull otherGestureRecognizer) {
        return weakSelf.selectedIndex == 0 && [weakSelf.respondOtherGestureDelegateClassList containsObject:NSStringFromClass(otherGestureRecognizer.delegate.class)];
    };
}

//初始化vc缓存数组
- (void)initData {
    self.shownVCArr = [[NSMutableArray alloc] init];
}

//设置titleView位置
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.config.showTitleInNavigationBar) {
        self.parentViewController.navigationItem.titleView = self.titleView;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    //更新contentview位置
    self.contentView.frame = self.view.bounds;
    
    //更新标题位置
    self.titleView.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, self.config.titleViewHeight);
    
    //更新pageVC位置
    self.pageVC.view.frame = CGRectMake(0, self.config.titleViewHeight, self.contentView.bounds.size.width, self.contentView.bounds.size.height - self.config.titleViewHeight);
    
    if (self.config.showTitleInNavigationBar) {
        self.pageVC.view.frame = self.contentView.bounds;
    }
    
    //自动选中当前位置_selectedIndex
    if (!self.pageVCDidLoad) {
        //设置加载标记为已加载
        [self switchToViewControllerAdIndex:_selectedIndex animated:NO];
        self.pageVCDidLoad = YES;
    }
    
    //初始化标题数组
    self.allTitleArr = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [self numberOfPage]; i++) {
        [self.allTitleArr addObject:[self titleForIndex:i]];
    }
}

#pragma mark -
#pragma mark UIPageViewControllerDelegate
//滚动切换时调用
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    self.pageVCAnimating = YES;
}

//滚动切换时调用
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (!completed) {
        //切换中属性更新
        self.pageVCAnimating = NO;
        return;
    }
    //更新选中位置
    UIViewController *vc = self.pageVC.viewControllers.firstObject;
    _selectedIndex = [self.allTitleArr indexOfObject:vc.xl_title];
    //标题居中
    self.titleView.selectedIndex = _selectedIndex;
    //回调代理方法
    [self delegateSelectedAdIndex:_selectedIndex];
    //切换中属性更新
    self.pageVCAnimating = NO;
}

#pragma mark -
#pragma mark UIPageViewControllerDataSource
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    //修正因为拖拽距离过大，导致空白界面问题
    [self fixSelectedIndexWhenDragingBefore];
    return [self viewControllerForIndex:_selectedIndex - 1];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    //修正因为拖拽距离过大，导致空白界面问题
    [self fixSelectedIndexWhenDragingAfter];
    return [self viewControllerForIndex:_selectedIndex + 1];
}

//修正因拖拽距离过大，导致出现空白界面问题
- (void)fixSelectedIndexWhenDragingBefore {
    //计算手动拖拽的距离，避免快速滑动时触发以下算法
    CGFloat dragDistance = fabs(self.scrollView.contentOffset.x - self.dragStartX);
    //判断1、是否是手指正在拖拽 2、是否滑动距离够大。如果两者成立，则表示需要手动修正位置
    if (self.scrollView.isTracking && dragDistance > self.scrollView.bounds.size.width) {
        self.pageVCAnimating = NO;
        NSInteger targetIndex = _selectedIndex - 1;
        targetIndex = targetIndex < 0 ? 0 : targetIndex;
        self.selectedIndex = targetIndex;
        self.titleView.stopAnimation = NO;
        //执行代理方法
        [self delegateSelectedAdIndex:targetIndex];
    }
}

//修正因拖拽距离过大，导致出现空白界面问题
- (void)fixSelectedIndexWhenDragingAfter {
    //计算手动拖拽的距离，避免快速滑动时触发以下算法
    CGFloat dragDistance = fabs(self.scrollView.contentOffset.x - self.dragStartX);
    //判断1、是否是手指正在拖拽 2、是否滑动距离够大。如果两者成立，则表示需要手动修正位置
    if (self.scrollView.isTracking && dragDistance > self.scrollView.bounds.size.width) {
        self.pageVCAnimating = NO;
        NSInteger targetIndex = _selectedIndex + 1;
        targetIndex = targetIndex >= [self numberOfPage] ? [self numberOfPage] - 1 : targetIndex;
        self.selectedIndex = targetIndex;
        self.titleView.stopAnimation = NO;
        //执行代理方法
        [self delegateSelectedAdIndex:targetIndex];
    }
}

#pragma mark -
#pragma mark ScrollViewDelegate
//滚动时计算标题动画进度
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat value = scrollView.contentOffset.x - scrollView.bounds.size.width;
    self.titleView.animationProgress = value/scrollView.bounds.size.width;
    
    //设置拖拽手势问题
    if (self.respondOtherGestureDelegateClassList.count > 0) {
        BOOL scrollDisababled = value < 0 && self.selectedIndex == 0 && self.respondOtherGestureDelegateClassList.count;
        scrollView.scrollEnabled = !scrollDisababled;
    }
    
    //设置边缘回弹问题
    BOOL dragToTheEdge = (self.selectedIndex == 0 && value < 0) || (self.selectedIndex == [self numberOfPage] - 1 && value > 0);
    if (dragToTheEdge && scrollView.isDragging && !self.bounces) {
        scrollView.scrollEnabled = NO;
    }
}

//更新执行动画状态
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    self.titleView.stopAnimation = false;
}

//更新执行动画状态
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.titleView.stopAnimation = false;
}

//更新执行动画状态
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.titleView.stopAnimation = false;
    //保存手指拖拽起始位置
    self.dragStartX = scrollView.contentOffset.x;
}

//更新执行动画状态
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.titleView.stopAnimation = false;
    scrollView.scrollEnabled = self.scrollEnabled;
}

#pragma mark -
#pragma mark PageTitleViewDataSource&Delegate
//titleview数据源方法
- (NSInteger)pageTitleViewNumberOfTitle {
    return [self numberOfPage];
}

//titleview数据源方法
- (NSString *)pageTitleViewTitleForIndex:(NSInteger)index {
    return [self titleForIndex:index];
}

//titleview数据源方法
- (XLPageTitleCell *)pageTitleViewCellForItemAtIndex:(NSInteger)index {
    if ([self.dataSource respondsToSelector:@selector(pageViewController:titleViewCellForItemAtIndex:)]) {
        return [self.dataSource pageViewController:self titleViewCellForItemAtIndex:index];
    }
    return nil;
}

//titleview代理方法
- (BOOL)pageTitleViewDidSelectedAtIndex:(NSInteger)index {
    BOOL switchSuccess = [self switchToViewControllerAdIndex:index animated:YES];
    if (!switchSuccess) {
        return false;
    }
    self.titleView.stopAnimation = true;
    //点击标题切换时会延时加载，所以要延时回调代理方法，避免出现获取当前VC不正确问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SetViewControllersMethodDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self delegateSelectedAdIndex:index];
    });
    return true;
}

#pragma mark -
#pragma mark Setter
//设置选中位置
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    //范围越界，抛出异常
    if (selectedIndex < 0 || selectedIndex > [self numberOfPage]) {
        [NSException raise:@"selectedIndex is not right ！！！" format:@"It is out of range"];
    }
    BOOL switchSuccess = [self switchToViewControllerAdIndex:selectedIndex animated:YES];
    if (!switchSuccess) {return;}
    self.titleView.stopAnimation = true;
    //更新代理反馈的index
    self.lastDelegateIndex = selectedIndex;
}

//滑动开关
- (void)setScrollEnabled:(BOOL)scrollEnabled {
    _scrollEnabled = scrollEnabled;
    self.scrollView.scrollEnabled = scrollEnabled;
}

//设置右侧按钮
- (void)setRightButton:(UIButton *)rightButton {
    _titleView.rightButton = rightButton;
}

#pragma mark -
#pragma mark 切换位置方法
- (BOOL)switchToViewControllerAdIndex:(NSInteger)index animated:(BOOL)animated {
    if ([self numberOfPage] == 0) {return NO;}
    //如果正在加载中 返回
    if (self.pageVCAnimating && self.config.titleViewStyle == XLPageTitleViewStyleBasic) {return NO;}
    if (index == _selectedIndex && index >= 0 && self.pageVCDidLoad) {return NO;}
    //设置正在加载标记
    self.pageVCAnimating = animated;
    //更新当前位置
    _selectedIndex = index;
    //设置滚动方向
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    if (_titleView.lastSelectedIndex > _selectedIndex) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }
    //设置当前展示VC
    __weak typeof(self)weakSelf = self;
    [self.pageVC setViewControllers:@[[self viewControllerForIndex:index]] direction:direction animated:NO completion:^(BOOL finished) {
        weakSelf.pageVCAnimating = NO;
    }];
    
    //延时是为了避免切换视图时有其它操作阻塞UI
    self.view.userInteractionEnabled = NO;
    float delayTime = animated ? SetViewControllersMethodDelay : 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.view.userInteractionEnabled = YES;
    });
    
    //标题居中
    self.titleView.selectedIndex = _selectedIndex;
    return YES;
}

#pragma mark -
#pragma mark 刷新方法
- (void)reloadData {
    self.pageVCDidLoad = NO;
    //刷新标题栏UI
    [self.titleView reloadData];
    //刷新标题数据
    [self.allTitleArr removeAllObjects];
    for (NSInteger i = 0; i < [self numberOfPage]; i++) {
        [self.allTitleArr addObject:[self titleForIndex:i]];
    }
}

#pragma mark -
#pragma mark 自定义方法
- (void)registerClass:(Class)cellClass forTitleViewCellWithReuseIdentifier:(NSString *)identifier {
    [self.titleView registerClass:cellClass forTitleViewCellWithReuseIdentifier:identifier];
}

- (XLPageTitleCell *)dequeueReusableTitleViewCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [self.titleView dequeueReusableCellWithIdentifier:identifier forIndex:index];
}

#pragma mark -
#pragma mark 辅助方法
//指定位置的视图控制器 缓存方法
- (UIViewController *)viewControllerForIndex:(NSInteger)index {
    
    //如果越界，则返回nil
    if (index < 0 || index >= [self numberOfPage]) {
        return nil;
    }
    //获取当前vc
    UIViewController *currentVC = self.pageVC.viewControllers.firstObject;
    //当前标题
    NSString *currentTitle = currentVC.xl_title;
    //目标切换位置标题
    NSString *targetTitle = [self titleForIndex:index];

    //如果和当前位置一样，则返回当前vc
    if ([currentTitle isEqualToString:targetTitle]) {
        return currentVC;
    }
    
    //如果之前显示过，则从内存中读取
    for (UIViewController *vc in self.shownVCArr) {
        if ([vc.xl_title isEqualToString:targetTitle]) {
            return vc;
        }
    }
    
    //如果之前没显示过，则通过dataSource创建
    UIViewController *vc = [self.dataSource pageViewController:self viewControllerForIndex:index];
    //设置扩展id，用户定位对应视图控制器
    vc.xl_title = [self titleForIndex:index];
    //设置试图控制器标题
    vc.title = [self titleForIndex:index];
    //把vc添加到缓存集合
    [self.shownVCArr addObject:vc];
    //添加子视图控制器
    [self addChildViewController:vc];
    return vc;
}

//指定位置的标题
- (NSString *)titleForIndex:(NSInteger)index {
    return [self.dataSource pageViewController:self titleForIndex:index];
}

//总页数
- (NSInteger)numberOfPage {
    return [self.dataSource pageViewControllerNumberOfPage];
}

//执行代理方法
- (void)delegateSelectedAdIndex:(NSInteger)index {
    if (index == self.lastDelegateIndex) {return;}
    self.lastDelegateIndex = index;
    if ([self.delegate respondsToSelector:@selector(pageViewController:didSelectedAtIndex:)]) {
        [self.delegate pageViewController:self didSelectedAtIndex:index];
    }
}

@end
