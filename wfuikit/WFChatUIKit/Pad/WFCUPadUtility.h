//
//  WFCUPadUtility.h
//  WFChat UIKit
//
//  iPad 适配的公共入口，交互参考微信 iPad 版：
//  左侧固定列表栏（会话/通讯录/发现/我 + 底部 TabBar），右侧详情栏。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 左栏宽度。取值与 android-chat 一致：`values/dimens.xml` 320dp，
/// `values-sw840dp/dimens.xml` 360dp（即 12.9/13 寸这一档）。
UIKIT_EXTERN const CGFloat WFCUPadPrimaryColumnWidth;
UIKIT_EXTERN const CGFloat WFCUPadPrimaryColumnWideWidth;
/// 用 WFCUPadPrimaryColumnWideWidth 的屏幕短边阈值，对应 android 的 sw840dp
UIKIT_EXTERN const CGFloat WFCUPadWideScreenMinDimension;

/// 聊天内容区最大宽度。iPad 横屏时聊天栏很宽，气泡若铺满整行会很难读，微信也做了收窄。
UIKIT_EXTERN const CGFloat WFCUPadChatContentMaxWidth;

/// 宽屏下表单类内容（二维码卡片、输入一段文字这类）的最大宽度。
/// 取自 android `values-sw600dp/dimens.xml` 的 `wfc_form_max_width`：
/// 「平板整宽拉伸的输入框既难看也难用，统一约束后居中显示。」
UIKIT_EXTERN const CGFloat WFCUPadFormMaxWidth;

/// 详情栏内容发生变化，左侧列表据此更新选中态
UIKIT_EXTERN NSString *const WFCUPadDetailDidChangeNotification;

@interface WFCUPadUtility : NSObject

/// 是否 iPad 设备
+ (BOOL)isPad;

/// 当前是否处于 iPad 双栏布局。iPad 上进入 Slide Over（compact 宽度）时会退回单栏，此时返回 NO。
+ (BOOL)isSplitLayoutActive;

/// 当前的分栏控制器，iPhone 上为 nil
+ (nullable UISplitViewController *)splitViewController;
+ (void)setSplitViewController:(nullable UISplitViewController *)splitViewController;

/// 把 vc 展示到右侧详情栏（「换内容」：退到栈底的欢迎页再压入）。
/// 返回 NO 表示当前不是双栏布局，调用方应按原逻辑 push。
+ (BOOL)showDetailViewController:(UIViewController *)vc;

/// 把 vc 压在右栏当前页面**之上**，不清栈。
/// 对应 android `TwoPaneNavigator.openInPane(resetFirst = false)`：调用方本身就在右栏里时，
/// 新页面是往下钻一层，而不是换一屏内容。返回 NO 表示当前不是双栏布局。
+ (BOOL)pushDetailViewController:(UIViewController *)vc animated:(BOOL)animated;

/// 用 vc 顶替右栏栈顶的那一页，被顶替的那一页从栈上消失。
/// 对应 android `TwoPaneNavigator.replacePage`，注释是「从『发起群聊』的选人页建完群，
/// 选人页就该消失」—— 会话建好之后再返回到选人页是没有意义的。
/// 栈底（欢迎页 / 工作台网页）不会被顶替，返回键始终有地方可退。
/// 返回 NO 表示当前不是双栏布局。
+ (BOOL)replaceDetailViewController:(UIViewController *)vc animated:(BOOL)animated;

/// 详情栏回到占位页
+ (void)resetDetailViewController;

/// 这个页面必须占满整个窗口（媒体预览这类），不能只盖住右栏。
/// 对应 android `PaneRegistry`：没登记进右栏的页面一律走原路径全屏打开。
+ (BOOL)requiresFullScreen:(UIViewController *)vc;

/// 双栏布局下，把必须全屏的页面改为全屏模态盖住整个分栏。
/// 返回 YES 表示已经弹出，调用方不要再 push；非双栏或该页面不需要全屏时返回 NO。
+ (BOOL)presentFullScreenIfNeeded:(UIViewController *)vc animated:(BOOL)animated;

/// 这个页面在双栏下只该占右栏，不该盖住整个窗口（转发、选人、改一段文字这类模态）。
/// 对应 android `PaneRegistry` 里登记进右栏的那一批。
+ (BOOL)prefersDetailPane:(UIViewController *)vc;

/// 双栏布局下，把「只该占右栏」的模态限制在右栏里弹。
/// 返回 YES 表示已经代为弹出，调用方不要再弹一次；返回 NO 表示照原样弹
/// （可能已经改过 modalPresentationStyle）。
+ (BOOL)presentInDetailPaneIfNeeded:(UIViewController *)vcToPresent
                               from:(UIViewController *)presenter
                           animated:(BOOL)animated
                         completion:(nullable void (^)(void))completion;

/// 详情栏当前的根控制器（即右侧正在展示的主页面），非双栏布局时为 nil
+ (nullable UIViewController *)currentDetailRootViewController;

