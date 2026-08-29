//
//  WFCUPadPrimaryNavigationController.h
//  WFChat UIKit
//
//  左侧栏（TabBar 的每个 tab）使用的导航控制器。
//  在 iPad 双栏布局下，从 tab 根页面 push 出来的页面会转到右侧详情栏展示，
//  与微信 iPad「左侧只留列表、右侧展示内容」的交互一致；
//  iPhone 上行为与 UINavigationController 完全相同。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUPadPrimaryNavigationController : UINavigationController
@end

NS_ASSUME_NONNULL_END
