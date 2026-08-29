//
//  WFCUPadUtility.m
//  WFChat UIKit
//

#import "WFCUPadUtility.h"
#import "WFCUPadPlaceholderViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

const CGFloat WFCUPadPrimaryColumnWidth = 320.f;
const CGFloat WFCUPadPrimaryColumnWideWidth = 360.f;
const CGFloat WFCUPadWideScreenMinDimension = 840.f;
const CGFloat WFCUPadChatContentMaxWidth = 720.f;
const CGFloat WFCUPadFormMaxWidth = 400.f;

NSString *const WFCUPadDetailDidChangeNotification = @"WFCUPadDetailDidChangeNotification";

static __weak UISplitViewController *gSplitViewController = nil;

static const void *kWFCUPadSearchTriggerKey = &kWFCUPadSearchTriggerKey;

/// 左栏那条搜索框上那个点击手势的守卫：只在双栏时认这一下。
/// 单栏（iPad 进 Slide Over）时不认，搜索框照原样取焦点，走 UISearchController 那条老路。
@interface WFCUPadSearchTriggerGate : NSObject <UIGestureRecognizerDelegate>
@end
@implementation WFCUPadSearchTriggerGate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return [WFCUPadUtility isSplitLayoutActive];
}
@end

@interface WFCUPadUtility ()
+ (UIView *)anchorViewFallback;
@end

@implementation WFCUPadUtility

+ (BOOL)isPad {
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

+ (CGFloat)primaryColumnWidth {
    CGSize screen = [UIScreen mainScreen].bounds.size;
    CGFloat shortSide = MIN(screen.width, screen.height);
    return shortSide >= WFCUPadWideScreenMinDimension ? WFCUPadPrimaryColumnWideWidth : WFCUPadPrimaryColumnWidth;
}

+ (void)syncDetailStackForCurrentTab {
    UISplitViewController *svc = gSplitViewController;
    if ([svc respondsToSelector:@selector(syncDetailStackForCurrentTab)]) {
        [(id)svc syncDetailStackForCurrentTab];
    }
}

+ (void)resetDetailStackForTabAtIndex:(NSInteger)index {
    UISplitViewController *svc = gSplitViewController;
    if ([svc respondsToSelector:@selector(resetDetailStackForTabAtIndex:)]) {
        [(id)svc resetDetailStackForTabAtIndex:index];
    }
}

+ (UISplitViewController *)splitViewController {
    return gSplitViewController;
}

+ (void)setSplitViewController:(UISplitViewController *)splitViewController {
    gSplitViewController = splitViewController;
}

+ (BOOL)isSplitLayoutActive {
    UISplitViewController *svc = gSplitViewController;
    if (!svc) {
        return NO;
    }
    return !svc.isCollapsed;
}

+ (UINavigationController *)detailNavigationController {
    UISplitViewController *svc = gSplitViewController;
    if (svc.viewControllers.count < 2) {
        return nil;
    }
    UIViewController *detail = svc.viewControllers.lastObject;
    if ([detail isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)detail;
    }
    //右栏外面套了一层容器（把内容钉在安全区右侧的那一层，见 WFCUPadSplitViewController）
    for (UIViewController *child in detail.childViewControllers) {
        if ([child isKindOfClass:[UINavigationController class]]) {
            return (UINavigationController *)child;
        }
    }
    return nil;
}

+ (BOOL)showDetailViewController:(UIViewController *)vc {
    if (![self isSplitLayoutActive]) {
        return NO;
    }
    UINavigationController *nav = [self detailNavigationController];
    if (!nav) {
        return NO;
    }
    //右栏挂的必须是当前 tab 自己那条栈，否则会把内容写到上一个 tab 的栈上
    [self syncDetailStackForCurrentTab];

    //重复点开同一个页面（最常见的是同一个会话）不重建：草稿、滚动位置、正在放的语音都会丢。
    //对应 android `TwoPaneNavigator.isSameConversationAsTop`：它同样只比栈顶，
    //且要求栈顶不是栈底的欢迎页（那边写作 stack.canPop()，这里欢迎页的 pageKey 为 nil，等价）。
    //定位参数（搜索命中的那条消息、按日期跳转）编在 key 里，所以「同一个会话但要停在不同位置」
    //仍然会重建 —— 与 android 那句「需要定位时即使是同一个会话也要重建」是同一条规则。
    NSString *pageKey = vc.wfcu_padPageKey;
    if (pageKey.length && [pageKey isEqualToString:nav.topViewController.wfcu_padPageKey]) {
        return YES;
    }
    //左栏根页面发起的跳转是「换内容」：退到栈底再压入，对应 android
    //TwoPaneNavigator 里的 openPage(resetFirst = true)。
    //栈底的欢迎页必须留着：右栏的返回箭头靠它才有地方可回。android 的注释写得很直白——
    //「压进来的页面一律给返回箭头，它下面至少还有本栈的栈底」。
    UIViewController *placeholder = nav.viewControllers.firstObject;
    if (![placeholder isKindOfClass:[WFCUPadPlaceholderViewController class]]) {
        placeholder = [WFCUPadPlaceholderViewController new];
    }
    [nav setViewControllers:@[placeholder, vc] animated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:vc];
    return YES;
}

+ (BOOL)pushDetailViewController:(UIViewController *)vc animated:(BOOL)animated {
    if (![self isSplitLayoutActive]) {
        return NO;
    }
    UINavigationController *nav = [self detailNavigationController];
    if (!nav) {
        return NO;
    }
    NSString *pageKey = vc.wfcu_padPageKey;
    if (pageKey.length && [pageKey isEqualToString:nav.topViewController.wfcu_padPageKey]) {
        return YES;
    }
    [nav pushViewController:vc animated:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:nil];
    return YES;
}

+ (BOOL)replaceDetailViewController:(UIViewController *)vc animated:(BOOL)animated {
    if (![self isSplitLayoutActive]) {
        return NO;
    }
    UINavigationController *nav = [self detailNavigationController];
    if (!nav) {
        return NO;
    }
    NSMutableArray<UIViewController *> *vcs = [nav.viewControllers mutableCopy];
    //栈底是欢迎页（工作台那一栏是网页本身），它是返回键的落点，不能被顶替掉
    if (vcs.count > 1) {
        [vcs removeLastObject];
    }
    [vcs addObject:vc];
    [nav setViewControllers:vcs animated:animated];
    //真正的高亮对象由 WFCUPadSplitViewController 的 didShowViewController: 重算，
    //这里只负责把「右栏换了内容」这件事发出去
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:nil];
    return YES;
}

