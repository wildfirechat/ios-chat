//
//  MainSplitViewController.m
//  WildFireChat
//
//  Created by Claude on 2024/05/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import "MainSplitViewController.h"
#import "WFCBaseTabBarController.h"

@interface MainSplitViewController ()
@property (nonatomic, strong) UIView *masterContainerView;
@property (nonatomic, strong) UIView *detailContainerView;
@property (nonatomic, strong) UIView *separatorView;
@end

@implementation MainSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    // 初始化子视图容器
    [self setupContainerViews];

    // 设置 Master VC (TabBarController)
    self.masterViewController = [[WFCBaseTabBarController alloc] init];
    [self addChildViewController:self.masterViewController];
    [self.masterContainerView addSubview:self.masterViewController.view];
    // Frame will be set in viewDidLayoutSubviews
    [self.masterViewController didMoveToParentViewController:self];

    // 设置初始 Detail VC (占位)
    UIViewController *placeholderVC = [[UIViewController alloc] init];
    placeholderVC.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    UILabel *label = [[UILabel alloc] init];
    label.text = @"WildFire Chat";
    label.textColor = [UIColor lightGrayColor];
    label.font = [UIFont systemFontOfSize:24];
    [label sizeToFit];
    label.center = placeholderVC.view.center;
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [placeholderVC.view addSubview:label];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:placeholderVC];
    [self setDetailNavigationController:nav];
}

- (void)setupContainerViews {
    // Master Container (Left)
    self.masterContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.masterContainerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.masterContainerView];

    // Separator (Middle)
    self.separatorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.separatorView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0];
    [self.view addSubview:self.separatorView];

    // Detail Container (Right)
    self.detailContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.detailContainerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.detailContainerView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat masterWidth = 320.0;
    CGFloat separatorWidth = 1.0; // 0.5 point for retina if needed, but 1.0 is safer for visibility

    CGRect bounds = self.view.bounds;
    CGFloat height = bounds.size.height;
    CGFloat width = bounds.size.width;

    // 确保在小屏幕或分屏下也能正常工作（虽然主要针对 iPad）
    if (width < masterWidth * 2) {
        // Fallback logic if needed, but we are enforcing split view behavior for iPad
    }

    self.masterContainerView.frame = CGRectMake(0, 0, masterWidth, height);
    self.separatorView.frame = CGRectMake(masterWidth, 0, separatorWidth, height);
    self.detailContainerView.frame = CGRectMake(masterWidth + separatorWidth, 0, width - masterWidth - separatorWidth, height);

    if (self.masterViewController) {
        self.masterViewController.view.frame = self.masterContainerView.bounds;
    }

    if (self.detailNavigationController) {
        self.detailNavigationController.view.frame = self.detailContainerView.bounds;
    }
}

- (void)setDetailNavigationController:(UINavigationController *)detailNavigationController {
    if (_detailNavigationController) {
        [_detailNavigationController willMoveToParentViewController:nil];
        [_detailNavigationController.view removeFromSuperview];
        [_detailNavigationController removeFromParentViewController];
    }

    _detailNavigationController = detailNavigationController;

    if (detailNavigationController) {
        [self addChildViewController:detailNavigationController];
        detailNavigationController.view.frame = self.detailContainerView.bounds;
        [self.detailContainerView addSubview:detailNavigationController.view];
        [detailNavigationController didMoveToParentViewController:self];
    }
}

- (void)showDetailViewController:(UINavigationController *)detailVC sender:(id)sender {
    [self setDetailNavigationController:detailVC];
}

@end
