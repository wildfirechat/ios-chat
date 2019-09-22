//
//  WFCUVerifyRequestViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2018/11/4.
//  Copyright © 2018 WF Chat. All rights reserved.
//

#import "WFCUVerifyRequestViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "MBProgressHUD.h"
#import "WFCUConfigManager.h"


@interface WFCUVerifyRequestViewController ()
@property(nonatomic, strong)UITextField *verifyField;
@end

@implementation WFCUVerifyRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect clientArea = self.view.bounds;
    UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8 + kStatusBarAndNavigationBarHeight, clientArea.size.width - 16, 16)];
    hintLabel.text = WFCString(@"AddFriendReasonHint");
    hintLabel.font = [UIFont systemFontOfSize:12];
    hintLabel.textColor = [UIColor grayColor];
    [self.view addSubview:hintLabel];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    self.verifyField = [[UITextField alloc] initWithFrame:CGRectMake(0, 32 + kStatusBarAndNavigationBarHeight, clientArea.size.width, 32)];
    WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    self.verifyField.font = [UIFont systemFontOfSize:16];
    self.verifyField.text = [NSString stringWithFormat:WFCString(@"DefaultAddFriendReason"), me.displayName];
    self.verifyField.borderStyle = UITextBorderStyleRoundedRect;
    self.verifyField.clearButtonMode = UITextFieldViewModeAlways;
    
    
    [self.view addSubview:self.verifyField];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Send") style:UIBarButtonItemStyleDone target:self action:@selector(onSend:)];
}


- (void)onSend:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Sending");
    [hud showAnimated:YES];
    
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] sendFriendRequest:self.userId reason:self.verifyField.text success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"Sent");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            [ws.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"SendFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        });
    }];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
