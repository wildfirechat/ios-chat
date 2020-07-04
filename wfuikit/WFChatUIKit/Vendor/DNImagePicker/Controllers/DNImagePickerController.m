//
//  DNImagePickerController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNImagePickerController.h"
#import "DNAlbumTableViewController.h"
#import "DNImageFlowViewController.h"
#import "DNImagePickerHelper.h"

NSString *kDNImagePickerStoredGroupKey = @"com.dennis.kDNImagePickerStoredGroup";


@interface DNImagePickerController ()<UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) id<UINavigationControllerDelegate> navDelegate;
@property (nonatomic, assign) BOOL isDuringPushAnimation;

@end

@implementation DNImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.delegate) {
        self.delegate = self;
    }
    
    self.interactivePopGestureRecognizer.delegate = self;
    
    NSString *propwetyID = [[NSUserDefaults standardUserDefaults] objectForKey:kDNImagePickerStoredGroupKey];

    if (propwetyID.length <= 0) {
        [self showAlbumList];
    } else {
        [self showImageFlow];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - priviate methods
- (void)showAlbumList {
    DNAlbumTableViewController *albumTableViewController = [[DNAlbumTableViewController alloc] init];
    [self setViewControllers:@[albumTableViewController]];
}

- (void)showImageFlow {
    NSString *albumIdentifier = [DNImagePickerHelper albumIdentifier];
    DNAlbumTableViewController *albumTableViewController = [[DNAlbumTableViewController alloc] init];
    DNImageFlowViewController *imageFlowController = [[DNImageFlowViewController alloc] initWithAlbumIdentifier:albumIdentifier];
    [self setViewControllers:@[albumTableViewController,imageFlowController]];
}

- (void)chargeAuthorizationStatus:(DNAlbumAuthorizationStatus)status {
    if (!self.viewControllers.firstObject) {
        [self showAlbumList];
    }

    DNAlbumTableViewController *albumTableViewController = self.viewControllers.firstObject;

    switch (status) {
        case DNAlbumAuthorizationStatusAuthorized:
            // TODO:Authorized
            break;
        case DNAlbumAuthorizationStatusDenied:
        case DNAlbumAuthorizationStatusRestricted:
            [albumTableViewController showUnAuthorizedTipsView];
            break;
        case DNAlbumAuthorizationStatusNotDetermined:
            // TODO: requestAuthorization
            break;
            
        default:
            break;
    }
}

#pragma mark - UINavigationController

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    [super setDelegate:delegate ? self : nil];
    self.navDelegate = delegate != self ? delegate : nil;
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated __attribute__((objc_requires_super))
{
    self.isDuringPushAnimation = YES;
    [super pushViewController:viewController animated:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    self.isDuringPushAnimation = NO;
    if ([self.navDelegate respondsToSelector:_cmd]) {
        [self.navDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        return [self.viewControllers count] > 1 && !self.isDuringPushAnimation;
    } else {
        return YES;
    }
}

#pragma mark - Delegate Forwarder

- (BOOL)respondsToSelector:(SEL)s {
    return [super respondsToSelector:s] || [self.navDelegate respondsToSelector:s];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)s {
    return [super methodSignatureForSelector:s] ?: [(id)self.navDelegate methodSignatureForSelector:s];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    id delegate = self.navDelegate;
    if ([delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:delegate];
    }
}

@end
