//
//  WFCUPadSplitViewController.m
//  WFChat UIKit
//

#import "WFCUPadSplitViewController.h"
#import "WFCUPadPlaceholderViewController.h"
#import "WFCUPadUtility.h"
#import "WFCUConfigManager.h"

/// 右栏自己的导航控制器。存在的唯一理由是拦下「必须全屏」的页面：
/// 右栏里 push 出来的媒体预览只会盖住右半边（缺陷 #6）。左栏那一路在
/// WFCUPadPrimaryNavigationController 里拦，两处合起来才是完整的 R6。
@interface WFCUPadDetailNavigationController : UINavigationController
@end

@implementation WFCUPadDetailNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    //把「只该占右栏」的模态（转发、选人、改一段文字这些）钉在本栏内呈现。
    //这是 UIKit 给分栏详情栏准备的现成机制：模态的 modalPresentationStyle 设成 CurrentContext 后，
    //UIKit 从发起者往上找第一个 definesPresentationContext 的控制器当容器，找到的就是这里。
    //谁被这样处理见 WFCUPadUtility 的 detailPaneClassNames。
    self.definesPresentationContext = YES;
    self.providesPresentationContextTransitionStyle = YES;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([WFCUPadUtility presentFullScreenIfNeeded:viewController animated:animated]) {
        return;
    }
    [super pushViewController:viewController animated:animated];
}

@end

/// 右栏的容器。iOS 26 起系统把左栏画成悬浮的玻璃面板，压在**满铺整屏**的右栏上（见计划 1.4 实测），
/// 右栏 view 的 frame 就是整个窗口，栏宽藏在 safeAreaInsets.left 里。这带来两个后果：
///  1. 新页面压进右栏的头一帧里安全区还没传下来（转场中的视图更是先在屏外排一次版），
///     页面按整屏宽排了一遍，内容就从左栏底下透出来闪一下；
///  2. R1 要的是微信那种硬分栏，不是内容从侧栏底下穿过去。
/// 所以这里把右栏导航控制器的 view 钉在安全区右侧那一块并 clipsToBounds：不管页面自己算出多宽，
/// 都画不到左栏那一条上；左边那一条交给容器自己的背景色。
/// 安全区随之逐级传下去（左边距被这一层吃掉，顶部状态栏、底部 Home 指示条照旧），
/// 页面里那些按安全区算的布局不用动。
/// iOS 25 及更早本来就是硬分栏（left inset 恒为 0），这一层退化成整块铺满，与不加它逐字节等价。
@interface WFCUPadDetailContainerViewController : UIViewController
- (instancetype)initWithContentViewController:(UIViewController *)content;
@property (nonatomic, strong, readonly) UIViewController *contentViewController;
@end

@implementation WFCUPadDetailContainerViewController {
    //上次钉好的右栏 frame。模态转场期间安全区/bounds 都是过渡值，用它保持原样不动。
    CGRect _lastGoodFrame;
}

- (instancetype)initWithContentViewController:(UIViewController *)content {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _contentViewController = content;
        [self addChildViewController:content];
        [content didMoveToParentViewController:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].frameBackgroudColor;
    self.contentViewController.view.clipsToBounds = YES;
    [self.view addSubview:self.contentViewController.view];
}

//模态弹起/收回期间，系统会临时改安全区、把右栏内容挪到错误位置（实测：收回时整页
//被顶到左栏底下）。此刻安全区/bounds 都是过渡值，不能用它们重算：沿用上次钉好的
//frame，转场期间一步不动。
//presentedViewController 在 dismiss 一开始就被系统清掉，罩不住收回动画那一段，
//所以要看 isModalTransitionInProgress（present/dismiss 的 swizzle 维护）。
//注意这里不是「跳过」而是主动钉回 _lastGoodFrame：系统若在转场里挪了右栏内容，
//下一轮布局（含转场期间的 CADisplayLink 每帧驱动）会立刻把它拉回正确位置，
//不会等转场结束才纠。
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat left = 0;
    if (@available(iOS 11.0, *)) {
        left = self.view.safeAreaInsets.left;
    }

    if ([WFCUPadUtility isModalTransitionInProgress]) {
        if (!CGRectIsEmpty(_lastGoodFrame) &&
            !CGRectEqualToRect(_lastGoodFrame, self.contentViewController.view.frame)) {
            [UIView performWithoutAnimation:^{
                self.contentViewController.view.frame = _lastGoodFrame;
            }];
        }
        return;
    }

    CGRect frame = CGRectMake(left, 0, MAX(bounds.size.width - left, 0), bounds.size.height);
    _lastGoodFrame = frame;
    self.contentViewController.view.frame = frame;
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    //手写 frame，安全区变了得自己要一次重排
    [self.view setNeedsLayout];
}