+ (void)resetDetailViewController {
    UINavigationController *nav = [self detailNavigationController];
    if (!nav) {
        return;
    }
    if ([nav.viewControllers.firstObject isKindOfClass:[WFCUPadPlaceholderViewController class]]) {
        if (nav.viewControllers.count == 1) {
            return;
        }
        //栈底本来就是欢迎页，退回去即可，不必重建
        [nav popToRootViewControllerAnimated:NO];
    } else {
        [nav setViewControllers:@[[WFCUPadPlaceholderViewController new]] animated:NO];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:WFCUPadDetailDidChangeNotification object:nil];
}

+ (UIViewController *)currentDetailRootViewController {
    if (![self isSplitLayoutActive]) {
        return nil;
    }
    //栈底恒为欢迎页，真正在展示的主页面是压在它上面的那一层
    for (UIViewController *vc in [self detailNavigationController].viewControllers) {
        if (![vc isKindOfClass:[WFCUPadPlaceholderViewController class]]) {
            return vc;
        }
    }
    return nil;
}

/// 必须全屏的页面名单。
/// android 那边是反过来的白名单（`PaneRegistry` 里登记过的才进右栏，其余全屏），
/// iOS 存量代码默认全是 push，只能列黑名单。用类名而不是 `isKindOfClass:`，
/// 是为了不把 Vendor 里的 MWPhotoBrowser 拖进 Pad 这个目录的依赖里。
+ (NSArray<NSString *> *)fullScreenClassNames {
    static NSArray *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[//图片/视频预览（含九宫格）。
                  //flutter 的原话：「在右栏里就只盖住右半边；而且预览的进出场动画是按气泡的
                  //全局坐标算的，压错栈连动画起点都是偏的。」
                  @"MWPhotoBrowser",
                  //密聊里的单图预览
                  @"WFCUImagePreviewViewController"];
    });
    return names;
}

