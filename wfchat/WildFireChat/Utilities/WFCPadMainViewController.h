//
//  WFCPadMainViewController.h
//  Wildfire Chat
//

#import <UIKit/UIKit.h>

@interface WFCPadMainViewController : UIViewController

- (BOOL)shouldShowInDetailPanel:(UIViewController *)vc;
- (void)showDetailViewController:(UIViewController *)vc;

@end