@end

@interface WFCUPadSplitViewController () <UISplitViewControllerDelegate, UINavigationControllerDelegate, UITabBarControllerDelegate>
@property (nonatomic, strong) UITabBarController *primaryTabBarController;
@property (nonatomic, strong) UINavigationController *detailNavigationController;
@property (nonatomic, strong) WFCUPadDetailContainerViewController *detailContainerViewController;

//每个 tab 一条独立的右栏栈，key 是 tab 下标。
//共用一条栈的话，在通讯录点开某人资料再切到消息 tab，右栏还挂着那个人；
//切回通讯录又变成了会话。微信 Pad、android-chat(TwoPaneNavigator.stacks) 与
//flutter-chat 都是每 tab 一条栈。
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSArray<UIViewController *> *> *detailStacks;
//右栏当前挂着的是哪个 tab 的栈。NSNotFound 表示还没装载过。
@property (nonatomic, assign) NSInteger loadedDetailTabIndex;
@end

@implementation WFCUPadSplitViewController

- (instancetype)initWithPrimaryViewController:(UITabBarController *)tabBarController {
    self = [super init];
    if (self) {
        _primaryTabBarController = tabBarController;
        _detailNavigationController = [[WFCUPadDetailNavigationController alloc] initWithRootViewController:[WFCUPadPlaceholderViewController new]];

        _detailNavigationController.delegate = self;
        _detailStacks = [[NSMutableDictionary alloc] init];
        _loadedDetailTabIndex = NSNotFound;
        tabBarController.delegate = self;

        _detailContainerViewController = [[WFCUPadDetailContainerViewController alloc] initWithContentViewController:_detailNavigationController];

        self.viewControllers = @[tabBarController, _detailContainerViewController];
        self.delegate = self;

        //左栏常驻，不允许滑动隐藏，与微信 iPad 一致
        if (@available(iOS 14.0, *)) {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
        } else {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        }
        self.presentsWithGesture = NO;
        //左栏定宽，min 与 max 取同一个值。比例宽会让 11 寸横屏时左栏被拉到 375，
        //与 android/flutter 两端的 320 / 360 对不上。
        CGFloat columnWidth = [WFCUPadUtility primaryColumnWidth];
        self.minimumPrimaryColumnWidth = columnWidth;
        self.maximumPrimaryColumnWidth = columnWidth;

        [WFCUPadUtility setSplitViewController:self];
    }
    return self;
}

- (void)dealloc {
    if ([WFCUPadUtility splitViewController] == self) {
        [WFCUPadUtility setSplitViewController:nil];
    }
}

#pragma mark - UISplitViewControllerDelegate

//变窄（Slide Over / iPhone 尺寸）时收成单栏：把右栏的页面接到当前 tab 的导航栈上，用户不会丢失当前聊天
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
collapseSecondaryViewController:(UIViewController *)secondaryViewController
  ontoPrimaryViewController:(UIViewController *)primaryViewController {
    //右栏当前挂着的那条栈先存回去，这样下面能统一按 tab 遍历
    if (self.loadedDetailTabIndex != NSNotFound) {
        self.detailStacks[@(self.loadedDetailTabIndex)] = self.detailNavigationController.viewControllers;
    }
    [self.detailNavigationController setViewControllers:[self emptyDetailStack] animated:NO];

    //每个 tab 的那条栈各自接回自己的导航栈，不能全塞给当前 tab
    for (NSNumber *key in [self.detailStacks.allKeys copy]) {
        [self appendStack:self.detailStacks[key] toTabAtIndex:key.integerValue];
    }
    [self.detailStacks removeAllObjects];
    self.loadedDetailTabIndex = NSNotFound;

    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:nil];
    return YES;
}