+ (BOOL)requiresFullScreen:(UIViewController *)vc {
    if (!vc) {
        return NO;
    }
    if (vc.wfcu_prefersFullScreen) {
        return YES;
    }
    for (NSString *name in [self fullScreenClassNames]) {
        Class cls = NSClassFromString(name);
        if (cls && [vc isKindOfClass:cls]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)presentFullScreenIfNeeded:(UIViewController *)vc animated:(BOOL)animated {
    if (![self isSplitLayoutActive] || ![self requiresFullScreen:vc]) {
        return NO;
    }
    UIViewController *presenter = gSplitViewController;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    //原本是 push 出来的页面，导航栏上的按钮（MWPhotoBrowser 的「完成」、分享）都挂在
    //navigationItem 上，不套一层导航控制器就没有地方显示，也就关不掉。
    UIViewController *toPresent = vc;
    if (![vc isKindOfClass:[UINavigationController class]]) {
        toPresent = [[UINavigationController alloc] initWithRootViewController:vc];
    }
    //iOS 13 起模态默认是 pageSheet，在 iPad 上会缩成一张卡片
    toPresent.modalPresentationStyle = UIModalPresentationFullScreen;
    [presenter presentViewController:toPresent animated:animated completion:nil];
    return YES;
}

/// 只该占右栏的页面名单。逐条对应 android `PaneRegistry` 里登记进右栏的那一批。
///
/// 这里要纠正一个此前的误读：android **并没有**把选择器挡在右栏之外，恰恰相反 ——
/// `ForwardActivity`、`PickContactActivity`、`PickGroupMemberActivity`、`AddGroupMemberActivity`、
/// `CreateConversationActivity`、`MentionGroupMemberActivity`、`PickConversationActivity`、
/// 以及「改一段文字然后保存」的那五个页面，全部登记进了右栏。
/// 真正返回 null 走全屏的只有三处，而且理由是同一个：**同一个页面既是普通列表又是选择器**
/// （`GroupListActivity` 带 forResult、`ChannelListActivity` 与组织架构页带 pick），
/// 右栏那一份是「普通列表」那一份，回传不了结果，所以选择器形态只能全屏。
///
/// iOS 没有这个二义性 —— 选择器的结果是 block 回调，捕获在调用点，页面压在哪一栏都能回传。
/// 所以这一批在 iOS 上一律留在右栏。
+ (NSArray<NSString *> *)detailPaneClassNames {
    static NSArray *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[//转发（ForwardActivity）
                  @"WFCUForwardViewController",
                  //选人一族：发起聊天/发起密聊、加群成员、群通话选人、群管理里的选人
                  //（CreateConversationActivity / AddGroupMemberActivity / PickGroupMemberActivity）
                  @"WFCUSeletedUserViewController",
                  //选人页里的搜索
                  @"WFCUSeletedUserSearchResultViewController",
                  //选联系人（PickContactActivity），禁言、加管理员、移除成员、按人查文件都用它
                  @"WFCUContactListViewController",
                  //「改一段文字然后保存」：群名、群备注、我的群名片、群公告、好友备注
                  //（SetGroupNameActivity / SetGroupRemarkActivity / SetAliasActivity …）
                  @"WFCUGeneralModifyViewController",
                  //互联域列表（DomainListActivity）
                  @"WFCUDomainTableViewController",
                  //发送位置（MyLocationActivity）与查看位置（ShowLocationActivity）
                  @"WFCULocationViewController",
                  //投票详情、接龙详情。两端都还没有这两个页面，按 android 的归类规则走：
                  //不在「登录/闪屏/协议/备份恢复/PC 确认/媒体预览/通话」那一小撮里的普通内容页
                  //一律进右栏（见 AppPaneRegistry 的注释）。
                  @"WFCUPollDetailViewController",
                  @"WFCUCollectionDetailViewController"];
    });
    return names;
}

