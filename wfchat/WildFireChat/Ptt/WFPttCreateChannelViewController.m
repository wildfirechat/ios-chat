//
//  WFPttCreateChannelViewController.m
//  PttUIKit
//
//  Created by Hao Jia on 2021/10/14.
//

#ifdef WFC_PTT
#import "WFPttCreateChannelViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <PttClient/WFPttClient.h>

@interface WFPttCreateChannelViewController () <UITextFieldDelegate>
@property(nonatomic, strong)UITextField *titleTextField;
@end

@implementation WFPttCreateChannelViewController
#define Label_Width 80
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, kStatusBarAndNavigationBarHeight + 8, Label_Width, 24)];
    label.text = @"频道名称";
    [self.view addSubview:label];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.titleTextField = [[UITextField alloc] initWithFrame:CGRectMake(16 + Label_Width, kStatusBarAndNavigationBarHeight + 8, self.view.bounds.size.width - 16 - Label_Width - 16, 24)];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    self.titleTextField.text = [NSString stringWithFormat:@"%@的频道", userInfo.displayName];
    self.titleTextField.borderStyle = UITextBorderStyleBezel;
    self.titleTextField.returnKeyType = UIReturnKeyDone;
    self.titleTextField.delegate = self;
    [self.view addSubview:self.titleTextField];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"创建" style:UIBarButtonItemStylePlain target:self action:@selector(onStart:)];
}

- (void)dismiss:(id)sender {
    if (self.navigationController.presentingViewController) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onStart:(id)sender {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    __weak typeof(self)ws = self;
    [[WFPttClient sharedClient] createChannel:nil channelName:self.titleTextField.text channelPortrait:nil maxSpeakerNumber:0 saveVoiceMessage:YES maxSpeakerTime:0 success:^(NSString *cid) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws dismiss:nil];
        });
    } error:^(int errorCode) {
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:@"糟糕，出错了" preferredStyle:UIAlertControllerStyleAlert];
        
        __weak typeof(self)ws = self;
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"等会再试试吧！" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [ws dismiss:nil];
        }];
        
        
        [actionSheet addAction:actionCancel];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
#endif //WFC_PTT