//变宽时重新展开：把当前 tab 导航栈里根页面之上的部分挪回右栏
- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController
separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    //每个 tab 的导航栈里该去右栏的那一段各自摘出来，存进自己的栈
    [self.detailStacks removeAllObjects];
    NSInteger tabCount = (NSInteger)self.primaryTabBarController.viewControllers.count;
    for (NSInteger i = 0; i < tabCount; i++) {
        NSArray<UIViewController *> *moved = [self detachDetailStackFromTabAtIndex:i];
        if (moved.count) {
            //栈底补上欢迎页：展开成双栏后这些页面同样要能一路返回到欢迎页，
            //与从左栏点开的路径保持一条规则。
            //工作台那一栏摘回来的第一页就是它自己的栈底（网页），别再补一层。
            NSArray<UIViewController *> *bottom = [self emptyDetailStackForTabAtIndex:i];
            if (bottom.firstObject == moved.firstObject) {
                self.detailStacks[@(i)] = moved;
            } else {
                self.detailStacks[@(i)] = [bottom arrayByAddingObjectsFromArray:moved];
            }
        }
    }

    NSInteger current = self.primaryTabBarController.selectedIndex;
    self.loadedDetailTabIndex = current;
    NSArray<UIViewController *> *stack = self.detailStacks[@(current)];
    if (!stack.count) {
        stack = [self emptyDetailStackForTabAtIndex:current];
    }
    [self.detailNavigationController setViewControllers:stack animated:NO];
    [self postDetailDidChange];
    return self.detailContainerViewController;
}

#pragma mark - 每个 tab 一条右栏栈

- (void)syncDetailStackForCurrentTab {
    if (self.isCollapsed) {
        //单栏形态下没有右栏，各 tab 的页面本来就在自己的导航栈上
        return;
    }
    NSInteger index = self.primaryTabBarController.selectedIndex;
    if (index == self.loadedDetailTabIndex) {
        return;
    }
    if (self.loadedDetailTabIndex != NSNotFound) {
        self.detailStacks[@(self.loadedDetailTabIndex)] = self.detailNavigationController.viewControllers;
    }
    self.loadedDetailTabIndex = index;

    NSArray<UIViewController *> *stack = self.detailStacks[@(index)];
    if (!stack.count) {
        //没进过的 tab 显示欢迎页，懒建（工作台那一栏建出来的是网页本身）
        stack = [self emptyDetailStackForTabAtIndex:index];
    }
    //用 setViewControllers: 换栈而不是隐藏：切走的那条栈上的会话页要真的走 viewWillDisappear，
    //否则它会在后台继续把新消息标记成已读（android 那边遇到过同样的问题）
    [self.detailNavigationController setViewControllers:stack animated:NO];
    [self postDetailDidChange];
}

/// 把某个 tab 的那条右栏栈退回栈底（欢迎页）。
/// 对应 android `TwoPaneNavigator.onConversationListChanged` 里的 `stacks.get(tab).reset()`：
/// 右栏打开的会话从列表里消失了（删除会话、退群），只退它所在的那一栏 ——
/// 别的 tab 的栈上压着完全无关的页面，不该被连累。
- (void)resetDetailStackForTabAtIndex:(NSInteger)index {
    if (self.isCollapsed) {
        //单栏形态下没有右栏，那些页面在各自 tab 的导航栈上
        return;
    }
    if (index < 0 || index >= (NSInteger)self.primaryTabBarController.viewControllers.count) {
        return;
    }
    if (index == self.loadedDetailTabIndex) {
        [WFCUPadUtility resetDetailViewController];
        return;
    }
    if (self.detailStacks[@(index)]) {
        //没装载的那条栈只是一组 VC，换成空栈即可；下次切到那个 tab 时装载的就是欢迎页
        self.detailStacks[@(index)] = [self emptyDetailStackForTabAtIndex:index];
    }
}

/// 一条空栈：只有欢迎页。每条栈各自持有自己的实例——同一个 VC 不能同时挂在两条导航栈上。
- (NSArray<UIViewController *> *)emptyDetailStack {
    return @[[WFCUPadPlaceholderViewController new]];
}

/// 某个 tab 的空栈栈底。绝大多数 tab 是欢迎页；工作台那一栏的栈底是网页本身
/// （它没有「列表 → 详情」的层次，左栏是迎宾面板，网页常驻右栏），
/// 对应 flutter `PadHome._initialPaneRoutes` 里那句「工作台 tab 的基座就是工作台本身」。
- (NSArray<UIViewController *> *)emptyDetailStackForTabAtIndex:(NSInteger)index {
    UIViewController *permanent = [self permanentDetailRootForTabAtIndex:index];
    return permanent ? @[permanent] : [self emptyDetailStack];
}

