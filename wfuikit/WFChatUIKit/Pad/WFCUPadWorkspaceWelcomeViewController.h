//
//  WFCUPadWorkspaceWelcomeViewController.h
//  WFChat UIKit
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 双栏形态下，工作台 tab 的**左栏**。
///
/// 工作台的正文是一整个远端网页，挤进 320pt 宽的左栏没法看，所以左栏让给一块迎宾面板
/// （问候语 + 日期），真正的网页常驻右栏。取自 flutter-chat 的 `PadWorkspaceWelcome`
/// ——那边的原话是「工作台没有『列表 → 详情』的层次」，与 hm-chat 的 `WorkspacePane` 同一套形态。
/// iPhone 不走这里（工作台在手机上就是整页网页）。
///
/// 面板上刻意只放"不点也不动"的静态信息。flutter 那边记过原因：左栏一旦出现可点的入口，
/// 用户就会预期它在右栏里打开，而右栏此刻被工作台网页占着，两者会互相打架。
@interface WFCUPadWorkspaceWelcomeViewController : UIViewController

/// 常驻右栏的那个网页控制器。
- (instancetype)initWithWorkspaceViewController:(UIViewController *)workspaceViewController;

@end

NS_ASSUME_NONNULL_END