+ (BOOL)prefersDetailPane:(UIViewController *)vc {
    UIViewController *page = vc;
    if ([page isKindOfClass:[UINavigationController class]]) {
        //存量代码一律是「套一层导航控制器再模态弹出」，真正的页面是它的根
        page = ((UINavigationController *)page).viewControllers.firstObject;
    }
    if (!page || [self requiresFullScreen:page]) {
        return NO;
    }
    if (page.wfcu_prefersDetailPane) {
        return YES;
    }
    for (NSString *name in [self detailPaneClassNames]) {
        Class cls = NSClassFromString(name);
        if (cls && [page isKindOfClass:cls]) {
            return YES;
        }
    }
    return NO;
}

/// 发起者是不是活在右栏里（含右栏自己弹出的那些模态里）
+ (BOOL)isPresenterInDetailPane:(UIViewController *)presenter {
    UINavigationController *nav = [self detailNavigationController];
    if (!nav) {
        return NO;
    }
    UIViewController *p = presenter;
    while (p) {
        if (p == nav) {
            return YES;
        }
        UIViewController *next = p.parentViewController ?: p.presentingViewController;
        if (next == p) {
            break;
        }
        p = next;
    }
    return NO;
}

+ (BOOL)presentInDetailPaneIfNeeded:(UIViewController *)vcToPresent
                               from:(UIViewController *)presenter
                           animated:(BOOL)animated
                         completion:(void (^)(void))completion {
    if (![self isSplitLayoutActive] || ![self prefersDetailPane:vcToPresent]) {
        return NO;
    }
    UINavigationController *nav = [self detailNavigationController];
    if (!nav.viewIfLoaded.window) {
        //右栏还没上屏，没有可用的呈现上下文，退回原路径
        return NO;
    }
    if ([self isPresenterInDetailPane:presenter]) {
        //已经在右栏里发起的：原地弹即可，CurrentContext 会向上找到右栏导航控制器
        vcToPresent.modalPresentationStyle = UIModalPresentationCurrentContext;
        return NO;
    }
    //左栏发起的（会话列表的「+」、通讯录、我 里的那些入口）：必须改由右栏来弹。
    //否则 CurrentContext 向上找到的是左栏那条 320pt 宽的导航控制器，页面会缩在左边一条里。
    //对应 android 的「左栏发起 → 内容出现在右栏」，只是 iOS 这边保持了模态形态。
    UIViewController *host = nav;
    while (host.presentedViewController) {
        host = host.presentedViewController;
    }
    vcToPresent.modalPresentationStyle = UIModalPresentationCurrentContext;
    [host presentViewController:vcToPresent animated:animated completion:completion];
    return YES;
}

/// actionSheet 的兜底锚点：当前 window 的根视图
+ (UIView *)anchorViewFallback {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
            if (window) break;
        }
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window.rootViewController.view ?: window;
}

+ (CGFloat)layoutWidthForView:(UIView *)view {
    //iPhone 上这些页面恒等于整屏宽，原样返回屏幕宽，取值逐字节不变。
    //（不是「公式上等价」而是直接分叉：iPad 上才有右栏这回事。）
    if (![self isPad]) {
        return [UIScreen mainScreen].bounds.size.width;
    }
    CGFloat width = view.bounds.size.width;
    if (width > 0) {
        return width;
    }
    //页面还没上屏（frame 还是 zero），只能先按屏幕宽排。这类页面都另配了
    //autoresizing，等真宽度下来会自己纠回去。
    return [UIScreen mainScreen].bounds.size.width;
}

#pragma mark - 左栏顶部的搜索框

