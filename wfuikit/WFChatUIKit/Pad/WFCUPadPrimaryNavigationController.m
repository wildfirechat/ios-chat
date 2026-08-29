//
//  WFCUPadPrimaryNavigationController.m
//  WFChat UIKit
//

#import "WFCUPadPrimaryNavigationController.h"
#import "WFCUPadUtility.h"

@implementation WFCUPadPrimaryNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //必须全屏的页面（媒体预览这类）优先，且不看栈深：它既不该留在左栏，也不该只盖住右栏
    if ([WFCUPadUtility presentFullScreenIfNeeded:viewController animated:animated]) {
        return;
    }
    //只有从 tab 根页面发起的 push 才转到右侧栏；
    //右侧栏内部（比如聊天页 -> 聊天设置）的 push 走的是详情栏自己的导航栈，不会进到这里。
    if (self.viewControllers.count == 1
        && !viewController.wfcu_prefersPrimaryColumn
        && [WFCUPadUtility isSplitLayoutActive]
        && [WFCUPadUtility showDetailViewController:viewController]) {
        return;
    }
    [super pushViewController:viewController animated:animated];
}

@end
