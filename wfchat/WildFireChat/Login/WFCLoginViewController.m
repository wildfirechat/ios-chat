//
//  WFCLoginViewController.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/7/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCLoginViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "AppDelegate.h"
#import "WFCBaseTabBarController.h"
#import "MBProgressHUD.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import "WFCPrivacyViewController.h"
#import "AppService.h"

//是否iPhoneX YES:iPhoneX屏幕 NO:传统屏幕
#define kIs_iPhoneX ([UIScreen mainScreen].bounds.size.height == 812.0f ||[UIScreen mainScreen].bounds.size.height == 896.0f )

#define kStatusBarAndNavigationBarHeight (kIs_iPhoneX ? 88.f : 64.f)

#define  kTabbarSafeBottomMargin        (kIs_iPhoneX ? 34.f : 0.f)

#define HEXCOLOR(rgbValue)                                                                                             \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0                                               \
green:((float)((rgbValue & 0xFF00) >> 8)) / 255.0                                                  \
blue:((float)(rgbValue & 0xFF)) / 255.0                                                           \
alpha:1.0]

@interface WFCLoginViewController () <UITextFieldDelegate>
@property (strong, nonatomic) UILabel *hintLabel;
@property (strong, nonatomic) UITextField *userNameField;
@property (strong, nonatomic) UITextField *passwordField;
@property (strong, nonatomic) UIButton *loginBtn;

@property (strong, nonatomic) UIView *userNameLine;
@property (strong, nonatomic) UIView *passwordLine;

@property (strong, nonatomic) UIButton *sendCodeBtn;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval sendCodeTime;
@property (nonatomic, strong) UILabel *privacyLabel;
@end

@implementation WFCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    NSString *savedName = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedName"];
   
    CGRect bgRect = self.view.bounds;
    CGFloat paddingEdge = 40;
    
    CGFloat paddingTF2Line = 12;
    CGFloat paddingLine2TF = 24;
    CGFloat sendCodeBtnwidth = 120;
    CGFloat paddingField2Code = 8;
    
    CGFloat topPos = kStatusBarAndNavigationBarHeight + 45;
    CGFloat fieldHeight = 25;
    
    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge - paddingEdge, fieldHeight*2)];
    [self.hintLabel setText:@"手机验证码登陆"];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.font = [UIFont systemFontOfSize:fieldHeight];
    
    topPos += fieldHeight * 2 + 10;
    
    self.userNameLine = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos + paddingTF2Line + fieldHeight, bgRect.size.width - paddingEdge - paddingEdge, 1.f)];
    self.userNameLine.backgroundColor = [UIColor grayColor];
    
    
    self.userNameField = [[UITextField alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge - paddingEdge, fieldHeight)];
    self.userNameField.placeholder = @"请输入手机号(仅支持中国大陆号码)";
    self.userNameField.returnKeyType = UIReturnKeyNext;
    self.userNameField.keyboardType = UIKeyboardTypePhonePad;
    self.userNameField.delegate = self;
    self.userNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.userNameField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    

    self.passwordLine = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos + paddingTF2Line + fieldHeight + paddingLine2TF + fieldHeight + paddingTF2Line, bgRect.size.width - paddingEdge - paddingEdge, 1.f)];
    self.passwordLine.backgroundColor = [UIColor grayColor];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(paddingEdge, topPos + paddingTF2Line + fieldHeight + paddingLine2TF, bgRect.size.width - paddingEdge - paddingEdge - sendCodeBtnwidth - paddingField2Code, fieldHeight)];
    self.passwordField.placeholder = @"请输入短信验证码";
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.keyboardType = UIKeyboardTypeNumberPad;
    self.passwordField.delegate = self;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.passwordField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.sendCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(bgRect.size.width - paddingEdge - sendCodeBtnwidth, topPos + paddingTF2Line + fieldHeight + paddingLine2TF, sendCodeBtnwidth, fieldHeight)];
    [self.sendCodeBtn setTitle:@"发送验证码" forState:UIControlStateNormal];
    [self.sendCodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.sendCodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
    [self.sendCodeBtn addTarget:self action:@selector(onSendCode:) forControlEvents:UIControlEventTouchDown];
    self.sendCodeBtn.enabled = NO;
    
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge, topPos + paddingTF2Line + fieldHeight + paddingLine2TF + fieldHeight + paddingTF2Line + paddingLine2TF + 20, bgRect.size.width - paddingEdge - paddingEdge, 36)];
    [self.loginBtn setBackgroundColor:[UIColor grayColor]];
    [self.loginBtn addTarget:self action:@selector(onLoginButton:) forControlEvents:UIControlEventTouchDown];
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 5.f;
    [self.loginBtn setTitle:@"登陆" forState:UIControlStateNormal];
    self.loginBtn.enabled = NO;
    
    [self.view addSubview:self.hintLabel];
    
    [self.view addSubview:self.userNameLine];
    [self.view addSubview:self.userNameField];
    
    [self.view addSubview:self.passwordLine];
    [self.view addSubview:self.passwordField];
    [self.view addSubview:self.sendCodeBtn];
    
    [self.view addSubview:self.loginBtn];
    
    self.userNameField.text = savedName;
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetKeyboard:)]];
    
    self.privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - 28 - kTabbarSafeBottomMargin, self.view.bounds.size.width-32, 28)];
    self.privacyLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:@"登陆即代表你已同意《野火IM用户协议》和《野火IM隐私政策》" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                                                                                                                     NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
    [text setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(9, 10)];
    [text setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(20, 10)];
    self.privacyLabel.attributedText = text ;
    __weak typeof(self)ws = self;
    [self.privacyLabel yb_addAttributeTapActionWithRanges:@[NSStringFromRange(NSMakeRange(9, 8)), NSStringFromRange(NSMakeRange(18, 8))] tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
        WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
        pvc.isPrivacy = (range.location == 18);
        [ws.navigationController pushViewController:pvc animated:YES];
    }];
    
    [self.view addSubview:self.privacyLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSendCode:(id)sender {
    self.sendCodeBtn.enabled = NO;
    [self.sendCodeBtn setTitle:@"短信发送中" forState:UIControlStateNormal];
    __weak typeof(self)ws = self;
    [[AppService sharedAppService] sendCode:self.userNameField.text success:^{
       [ws sendCodeDone:YES];
    } error:^(NSString * _Nonnull message) {
        [ws sendCodeDone:NO];
    }];
}

- (void)updateCountdown:(id)sender {
    int second = (int)([NSDate date].timeIntervalSince1970 - self.sendCodeTime);
    [self.sendCodeBtn setTitle:[NSString stringWithFormat:@"%ds", 60-second] forState:UIControlStateNormal];
    if (second >= 60) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        [self.sendCodeBtn setTitle:@"发送验证码" forState:UIControlStateNormal];
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
                [self.sendCodeBtn setTitle:@"发送验证码" forState:UIControlStateNormal];
                self.sendCodeBtn.enabled = YES;
            });
        }
    });
}