+ (void)installSearchTriggerOnSearchBar:(UISearchBar *)searchBar
                                 target:(id)target
                                 action:(SEL)action {
    if (![self isPad] || !searchBar) {
        return;
    }
    WFCUPadSearchTriggerGate *gate = [[WFCUPadSearchTriggerGate alloc] init];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    tap.delegate = gate;
    //手势的 delegate 是 assign 的，得找个地方把守卫拴住
    objc_setAssociatedObject(searchBar, kWFCUPadSearchTriggerKey, gate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [searchBar addGestureRecognizer:tap];
    [self syncSearchTriggerOnSearchBar:searchBar];
}

+ (void)syncSearchTriggerOnSearchBar:(UISearchBar *)searchBar {
    if (![self isPad] || !searchBar) {
        return;
    }
    //没装过触发器的搜索框不归这里管（比如选人页那种模态形态的通讯录，
    //它本来就没有「左栏列表 + 右栏内容」，搜索照旧在本页内进行）。
    if (!objc_getAssociatedObject(searchBar, kWFCUPadSearchTriggerKey)) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        //光装手势不够：输入框自己会吃掉这一下并取焦点。把它关掉，
        //触摸才落到搜索框本体上，交给上面那个手势。
        BOOL split = [self isSplitLayoutActive];
        UITextField *textField = searchBar.searchTextField;
        textField.userInteractionEnabled = !split;
        if (split && textField.isFirstResponder) {
            [searchBar resignFirstResponder];
        }
    }
}

+ (CGFloat)chatContentWidthForViewWidth:(CGFloat)viewWidth {
    if (viewWidth <= 0) {
        viewWidth = [UIScreen mainScreen].bounds.size.width;
    }
    if ([self isPad]) {
        return MIN(viewWidth, WFCUPadChatContentMaxWidth);
    }
    return viewWidth;
}

/// 让右栏容器重排一次：转场期间由 CADisplayLink 每帧驱动，把内容钉回正确位置，
/// 并一直持续到冷却期结束（那一刻系统布局才稳定下来）。
+ (void)relayoutDetailContainerIfNeeded {
    UISplitViewController *svc = gSplitViewController;
    if (!svc || svc.isCollapsed) {
        return;
    }
    UIViewController *secondary = svc.viewControllers.lastObject;
    if (secondary && secondary.isViewLoaded && secondary.view.window) {
        [secondary.view setNeedsLayout];
    }
}

#pragma mark - 模态转场进行中标记

static BOOL gPadModalTransitionInProgress = NO;
static NSUInteger gPadModalTransitionGeneration = 0;
//转场结束时刻（CACurrentMediaTime）。清标记后留一段冷却期：完成回调那一刻系统布局
//还没稳定（nav view 还停在全屏、页面宽度还是过渡值），此刻让 isModalTransitionInProgress
//仍返回 YES，页面就不会按过渡宽度重建宫格，容器也继续钉回，等稳定后再放开。
static CFTimeInterval gPadTransitionEndTime = 0;
static const CFTimeInterval gPadTransitionCooldown = 0.25;
//转场期间每帧驱动右栏容器重钉的定时器。dismiss 动画中系统会改容器里 nav view 的 frame，
//但容器自身的 bounds/安全区没变，viewWillLayoutSubviews 不会被触发——没有这个定时器的话，
//内容会一直停在全屏位置，直到完成回调后的补钉才「往右挪回」。
static CADisplayLink *gPadTransitionDisplayLink = nil;

+ (BOOL)isModalTransitionInProgress {
    if (gPadModalTransitionInProgress) {
        return YES;
    }
    if (gPadTransitionEndTime > 0 &&
        CACurrentMediaTime() - gPadTransitionEndTime < gPadTransitionCooldown) {
        return YES;
    }
    return NO;
}

+ (void)setModalTransitionInProgress:(BOOL)inProgress {
    if (inProgress) {
        gPadModalTransitionGeneration++;
        NSUInteger gen = gPadModalTransitionGeneration;
        gPadModalTransitionInProgress = YES;
        gPadTransitionEndTime = 0;
        [self startTransitionDisplayLink];
        //present/dismiss 的完成回调正常都会把标记清掉；万一没走（present 被系统拒绝、
        //「already presenting」等，完成回调不保证被调），0.8s 后兜底清一次，
        //别让右栏容器永远跳过重钉。只清自己这一代，不干扰后来的转场。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (gPadModalTransitionGeneration == gen && gPadModalTransitionInProgress) {
                [self setModalTransitionInProgress:NO];
            }
        });
    } else {
        gPadModalTransitionInProgress = NO;
        gPadTransitionEndTime = CACurrentMediaTime();
        //冷却期结束再停定时器：期间容器仍每帧把右栏钉回正确位置。
        NSUInteger gen = gPadModalTransitionGeneration;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(gPadTransitionCooldown * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (gPadModalTransitionGeneration == gen && !gPadModalTransitionInProgress) {
                [self stopTransitionDisplayLink];
            }
        });
    }
}

