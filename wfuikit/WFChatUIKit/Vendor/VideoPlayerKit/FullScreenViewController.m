/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "FullScreenViewController.h"
#import "FullScreenView.h"

@interface FullScreenViewController ()
@property (nonatomic, strong) FullScreenView *fullScreenView;
@end

@implementation FullScreenViewController

- (id)init
{
    if (self = [super init]) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    
    return self;
}

- (void)loadView
{
    self.fullScreenView = [[FullScreenView alloc] init];
    [self setView:self.fullScreenView];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (!self.allowPortraitFullscreen) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (!self.allowPortraitFullscreen) {
        return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
    } else {
        return YES;
    }
}

@end
