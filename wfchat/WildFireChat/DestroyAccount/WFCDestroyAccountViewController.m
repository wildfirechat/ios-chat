//
//  WFCDestroyAccountViewController.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/7/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCDestroyAccountViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "AppDelegate.h"
#import "WFCBaseTabBarController.h"
#import "MBProgressHUD.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import "WFCPrivacyViewController.h"
#import "AppService.h"
#import "OrgService.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"

@interface WFCDestroyAccountViewController () <UITextFieldDelegate>
@property (strong, nonatomic) UILabel *hintLabel;
@property (strong, nonatomic) UITextField *passwordField;
@property (strong, nonatomic) UIButton *loginBtn;

@property (strong, nonatomic) UIView *passwordLine;

@property (strong, nonatomic) UIButton *sendCodeBtn;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval sendCodeTime;
@end

@implementation WFCDestroyAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    CGRect bgRect = self.view.bounds;
    CGFloat paddingEdge = 16;
    CGFloat inputHeight = 40;
    CGFloat hintHeight = 20;
    CGFloat topPos = [WFCUUtilities wf_navigationFullHeight] + 45;
    
    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge - paddingEdge, hintHeight)];
    [self.hintLabel setText:@"亲，真的要狠心离开我们吗😭😭😭！"];
    self.hintLabel.textAlignment = NSTextAlignmentLeft;
    self.hintLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:hintHeight];
    
    topPos += hintHeight + 100;
    
    
    UIView *passwordContainer  = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge * 2, inputHeight)];
    UILabel *passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, inputHeight - 1)];
    passwordLabel.text = @"验证码";
    passwordLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:17];
    
    
    self.passwordLine = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, passwordContainer.frame.size.width, 1.f)];
    self.passwordLine.backgroundColor = [UIColor colorWithHexString:@"0xd4d4d4"];
    
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(87, 0, passwordContainer.frame.size.width - 87 - 72, inputHeight - 1)];
    self.passwordField.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
    self.passwordField.placeholder = @"请输入验证码";
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.keyboardType = UIKeyboardTypeNumberPad;
    self.passwordField.delegate = self;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.passwordField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.sendCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(passwordContainer.frame.size.width - 72, (inputHeight - 1 - 23) / 2.0, 72, 23)];
    [self.sendCodeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
    self.sendCodeBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    self.sendCodeBtn.layer.borderWidth = 1;
    self.sendCodeBtn.layer.cornerRadius = 4;
    self.sendCodeBtn.layer.borderColor = [UIColor colorWithHexString:@"0x191919"].CGColor;
    [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateNormal];
    [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateSelected];
    [self.sendCodeBtn addTarget:self action:@selector(onSendCode:) forControlEvents:UIControlEventTouchDown];
    
    
    topPos += 71;
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge * 2, 43)];
    [self.loginBtn addTarget:self action:@selector(onLoginButton:) forControlEvents:UIControlEventTouchDown];
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 4.f;
    [self.loginBtn setTitle:@"销毁账户" forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = [UIColor colorWithHexString:@"0xe1e1e1"];
    [self.loginBtn setTitleColor:[UIColor colorWithHexString:@"0xb1b1b1"] forState:UIControlStateNormal];
    self.loginBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:16];
    self.loginBtn.enabled = NO;
    
    [self.view addSubview:self.hintLabel];
    
    
    [self.view addSubview:passwordContainer];
    [passwordContainer addSubview:passwordLabel];
    [passwordContainer addSubview:self.passwordField];
    [passwordContainer addSubview:self.passwordLine];
    [passwordContainer addSubview:self.sendCodeBtn];
    
    [self.view addSubview:self.loginBtn];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetKeyboard:)]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSendCode:(id)sender {
    self.sendCodeBtn.enabled = NO;
    [self.sendCodeBtn setTitle:@"短信发送中" forState:UIControlStateNormal];
    __weak typeof(self)ws = self;
    [[AppService sharedAppService] sendDestroyAccountCode:^{
       [ws sendCodeDone:YES];
    } error:^(int errorCode, NSString * _Nonnull message) {
        [ws sendCodeDone:NO];
    }];
}

- (void)updateCountdown:(id)sender {
    int second = (int)([NSDate date].timeIntervalSince1970 - self.sendCodeTime);
    [self.sendCodeBtn setTitle:[NSString stringWithFormat:@"%ds", 60-second] forState:UIControlStateNormal];
    if (second >= 60) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        [self.sendCodeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
        self.sendCodeBtn.enabled = YES;
    }
}
- (void)sendCodeDone:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = @"发送成功";
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            self.sendCodeTime = [NSDate date].timeIntervalSince1970;
            self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                target:self
                                                                 selector:@selector(updateCountdown:)
                                                              userInfo:nil
                                                               repeats:YES];
            [self.countdownTimer fire];
            
            
            [hud hideAnimated:YES afterDelay:1.f];
        } else {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = @"发送失败";
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.sendCodeBtn setTitle:@"获取验证码" forState:UIControlStateNormal];
                self.sendCodeBtn.enabled = YES;
            });
        }
    });
}

- (void)resetKeyboard:(id)sender {
    [self.passwordField resignFirstResponder];
    self.passwordLine.backgroundColor = [UIColor grayColor];
}

- (void)onLoginButton:(id)sender {
    NSString *password = self.passwordField.text;
  
    if (!password.length) {
        return;
    }
    
    [self resetKeyboard:nil];
    
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.label.text = @"登录中...";
  [hud showAnimated:YES];
    [[AppService sharedAppService] destroyAccount:password success:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
        [[AppService sharedAppService] clearAppServiceAuthInfos];
        [[OrgService sharedOrgService] clearOrgServiceAuthInfos];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        //服务器已经删除所有信息了，这里都传NO。不能传YES，如果传YES协议栈会需要跟IM服务进行交互。
        [[WFCCNetworkService sharedInstance] disconnect:NO clearSession:NO];
    } error:^(int errCode, NSString * _Nonnull message) {
        NSLog(@"login error with code %d, message %@", errCode, message);
      dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"登录失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
      });
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.passwordField) {
        [self onLoginButton:nil];
    }
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.passwordField) {
        self.passwordLine.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    }
    return YES;
}
#pragma mark - UITextInputDelegate
- (void)textDidChange:(id<UITextInput>)textInput {
    if (textInput == self.passwordField) {
        [self updateBtn];
    }
}

- (void)updateBtn {
    if (!self.countdownTimer) {
        self.sendCodeBtn.enabled = YES;
        [self.sendCodeBtn setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
        self.sendCodeBtn.layer.borderColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9].CGColor;
    } else {
        self.sendCodeBtn.enabled = NO;
        self.sendCodeBtn.layer.borderColor = [UIColor colorWithHexString:@"0x191919"].CGColor;
        [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateNormal];
        [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateSelected];
    }
    
    if ([self isValidCode]) {
        [self.loginBtn setBackgroundColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]];
        
        self.loginBtn.enabled = YES;
    } else {
        [self.loginBtn setBackgroundColor:[UIColor grayColor]];
        self.loginBtn.enabled = NO;
    }
}

- (BOOL)isValidCode {
    if (self.passwordField.text.length >= 4) {
        return YES;
    } else {
        return NO;
    }
}
@end