/// 当前设备的左栏宽度
+ (CGFloat)primaryColumnWidth;

/// 左栏切了 tab，把右栏换成那个 tab 自己的栈。非 iPad / 非双栏时什么都不做。
+ (void)syncDetailStackForCurrentTab;

/// 把某个 tab 的那条右栏栈退回栈底（欢迎页）。非 iPad / 非双栏时什么都不做。
/// 对应 android `TwoPaneNavigator` 里的 `stacks.get(tab).reset()`。
+ (void)resetDetailStackForTabAtIndex:(NSInteger)index;

/// 在指定宽度下，聊天内容区的可用宽度（已按 iPad 上限收窄）
+ (CGFloat)chatContentWidthForViewWidth:(CGFloat)viewWidth;

/// 排版基准宽度。项目里不少页面是拿 `[UIScreen mainScreen].bounds.size.width` 算 frame 的
/// （资料页、二维码、频道资料…），这些页面在 iPad 右栏里会按整屏宽排：
/// 文字跑到栏外、本该居中的东西偏到一边。
/// iPhone 上原样返回屏幕宽（这些页面恒等于整屏宽，取值一个不变），
/// iPad 上返回页面自己的宽度；页面还没上屏拿不到宽度时退回屏幕宽。
+ (CGFloat)layoutWidthForView:(nullable UIView *)view;

/// 让右栏容器重排一次（转场期间由 CADisplayLink 每帧驱动，把内容钉回正确位置）。
+ (void)relayoutDetailContainerIfNeeded;

/// 当前是否有模态转场在进行（present/dismiss 的 swizzle 钩子维护）。
/// 转场期间安全区是过渡值，右栏容器要跳过重钉。
+ (BOOL)isModalTransitionInProgress;
+ (void)setModalTransitionInProgress:(BOOL)inProgress;

#pragma mark - 左栏顶部的搜索框

/// 双栏下把左栏顶上那条搜索框变成「只是一颗按钮」：点它不取焦点，
/// 只由 `action` 把搜索页压进右栏（搜索框长在那张搜索页自己身上）。
/// 两端的搜索入口本来就是按钮 —— android 主界面是 toolbar 上的 `R.id.search` 菜单项、
/// flutter 是 `_onTapSearchButton`；输入框在 android `search_bar.xml` 那一条里。
/// iPhone 上直接返回，这条路径一行都不跑。
+ (void)installSearchTriggerOnSearchBar:(nullable UISearchBar *)searchBar
                                 target:(id)target
                                 action:(SEL)action;

/// 分栏形态是会变的（旋转、Stage Manager、Slide Over），布局时调一下，
/// 把「这条搜索框能不能取焦点」同步过来。
+ (void)syncSearchTriggerOnSearchBar:(nullable UISearchBar *)searchBar;

@end

@interface UIViewController (WFCUPad)
/// 置为 YES 时，即使在 iPad 双栏布局下也留在左侧栏内 push，而不是跳到右侧详情栏
@property (nonatomic, assign) BOOL wfcu_prefersPrimaryColumn;

/// 置为 YES 时，双栏布局下该页面以全屏模态盖住整个窗口（含左栏），而不是只占右栏。
/// 项目自己的页面用这个标记；第三方/存量类走 `+requiresFullScreen:` 里的名单。
@property (nonatomic, assign) BOOL wfcu_prefersFullScreen;

/// 置为 YES 时，双栏布局下这个页面即使是模态弹出的也只盖住右栏。
/// 存量类走 `+prefersDetailPane:` 里的名单；新写的页面可以直接标这个。
@property (nonatomic, assign) BOOL wfcu_prefersDetailPane;

/// 这个 tab 的左栏根页面所对应的、**常驻右栏**的那一页。
/// 只有工作台是这个形态：它没有「列表 → 详情」的层次，左栏放迎宾面板，网页始终占着右栏，
/// 所以这条栈的栈底不是欢迎页而是网页本身。对应 flutter `PadHome._initialPaneRoutes` 里
/// 那句「工作台 tab 的基座就是工作台本身」。默认 nil，表示这条栈的栈底是欢迎页。
@property (nonatomic, strong, nullable) UIViewController *wfcu_padDetailRootViewController;

/// 右栏页面的去重标识，对应 android 的 `PaneRegistry.pageKeyOf(intent)`。
/// 标识相同的页面视为同一个页面，从左栏再点一次时原地保留而不是重建。
/// 默认 nil，表示不参与去重。有自己一套标识规则的页面重写 getter
/// （见 WFCUMessageListViewController）；没有的，由调用方在压进右栏之前直接赋值
/// （对应 android 那种 `intent -> XxxActivity.class.getName()` 的常量 key）。
@property (nonatomic, strong, nullable) NSString *wfcu_padPageKey;
@end

NS_ASSUME_NONNULL_END
