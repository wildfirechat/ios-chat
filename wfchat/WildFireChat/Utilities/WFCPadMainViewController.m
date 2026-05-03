//
//  WFCPadMainViewController.m
//  Wildfire Chat
//

#import "WFCPadMainViewController.h"
#import "WFCPadModeManager.h"
#import "WFCBaseTabBarController.h"
#import "WFCWorkPlatformViewController.h"
#import "DiscoverViewController.h"
#import "WFCMeTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>

#define kMiddleWidth 340.0

@interface WFCPadMainViewController ()

@property (nonatomic, strong) UIView *middleContainer;
@property (nonatomic, strong) UIView *detailContainer;
@property (nonatomic, strong) WFCBaseTabBarController *tabBarController;
@property (nonatomic, strong) UINavigationController *detailNav;

@end

@implementation WFCPadMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupContainers];
    [self setupContent];
}

- (void)setupContainers {
    self.middleContainer = [[UIView alloc] init];
    self.middleContainer.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.middleContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.middleContainer];
    
    self.detailContainer = [[UIView alloc] init];
    self.detailContainer.backgroundColor = [UIColor whiteColor];
    self.detailContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.detailContainer];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.middleContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.middleContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.middleContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.middleContainer.widthAnchor constraintEqualToConstant:kMiddleWidth],
        
        [self.detailContainer.leadingAnchor constraintEqualToAnchor:self.middleContainer.trailingAnchor],
        [self.detailContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.detailContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.detailContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)setupContent {
    self.tabBarController = [[WFCBaseTabBarController alloc] init];
    self.tabBarController.padController = self;
    self.tabBarController.edgesForExtendedLayout = UIRectEdgeNone;
    [self addChildViewController:self.tabBarController];
    self.tabBarController.view.frame = self.middleContainer.bounds;
    self.tabBarController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.middleContainer addSubview:self.tabBarController.view];
    [self.tabBarController didMoveToParentViewController:self];
    
    if (@available(iOS 8.0, *)) {
        UITraitCollection *compact = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact];
        [self setOverrideTraitCollection:compact forChildViewController:self.tabBarController];
    }
    
    self.detailNav = [[UINavigationController alloc] init];
    [self addChildViewController:self.detailNav];
    self.detailNav.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.detailContainer addSubview:self.detailNav.view];
    [NSLayoutConstraint activateConstraints:@[
        [self.detailNav.view.leadingAnchor constraintEqualToAnchor:self.detailContainer.leadingAnchor],
        [self.detailNav.view.trailingAnchor constraintEqualToAnchor:self.detailContainer.trailingAnchor],
        [self.detailNav.view.topAnchor constraintEqualToAnchor:self.detailContainer.topAnchor],
        [self.detailNav.view.bottomAnchor constraintEqualToAnchor:self.detailContainer.bottomAnchor]
    ]];
    [self.detailNav didMoveToParentViewController:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.detailNav.view.frame = self.detailContainer.bounds;
}

// 默认所有页面都进右侧详情区，只有固定在左侧栏的 Tab 根页面除外
- (BOOL)shouldShowInDetailPanel:(UIViewController *)vc {
    if ([vc isKindOfClass:[WFCUConversationTableViewController class]]
        || [vc isKindOfClass:[WFCUContactListViewController class]]
        || [vc isKindOfClass:[WFCWorkPlatformViewController class]]
        || [vc isKindOfClass:[DiscoverViewController class]]
        || [vc isKindOfClass:[WFCMeTableViewController class]]
        || [vc isKindOfClass:[WFCUFavGroupTableViewController class]]
        ) {
        return NO;
    }
    return YES;
}

- (void)showDetailViewController:(UIViewController *)vc {
    [self.view layoutIfNeeded];
    [self.detailNav setViewControllers:@[vc] animated:NO];
}

@end