+ (void)startTransitionDisplayLink {
    if (gPadTransitionDisplayLink) {
        return;
    }
    gPadTransitionDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(transitionDisplayLinkTick)];
    [gPadTransitionDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

+ (void)transitionDisplayLinkTick {
    //每帧让右栏容器重钉一次：系统在转场里改了 nav view 的 frame，容器自身的
    //viewWillLayoutSubviews 未必会被触发，靠这里强制排一次，把内容拉回正确位置。
    [self relayoutDetailContainerIfNeeded];
}

+ (void)stopTransitionDisplayLink {
    [gPadTransitionDisplayLink invalidate];
    gPadTransitionDisplayLink = nil;
}

@end

#pragma mark - UIViewController (WFCUPad)

static const void *kWFCUPrefersPrimaryColumnKey = &kWFCUPrefersPrimaryColumnKey;
static const void *kWFCUPrefersFullScreenKey = &kWFCUPrefersFullScreenKey;
static const void *kWFCUPrefersDetailPaneKey = &kWFCUPrefersDetailPaneKey;
static const void *kWFCUPadDetailRootKey = &kWFCUPadDetailRootKey;
static const void *kWFCUPadPageKeyKey = &kWFCUPadPageKeyKey;

@implementation UIViewController (WFCUPad)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method origin = class_getInstanceMethod(self, @selector(presentViewController:animated:completion:));
        Method swizzled = class_getInstanceMethod(self, @selector(wfcu_presentViewController:animated:completion:));
        if (origin && swizzled) {
            method_exchangeImplementations(origin, swizzled);
        }
        //模态收回时也要维护转场标记（present 那一侧只罩住弹起，罩不住收回动画那一段）
        Method dismissOrigin = class_getInstanceMethod(self, @selector(dismissViewControllerAnimated:completion:));
        Method dismissSwizzled = class_getInstanceMethod(self, @selector(wfcu_dismissViewControllerAnimated:completion:));
        if (dismissOrigin && dismissSwizzled) {
            method_exchangeImplementations(dismissOrigin, dismissSwizzled);
        }
    });
}

- (BOOL)wfcu_prefersPrimaryColumn {
    return [objc_getAssociatedObject(self, kWFCUPrefersPrimaryColumnKey) boolValue];
}