/// 这个 tab 有没有常驻右栏的那一页（只有工作台有）
- (UIViewController *)permanentDetailRootForTabAtIndex:(NSInteger)index {
    UINavigationController *nav = [self primaryNavigationControllerAtIndex:index];
    return nav.viewControllers.firstObject.wfcu_padDetailRootViewController;
}

- (void)postDetailDidChange {
    //栈底恒为欢迎页，左栏高亮跟着压在它上面那一层走。往下钻（会话 -> 会话详情）时
    //仍然由最底下那个真实页面说了算，高亮不该在下钻时掉。
    UIViewController *root = nil;
    for (UIViewController *vc in self.detailNavigationController.viewControllers) {
        if (![vc isKindOfClass:[WFCUPadPlaceholderViewController class]]) {
            root = vc;
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:root];
}

/// 收起右栏时，把某条栈接到对应 tab 的导航栈末尾
- (void)appendStack:(NSArray<UIViewController *> *)stack toTabAtIndex:(NSInteger)index {
    NSMutableArray<UIViewController *> *movable = [[NSMutableArray alloc] init];
    for (UIViewController *vc in stack) {
        if (![vc isKindOfClass:[WFCUPadPlaceholderViewController class]]) {
            [movable addObject:vc];
        }
    }
    if (!movable.count) {
        return;
    }
    UINavigationController *nav = [self primaryNavigationControllerAtIndex:index];
    if (!nav) {
        return;
    }
    NSMutableArray *vcs = [nav.viewControllers mutableCopy];
    [vcs addObjectsFromArray:movable];
    [nav setViewControllers:vcs animated:NO];
}

/// 展开右栏时，把某个 tab 导航栈里该去右栏的那一段摘出来。
/// 标了 wfcu_prefersPrimaryColumn 的页面（搜索、设置这类）留在左栏，不受牵连。
- (NSArray<UIViewController *> *)detachDetailStackFromTabAtIndex:(NSInteger)index {
    UINavigationController *nav = [self primaryNavigationControllerAtIndex:index];
    NSArray<UIViewController *> *vcs = nav.viewControllers;
    NSInteger splitAt = NSNotFound;
    for (NSInteger i = 1; i < (NSInteger)vcs.count; i++) {
        if (!vcs[i].wfcu_prefersPrimaryColumn) {
            splitAt = i;
            break;
        }
    }
    if (splitAt == NSNotFound) {
        return nil;
    }
    NSArray<UIViewController *> *moved = [vcs subarrayWithRange:NSMakeRange(splitAt, vcs.count - splitAt)];
    [nav setViewControllers:[vcs subarrayWithRange:NSMakeRange(0, splitAt)] animated:NO];
    return moved;
}

- (UINavigationController *)primaryNavigationControllerAtIndex:(NSInteger)index {
    NSArray<UIViewController *> *tabs = self.primaryTabBarController.viewControllers;
    if (index < 0 || index >= (NSInteger)tabs.count) {
        return nil;
    }
    UIViewController *vc = tabs[index];
    return [vc isKindOfClass:[UINavigationController class]] ? (UINavigationController *)vc : nil;
}

#pragma mark - UITabBarControllerDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self syncDetailStackForCurrentTab];
}

#pragma mark - UINavigationControllerDelegate

//右栏的导航栏只在占位页时隐藏。这个判断必须放在这里而不是占位页自己的 viewWillDisappear：
//右栏是用 setViewControllers: 直接换根页面的，占位页的消失回调不保证被调用，
//一旦漏掉，导航栏就永远藏着——聊天页没有标题也没有返回键。
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (navigationController != self.detailNavigationController) {
        return;
    }
    BOOL shouldHide = [viewController isKindOfClass:[WFCUPadPlaceholderViewController class]];
    if (navigationController.navigationBarHidden != shouldHide) {
        [navigationController setNavigationBarHidden:shouldHide animated:animated];
    }
}

//点返回键退回欢迎页之后，左栏的选中高亮要跟着撤掉，否则列表还亮着一个右栏已经不显示的会话。
//android 用 FragmentManager 的返回栈监听、flutter 用 NavigatorObserver 做的是同一件事。
- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (navigationController != self.detailNavigationController) {
        return;
    }
    [self postDetailDidChange];
}

#pragma mark - 状态栏 / 旋转

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.primaryTabBarController;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
