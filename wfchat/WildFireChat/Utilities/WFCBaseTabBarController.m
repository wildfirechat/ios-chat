//
//  WFCBaseTabBarController.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCBaseTabBarController.h"
#import "WFCPadMainViewController.h"
#import "WFCWorkPlatformViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "DiscoverViewController.h"
#import "WFCMeTableViewController.h"
#import "WFCConfig.h"
#ifdef WFC_MOMENTS
#import <WFMomentUIKit/WFMomentUIKit.h>
#import <WFMomentClient/WFMomentClient.h>
#endif
#import "UIImage+ERCategory.h"
#define kClassKey   @"rootVCClassString"
#define kTitleKey   @"title"
#define kImgKey     @"imageName"
#define kSelImgKey  @"selectedImageName"

@interface WFCPadTabNavigationController : UINavigationController
@end

@implementation WFCPadTabNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    WFCBaseTabBarController *tabVC = (WFCBaseTabBarController *)self.tabBarController;
    if ([tabVC isKindOfClass:[WFCBaseTabBarController class]] && tabVC.padController) {
        if ([tabVC.padController shouldShowInDetailPanel:viewController]) {
            [tabVC.padController showDetailViewController:viewController];
            return;
        }
    }
    [super pushViewController:viewController animated:animated];
}

@end

@interface WFCBaseTabBarController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong)UINavigationController *firstNav;
@property (nonatomic, strong)UINavigationController *settingNav;
@property (nonatomic, strong)WFCUConversationTableViewController *conversationsViewController;
@end

@implementation WFCBaseTabBarController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.conversationsViewController = [WFCUConversationTableViewController new];
    UIViewController *vc = self.conversationsViewController;
    vc.title = LocalizedString(@"Message");
    UINavigationController *nav = [[WFCPadTabNavigationController alloc] initWithRootViewController:vc];
    UITabBarItem *item = nav.tabBarItem;
    item.title = LocalizedString(@"Message");
    item.image = [UIImage imageNamed:@"tabbar_chat"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_chat_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    doubleTap.cancelsTouchesInView = NO;
    doubleTap.delaysTouchesBegan = NO;
    doubleTap.delaysTouchesEnded = NO;
    [self.tabBar addGestureRecognizer:doubleTap];
    
    self.firstNav = nav;
    
 
    vc = [WFCUContactListViewController new];
    vc.title = LocalizedString(@"Contact");
    nav = [[WFCPadTabNavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = LocalizedString(@"Contact");
    item.image = [UIImage imageNamed:@"tabbar_contacts"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_contacts_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    if(WORK_PLATFORM_URL.length) {
        WFCWorkPlatformViewController *browserVC = [WFCWorkPlatformViewController new];
        browserVC.url = WORK_PLATFORM_URL;
        browserVC.hidenOpenInBrowser = YES;
        
        vc = browserVC;
        vc.title = LocalizedString(@"Work");
        nav = [[WFCPadTabNavigationController alloc] initWithRootViewController:vc];
        item = nav.tabBarItem;
        item.title = LocalizedString(@"Work");
        item.image = [UIImage imageNamed:@"tabbar_work"];
        item.selectedImage = [[UIImage imageNamed:@"tabbar_work_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
        [self addChildViewController:nav];
    }
    
    vc = [DiscoverViewController new];
    vc.title = LocalizedString(@"Discover");
    nav = [[WFCPadTabNavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = LocalizedString(@"Discover");
    item.image = [UIImage imageNamed:@"tabbar_discover"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_discover_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    vc = [WFCMeTableViewController new];
    vc.title = LocalizedString(@"Me");
    nav = [[WFCPadTabNavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = LocalizedString(@"Me");
    item.image = [UIImage imageNamed:@"tabbar_me"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_me_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    self.settingNav = nav;

#ifdef WFC_MOMENTS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUnreadCommentStatusChanged:) name:kReceiveComments object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUnreadCommentStatusChanged:) name:kClearUnreadComments object:nil];
#endif
}

- (void)onDoubleTap:(UITapGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self.tabBar];
    if(location.x < self.tabBar.bounds.size.width/self.tabBar.items.count) {
        //点击第一个tab item。如果消息不是第一个需要调整一下。
        [self.conversationsViewController onTabbarItemDoubleClicked];
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 让双击手势优先于单击手势识别
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)otherGestureRecognizer;
        if (tap.numberOfTapsRequired == 1) {
            return YES;
        }
    }
    return NO;
}

- (void)onUnreadCommentStatusChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBadgeNumber];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBadgeNumber];
}

- (void)updateBadgeNumber {
#ifdef WFC_MOMENTS
    int momentIndex = 2;
    if(WORK_PLATFORM_URL.length)
        momentIndex = 3;
    [self.tabBar showBadgeOnItemIndex:momentIndex badgeValue:[[WFMomentService sharedService] getUnreadCount]];
#endif
}

- (UITraitCollection *)traitCollection {
    if (self.padController) {
        // 在 iPad 分栏模式下强制使用 compact 水平尺寸，防止 tabBar 变成侧边栏
        UITraitCollection *compactWidth = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
        return [UITraitCollection traitCollectionWithTraitsFromCollections:@[[super traitCollection], compactWidth]];
    }
    return [super traitCollection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if([[UIApplication sharedApplication].delegate respondsToSelector:@selector(setupNavBar)]) {
                [[UIApplication sharedApplication].delegate performSelector:@selector(setupNavBar)];
            }
            UIView *superView = self.view.superview;
            [self.view removeFromSuperview];
            [superView addSubview:self.view];
        }
    }
}

@end
