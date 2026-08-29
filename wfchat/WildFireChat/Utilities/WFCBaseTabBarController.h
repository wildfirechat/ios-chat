//
//  WFCBaseTabBarController.h
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCBaseTabBarController : UITabBarController

/// 主界面根控制器。iPad 上返回微信风格的双栏容器（左侧 TabBar + 列表，右侧详情），
/// iPhone 上就是 TabBar 本身。
+ (UIViewController *)rootViewController;

/// 从 rootViewController 返回的容器里取出 TabBar（iPad 上根是双栏容器，TabBar 在左栏里）
+ (WFCBaseTabBarController *)tabBarControllerInRoot:(UIViewController *)rootViewController;

@end