- (void)setWfcu_prefersPrimaryColumn:(BOOL)wfcu_prefersPrimaryColumn {
    objc_setAssociatedObject(self, kWFCUPrefersPrimaryColumnKey, @(wfcu_prefersPrimaryColumn), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)wfcu_prefersFullScreen {
    return [objc_getAssociatedObject(self, kWFCUPrefersFullScreenKey) boolValue];
}

- (void)setWfcu_prefersFullScreen:(BOOL)wfcu_prefersFullScreen {
    objc_setAssociatedObject(self, kWFCUPrefersFullScreenKey, @(wfcu_prefersFullScreen), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)wfcu_prefersDetailPane {
    return [objc_getAssociatedObject(self, kWFCUPrefersDetailPaneKey) boolValue];
}

- (void)setWfcu_prefersDetailPane:(BOOL)wfcu_prefersDetailPane {
    objc_setAssociatedObject(self, kWFCUPrefersDetailPaneKey, @(wfcu_prefersDetailPane), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)wfcu_padDetailRootViewController {
    return objc_getAssociatedObject(self, kWFCUPadDetailRootKey);
}

- (void)setWfcu_padDetailRootViewController:(UIViewController *)wfcu_padDetailRootViewController {
    objc_setAssociatedObject(self, kWFCUPadDetailRootKey, wfcu_padDetailRootViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)wfcu_padPageKey {
    return objc_getAssociatedObject(self, kWFCUPadPageKeyKey);
}

- (void)setWfcu_padPageKey:(NSString *)wfcu_padPageKey {
    objc_setAssociatedObject(self, kWFCUPadPageKeyKey, [wfcu_padPageKey copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//iPad 上 actionSheet / 分享面板必须有 popover 锚点，否则直接崩溃。
//项目里有三十多处 actionSheet，统一在这里兜底，避免逐个改动时漏掉。
- (void)wfcu_presentViewController:(UIViewController *)vcToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    //转场期间安全区是过渡值，右栏容器要跳过重钉（presentedViewController 在
    //dismiss 一开始就清掉了，覆盖不了收回动画那一段，所以单独用这个标记）
    [WFCUPadUtility setModalTransitionInProgress:YES];
    void (^wrappedCompletion)(void) = ^{
        [WFCUPadUtility setModalTransitionInProgress:NO];
        if (completion) {
            completion();
        }
    };
    if ([WFCUPadUtility isPad]) {
        //已经是模态弹出、但被系统默认成 pageSheet 卡片的媒体预览，拉回全屏。
        //push 出来的那一路在导航控制器里拦（见 WFCUPadPrimaryNavigationController /
        //右栏的导航控制器），两条路径合起来才是完整的 R6。
        UIModalPresentationStyle style = vcToPresent.modalPresentationStyle;
        BOOL sheetLike = (style == UIModalPresentationPageSheet || style == UIModalPresentationFormSheet);
        if (@available(iOS 13.0, *)) {
            //iOS 13 起没显式设过 style 的模态默认就是 Automatic，在 iPad 上落成 pageSheet
            sheetLike = sheetLike || style == UIModalPresentationAutomatic;
        }
        if (sheetLike && [WFCUPadUtility requiresFullScreen:vcToPresent]) {
            vcToPresent.modalPresentationStyle = UIModalPresentationFullScreen;
        }

        //只该占右栏的那一批（转发、选人、改一段文字…）：限制在右栏里弹，别盖住左栏。
        //左栏发起的会被改由右栏代弹，此时本方法已经把它弹出去了。
        if ([WFCUPadUtility presentInDetailPaneIfNeeded:vcToPresent from:self animated:flag completion:wrappedCompletion]) {
            return;
        }

        UIPopoverPresentationController *popover = nil;
        if ([vcToPresent isKindOfClass:[UIAlertController class]]) {
            UIAlertController *alert = (UIAlertController *)vcToPresent;
            if (alert.preferredStyle == UIAlertControllerStyleActionSheet) {
                popover = alert.popoverPresentationController;
            }
        } else if ([vcToPresent isKindOfClass:[UIActivityViewController class]]) {
            popover = vcToPresent.popoverPresentationController;
        }

        if (popover && !popover.sourceView && !popover.barButtonItem) {
            UIView *anchor = self.isViewLoaded ? self.view : nil;
            if (!anchor.window) {
                anchor = [WFCUPadUtility anchorViewFallback];
            }
            if (anchor) {
                popover.sourceView = anchor;
                popover.sourceRect = CGRectMake(CGRectGetMidX(anchor.bounds), CGRectGetMaxY(anchor.bounds), 1, 1);
                //不带箭头，居中偏下弹出，观感接近微信 iPad 的操作面板
                popover.permittedArrowDirections = (UIPopoverArrowDirection)0;
            }
        }
    }
    [self wfcu_presentViewController:vcToPresent animated:flag completion:wrappedCompletion];
}

- (void)wfcu_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    //转场期间安全区是过渡值，右栏容器要跳过重钉；完成回调里清标记。
    //displaylink 会持续到冷却期结束，期间容器每帧钉回，不需要在这里补发。
    [WFCUPadUtility setModalTransitionInProgress:YES];
    [self wfcu_dismissViewControllerAnimated:flag completion:^{
        [WFCUPadUtility setModalTransitionInProgress:NO];
        if (completion) {
            completion();
        }
    }];
}

@end