- (void)resetKeyboard:(id)sender {
    [self.userNameField resignFirstResponder];
    self.userNameLine.backgroundColor = [UIColor grayColor];
    [self.passwordField resignFirstResponder];
    self.passwordLine.backgroundColor = [UIColor grayColor];
}

- (void)onLoginButton:(id)sender {
    NSString *user = self.userNameField.text;
    NSString *password = self.passwordField.text;
  
    if (!user.length || !password.length) {
        return;
    }
    
    [self resetKeyboard:nil];
    
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.label.text = @"登陆中...";
  [hud showAnimated:YES];
  
    [[AppService sharedAppService] login:user password:password success:^(NSString *userId, NSString *token, BOOL newUser) {
        [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"savedName"];
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"savedToken"];
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[WFCCNetworkService sharedInstance] connect:userId token:token];
        
        dispatch_async(dispatch_get_main_queue(), ^{
          [hud hideAnimated:YES];
            WFCBaseTabBarController *tabBarVC = [WFCBaseTabBarController new];
            tabBarVC.newUser = newUser;
            [UIApplication sharedApplication].delegate.window.rootViewController =  tabBarVC;
        });
    } error:^(int errCode, NSString *message) {
        NSLog(@"login error with code %d, message %@", errCode, message);
      dispatch_async(dispatch_get_main_queue(), ^{
        [hud hideAnimated:YES];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"登陆失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
      });
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.userNameField) {
        [self.passwordField becomeFirstResponder];
    } else if(textField == self.passwordField) {
        [self onLoginButton:nil];
    }
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.userNameField) {
        self.userNameLine.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
        self.passwordLine.backgroundColor = [UIColor grayColor];
    } else if (textField == self.passwordField) {
        self.userNameLine.backgroundColor = [UIColor grayColor];
        self.passwordLine.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    }
    return YES;
}
#pragma mark - UITextInputDelegate
- (void)textDidChange:(id<UITextInput>)textInput {
    if (textInput == self.userNameField) {
        [self updateBtn];
    } else if (textInput == self.passwordField) {
        [self updateBtn];
    }
}

- (void)updateBtn {
    if ([self isValidNumber]) {
        if (!self.countdownTimer) {
            self.sendCodeBtn.enabled = YES;
            [self.sendCodeBtn setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
        } else {
            self.sendCodeBtn.enabled = NO;
            [self.sendCodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        }
        
        if ([self isValidCode]) {
            [self.loginBtn setBackgroundColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]];
            self.loginBtn.enabled = YES;
        } else {
            [self.loginBtn setBackgroundColor:[UIColor grayColor]];
            self.loginBtn.enabled = NO;
        }
    } else {
        self.sendCodeBtn.enabled = NO;
        [self.sendCodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        
        [self.loginBtn setBackgroundColor:[UIColor grayColor]];
        self.loginBtn.enabled = NO;
    }
}

- (BOOL)isValidNumber {
    NSString * MOBILE = @"^((1[34578]))\\d{9}$";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if (self.userNameField.text.length == 11 && ([regextestmobile evaluateWithObject:self.userNameField.text] == YES)) {
        return YES;
    } else {
        return NO;
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
