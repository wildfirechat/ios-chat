//
//  WFCBaseTabBarController.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCBaseTabBarController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "DiscoverViewController.h"
#import "WFCMeTableViewController.h"

#define kClassKey   @"rootVCClassString"
#define kTitleKey   @"title"
#define kImgKey     @"imageName"
#define kSelImgKey  @"selectedImageName"

@interface WFCBaseTabBarController ()
@property (nonatomic, strong)UINavigationController *firstNav;
@property (nonatomic, strong)UINavigationController *settingNav;
@end

@implementation WFCBaseTabBarController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIViewController *vc = [WFCUConversationTableViewController new];
    vc.title = @"消息";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    UITabBarItem *item = nav.tabBarItem;
    item.title = @"消息";
    item.image = [UIImage imageNamed:@"tabbar_chat"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_chat_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    self.firstNav = nav;
    
 
    vc = [WFCUContactListViewController new];
    vc.title = @"联系人";
    nav = [[UINavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = @"联系人";
    item.image = [UIImage imageNamed:@"tabbar_contacts"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_contacts_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    vc = [DiscoverViewController new];
    vc.title = @"发现";
    nav = [[UINavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = @"发现";
    item.image = [UIImage imageNamed:@"tabbar_discover"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_discover_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    vc = [WFCMeTableViewController new];
    vc.title = @"设置";
    nav = [[UINavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = @"设置";
    item.image = [UIImage imageNamed:@"tabbar_me"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_me_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    self.settingNav = nav;
}

- (void)setNewUser:(BOOL)newUser {
    if (newUser) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"欢迎注册" message:@"请更新您头像和昵称，以便您的朋友能更好地识别！" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                self.selectedViewController = self.settingNav;
            }];
            [alertController addAction:action];
            NSLog(@"hahahah");
            [self.firstNav presentViewController:alertController animated:YES completion:nil];
        });
    }
}
@end
