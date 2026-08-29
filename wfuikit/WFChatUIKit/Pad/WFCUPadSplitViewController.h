//
//  WFCUPadSplitViewController.h
//  WFChat UIKit
//
//  iPad 根容器，参考微信 iPad：
//  左栏固定显示 TabBar + 列表，右栏显示聊天/详情内容，不做左栏隐藏与滑动手势。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUPadSplitViewController : UISplitViewController

/// tabBarController 作为左侧栏，右侧栏自动创建为一个带占位页的导航控制器
- (instancetype)initWithPrimaryViewController:(UITabBarController *)tabBarController;

@property (nonatomic, strong, readonly) UITabBarController *primaryTabBarController;
@property (nonatomic, strong, readonly) UINavigationController *detailNavigationController;

/// 把右栏切换到当前 tab 那条栈上。用户点 TabBar 时会自动调用；
/// 代码里改 selectedIndex 不走 TabBar 的代理，需要显式调一次。
- (void)syncDetailStackForCurrentTab;

@end

NS_ASSUME_NONNULL_END
