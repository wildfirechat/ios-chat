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
#import "WFCConfig.h"

#import "UIFont+YH.h"
#ifdef WFC_MOMENTS
#import <WFMomentUIKit/WFMomentUIKit.h>
#import <WFMomentClient/WFMomentClient.h>
#endif
#import "UIImage+ERCategory.h"
#define kClassKey   @"rootVCClassString"
#define kTitleKey   @"title"
#define kImgKey     @"imageName"
#define kSelImgKey  @"selectedImageName"

@interface WFCTabBar : UITabBar
@end

@implementation WFCTabBar
- (CGSize)sizeThatFits:(CGSize)size {
    CGSize sizeThatFits = [super sizeThatFits:size];
    // 字体放大时稍微增加 TabBar 高度，但变化幅度远小于字体缩放比例，避免突兀
    CGFloat fontScale = [WFCUConfigManager globalManager].fontScale;
    sizeThatFits.height += (fontScale - 1.0) * 20;
    
    return sizeThatFits;
}
@end

@interface WFCBaseTabBarController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong)UINavigationController *firstNav;
@property (nonatomic, strong)UINavigationController *settingNav;
@property (nonatomic, strong)WFCUConversationTableViewController *conversationsViewController;
@end

@implementation WFCBaseTabBarController
+ (UIViewController *)rootViewController {
    WFCBaseTabBarController *tabBarController = [WFCBaseTabBarController new];
    if ([WFCUPadUtility isPad]) {
        return [[WFCUPadSplitViewController alloc] initWithPrimaryViewController:tabBarController];
    }
    return tabBarController;
}

+ (WFCBaseTabBarController *)tabBarControllerInRoot:(UIViewController *)rootViewController {
    if ([rootViewController isKindOfClass:[UISplitViewController class]]) {
        rootViewController = ((UISplitViewController *)rootViewController).viewControllers.firstObject;
    }
    if ([rootViewController isKindOfClass:[WFCBaseTabBarController class]]) {
        return (WFCBaseTabBarController *)rootViewController;
    }
    return nil;
}

- (void)viewDidLoad {
    // 替换为自定义 TabBar，微调高度随字体变化
    WFCTabBar *tabBar = [[WFCTabBar alloc] init];
    [self setValue:tabBar forKey:@"tabBar"];
    
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFontScaleChanged:)
                                                 name:WFCUFontScaleDidChangeNotification
                                               object:nil];
    
    self.conversationsViewController = [WFCUConversationTableViewController new];
    UIViewController *vc = self.conversationsViewController;
    vc.title = LocalizedString(@"Message");
    UINavigationController *nav = [[WFCUPadPrimaryNavigationController alloc] initWithRootViewController:vc];
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
    nav = [[WFCUPadPrimaryNavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = LocalizedString(@"Contact");
    item.image = [UIImage imageNamed:@"tabbar_contacts"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_contacts_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    if((WORK_PLATFORM_URL ?: WORK_PLATFORM_BACKUP_URL).length) {
        WFCUBrowserViewController *browserVC = [WFCUBrowserViewController new];
        browserVC.url = WFCGetWorkPlatformUrl();
        browserVC.hidenOpenInBrowser = YES;
        browserVC.title = LocalizedString(@"Work");

        //工作台特例：它没有「列表 → 详情」的层次，一整个远端网页挤进 320pt 宽的左栏没法看。
        //iPad 上左栏换成迎宾面板，网页常驻右栏（flutter 的 PadWorkspaceWelcome，
        //android/hm-chat 的 WorkspacePane 也是这一套）。iPhone 上仍然是整页网页，一行没动。
        if([WFCUPadUtility isPad]) {
            vc = [[WFCUPadWorkspaceWelcomeViewController alloc] initWithWorkspaceViewController:browserVC];
        } else {
            vc = browserVC;
        }
        vc.title = LocalizedString(@"Work");
        nav = [[WFCUPadPrimaryNavigationController alloc] initWithRootViewController:vc];
        item = nav.tabBarItem;
        item.title = LocalizedString(@"Work");
        item.image = [UIImage imageNamed:@"tabbar_work"];
        item.selectedImage = [[UIImage imageNamed:@"tabbar_work_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
        [self addChildViewController:nav];
    }
    
    vc = [DiscoverViewController new];
    vc.title = LocalizedString(@"Discover");
    nav = [[WFCUPadPrimaryNavigationController alloc] initWithRootViewController:vc];
    item = nav.tabBarItem;
    item.title = LocalizedString(@"Discover");
    item.image = [UIImage imageNamed:@"tabbar_discover"];
    item.selectedImage = [[UIImage imageNamed:@"tabbar_discover_cover"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]} forState:UIControlStateSelected];
    [self addChildViewController:nav];
    
    vc = [WFCMeTableViewController new];
    vc.title = LocalizedString(@"Me");
    nav = [[WFCUPadPrimaryNavigationController alloc] initWithRootViewController:vc];
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
    
    [self applyTabBarItemFont];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//代码里切 tab 不会走 UITabBarControllerDelegate，右栏得手动换到对应那条栈
- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    [WFCUPadUtility syncDetailStackForCurrentTab];
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    [super setSelectedViewController:selectedViewController];
    [WFCUPadUtility syncDetailStackForCurrentTab];
}

- (NSDictionary *)tabBarTitleAttributes {
    UIFont *font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:10];
    return @{NSFontAttributeName : font};
}

- (void)applyTabBarItemFont {
    for (UINavigationController *nav in self.viewControllers) {
        if (![nav isKindOfClass:[UINavigationController class]]) continue;
        UITabBarItem *item = nav.tabBarItem;
        if (!item) continue;
        NSDictionary *attrs = [self tabBarTitleAttributes];
        [item setTitleTextAttributes:attrs forState:UIControlStateNormal];
        [item setTitleTextAttributes:attrs forState:UIControlStateSelected];
    }
}

- (void)onFontScaleChanged:(NSNotification *)notification {
    [self applyTabBarItemFont];
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
    if((WORK_PLATFORM_URL ?: WORK_PLATFORM_BACKUP_URL).length)
        momentIndex = 3;
    [self.tabBar showBadgeOnItemIndex:momentIndex badgeValue:[[WFMomentService sharedService] getUnreadCount]];
#endif
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
