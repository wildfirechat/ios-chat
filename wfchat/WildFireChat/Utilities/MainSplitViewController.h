//
//  MainSplitViewController.h
//  WildFireChat
//
//  Created by Claude on 2024/05/22.
//  Copyright © 2024 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainSplitViewController : UIViewController

@property (nonatomic, strong) UIViewController *masterViewController;
@property (nonatomic, strong) UINavigationController *detailNavigationController;

- (void)showDetailViewController:(UINavigationController *)detailVC sender:(id)sender;

@end

NS_ASSUME_NONNULL_END
