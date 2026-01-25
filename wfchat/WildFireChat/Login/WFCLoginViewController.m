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
#import "WFCResetPasswordViewController.h"
#import "MBProgressHUD.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import "WFCPrivacyViewController.h"
#import "AppService.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "TYHWaterMark.h"
#import "WFCConfig.h"
#import "SSKeychain.h"
#import "WFCSlideVerifyView.h"

@interface WFCLoginViewController () <UITextFieldDelegate, WFCSlideVerifyViewDelegate>
@property (strong, nonatomic) UILabel *hintLabel;
@property (strong, nonatomic) UITextField *userNameField;
@property (strong, nonatomic) UITextField *passwordField;
@property (strong, nonatomic) UIButton *loginBtn;

@property (strong, nonatomic) UILabel *passwordLabel;


@property (strong, nonatomic) UIView *userNameLine;
@property (strong, nonatomic) UIView *passwordLine;

@property (strong, nonatomic) UIButton *sendCodeBtn;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval sendCodeTime;
@property (nonatomic, strong) UILabel *privacyLabel;

@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *registerButton;

@property (strong, nonatomic) WFCSlideVerifyView *slideVerifyView;
@property (strong, nonatomic) NSString *slideVerifyToken;
@property (nonatomic, assign) BOOL needSlideVerify;
@property (nonatomic, assign) BOOL hasSlideVerifiedForCode; // 是否已通过滑动验证（用于验证码登录）
@property (nonatomic, copy) void (^pendingLoginAction)(void);
@end

@implementation WFCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    NSString *savedName = [[NSUserDefaults standardUserDefaults] stringForKey:@"savedName"];
   
    CGRect bgRect = self.view.bounds;
    CGFloat paddingEdge = 16;
    CGFloat inputHeight = 40;
    CGFloat hintHeight = 26;
    CGFloat topPos = [WFCUUtilities wf_navigationFullHeight] + 45;
    
    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge - paddingEdge, hintHeight)];
    [self.hintLabel setText:LocalizedString(@"PhoneLogin")];
    self.hintLabel.textAlignment = NSTextAlignmentLeft;
    self.hintLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:hintHeight];
    
    topPos += hintHeight + 50;
    
    UIView *userNameContainer = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - 2 * paddingEdge, inputHeight)];
    
    UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, inputHeight - 1)];
    userNameLabel.text = LocalizedString(@"PhoneNumber");
    userNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:17];
    
    self.userNameLine = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, userNameContainer.frame.size.width, 1.f)];
    self.userNameLine.backgroundColor = [UIColor colorWithHexString:@"0xd4d4d4"];
    
    
    self.userNameField = [[UITextField alloc] initWithFrame:CGRectMake(87, 0, userNameContainer.frame.size.width - 87, inputHeight - 1)];
    self.userNameField.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
    self.userNameField.placeholder = LocalizedString(@"PhoneNumberPlaceholder");
    self.userNameField.returnKeyType = UIReturnKeyNext;
    self.userNameField.keyboardType = UIKeyboardTypePhonePad;
    self.userNameField.delegate = self;
    self.userNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.userNameField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    topPos += inputHeight + 1;

    UIView *passwordContainer  = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge * 2, inputHeight)];
    self.passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, inputHeight - 1)];
    self.passwordLabel.text = LocalizedString(@"VerificationCode");
    self.passwordLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:17];
    
    
    self.passwordLine = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, passwordContainer.frame.size.width, 1.f)];
    self.passwordLine.backgroundColor = [UIColor colorWithHexString:@"0xd4d4d4"];
    
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(87, 0, passwordContainer.frame.size.width - 87 - 72, inputHeight - 1)];
    self.passwordField.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
    self.passwordField.placeholder = LocalizedString(@"VerificationCodePlaceholder");
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.keyboardType = UIKeyboardTypeNumberPad;
    self.passwordField.delegate = self;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.passwordField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.sendCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(passwordContainer.frame.size.width - 72, (inputHeight - 1 - 23) / 2.0, 72, 23)];
    [self.sendCodeBtn setTitle:LocalizedString(@"GetVerificationCode") forState:UIControlStateNormal];
    self.sendCodeBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
    self.sendCodeBtn.layer.borderWidth = 1;
    self.sendCodeBtn.layer.cornerRadius = 4;
    self.sendCodeBtn.layer.borderColor = [UIColor colorWithHexString:@"0x191919"].CGColor;
    [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateNormal];
    [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateSelected];
    [self.sendCodeBtn addTarget:self action:@selector(onSendCode:) forControlEvents:UIControlEventTouchDown];
    self.sendCodeBtn.enabled = NO;
    
    
    topPos += 40;
    
    topPos += 8;
    
    self.switchButton = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge, topPos, 150, 40)];
    [self.switchButton setTitle:LocalizedString(@"UsePasswordLogin") forState:UIControlStateNormal];
    self.switchButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.switchButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.switchButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(onSwitchLoginType:) forControlEvents:UIControlEventTouchDown];
    
    self.registerButton = [[UIButton alloc] initWithFrame:CGRectMake(bgRect.size.width - paddingEdge - 100, topPos, 100, 40)];
    [self.registerButton setTitle:LocalizedString(@"Register") forState:UIControlStateNormal];
    self.registerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.registerButton.titleLabel.font = [UIFont systemFontOfSize:12];
    [self.registerButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [self.registerButton addTarget:self action:@selector(onRegister:) forControlEvents:UIControlEventTouchDown];
    
    topPos += 40;
    topPos += 31;
    
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge, topPos, bgRect.size.width - paddingEdge * 2, 43)];
    [self.loginBtn addTarget:self action:@selector(onLoginButton:) forControlEvents:UIControlEventTouchDown];
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 4.f;
    [self.loginBtn setTitle:LocalizedString(@"Login") forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = [UIColor colorWithHexString:@"0xe1e1e1"];
    [self.loginBtn setTitleColor:[UIColor colorWithHexString:@"0xb1b1b1"] forState:UIControlStateNormal];
    self.loginBtn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:16];
    self.loginBtn.enabled = NO;
    
    [self.view addSubview:self.hintLabel];
    
    [userNameContainer addSubview:userNameLabel];
    [userNameContainer addSubview:self.userNameField];
    [userNameContainer addSubview:self.userNameLine];
    [self.view addSubview:userNameContainer];
    
    [self.view addSubview:passwordContainer];
    [passwordContainer addSubview:self.passwordLabel];
    [passwordContainer addSubview:self.passwordField];
    [passwordContainer addSubview:self.passwordLine];
    [passwordContainer addSubview:self.sendCodeBtn];
    
    [self.view addSubview:self.switchButton];
    [self.view addSubview:self.registerButton];
    [self.view addSubview:self.loginBtn];
    
    self.userNameField.text = savedName;
    
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetKeyboard:)]];
    
    self.privacyLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.view.bounds.size.height - 40 - [WFCUUtilities wf_safeDistanceBottom], self.view.bounds.size.width-32, 40)];
    self.privacyLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:LocalizedString(@"LoginAgreement") attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                                                                                                                     NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
    [text setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(9, 10)];
    [text setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(20, 10)];
    self.privacyLabel.attributedText = text ;
    __weak typeof(self)ws = self;
    [self.privacyLabel yb_addAttributeTapActionWithRanges:@[NSStringFromRange(NSMakeRange(9, 10)), NSStringFromRange(NSMakeRange(20, 10))] tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
        WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
        pvc.isPrivacy = (range.location == 19);
        [ws.navigationController pushViewController:pvc animated:YES];
    }];
    
    [self.view addSubview:self.privacyLabel];
    [self setIsPwdLogin:self.isPwdLogin];
}

- (void)setIsPwdLogin:(BOOL)isPwdLogin {
    _isPwdLogin = isPwdLogin;
    CGRect bgRect = self.view.bounds;
    CGRect pwdFeildFrame = self.passwordField.frame;
    CGFloat paddingEdge = 16;
    CGFloat pwdFeildWidth = bgRect.size.width - paddingEdge * 2 - 87;
    if (isPwdLogin) {
        self.hintLabel.text = LocalizedString(@"PasswordLogin");
        self.passwordLabel.text = LocalizedString(@"Password");
        self.sendCodeBtn.hidden = YES;
        self.passwordField.placeholder = LocalizedString(@"PasswordPlaceholder");
        self.passwordField.keyboardType = UIKeyboardTypeASCIICapable;
        self.passwordField.secureTextEntry = YES;
        self.passwordField.text = nil;
        if (self.passwordField.isFirstResponder) {
            [self.passwordField resignFirstResponder];
            [self.passwordField becomeFirstResponder];
        }
        [self.switchButton setTitle:LocalizedString(@"UseSMSCodeLogin") forState:UIControlStateNormal];
    } else {
        self.hintLabel.text = LocalizedString(@"SMSCodeLogin");
        self.passwordLabel.text = LocalizedString(@"VerificationCode");
        self.sendCodeBtn.hidden = NO;
        self.passwordField.placeholder = LocalizedString(@"VerificationCodePlaceholder");
        self.passwordField.keyboardType = UIKeyboardTypeNumberPad;
        self.passwordField.secureTextEntry = NO;
        self.passwordField.text = nil;
        if (self.passwordField.isFirstResponder) {
            [self.passwordField resignFirstResponder];
            [self.passwordField becomeFirstResponder];
        }
        [self.switchButton setTitle:LocalizedString(@"UsePasswordLogin") forState:UIControlStateNormal];
        pwdFeildWidth -= 72;
    }
    pwdFeildFrame.size.width = pwdFeildWidth;
    self.passwordField.frame = pwdFeildFrame;

    // 切换登录模式后，重置验证标志并更新按钮状态
    self.hasSlideVerifiedForCode = NO;
    [self updateBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.isKickedOff) {
        self.isKickedOff = NO;
        UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:LocalizedString(@"AccountLoggedInElsewhere") preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LocalizedString(@"GotIt") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];

        [actionSheet addAction:actionCancel];
        
        [self presentViewController:actionSheet animated:YES completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSwitchLoginType:(id)sender {
//    [UIView animateWithDuration:0.5 animations:^{
        self.isPwdLogin = !self.isPwdLogin;
//    }];
}

- (void)onRegister:(id)sender {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Tips") message:LocalizedString(@"SMSCodeLoginTip") preferredStyle:UIAlertControllerStyleAlert];
    
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:LocalizedString(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        ws.isPwdLogin = NO;
    }];
    
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)onSendCode:(id)sender {
    if (!self.userNameField.text.length) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"PleaseInputPhone");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        return;
    }

    // 显示滑动验证
    [self showSlideVerifyWithAction:^{
        self.sendCodeBtn.enabled = NO;
        [self.sendCodeBtn setTitle:LocalizedString(@"SMSSending") forState:UIControlStateNormal];
        __weak typeof(self)ws = self;
        [[AppService sharedAppService] sendLoginCode:self.userNameField.text slideVerifyToken:self.slideVerifyToken success:^{
           [ws sendCodeDone:YES];
           // 标记已通过滑动验证
           ws.hasSlideVerifiedForCode = YES;
        } error:^(NSString * _Nonnull message) {
            [ws sendCodeDone:NO];
            // 发送失败，重置验证标志
            ws.hasSlideVerifiedForCode = NO;
        }];
    }];
}

- (void)updateCountdown:(id)sender {
    int second = (int)([NSDate date].timeIntervalSince1970 - self.sendCodeTime);
    [self.sendCodeBtn setTitle:[NSString stringWithFormat:@"%ds", 60-second] forState:UIControlStateNormal];
    if (second >= 60) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
        [self.sendCodeBtn setTitle:LocalizedString(@"GetVerificationCode") forState:UIControlStateNormal];
        self.sendCodeBtn.enabled = YES;
    }
}
- (void)sendCodeDone:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (success) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LocalizedString(@"SendSuccess");
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
            hud.label.text = LocalizedString(@"SendFailed");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.sendCodeBtn setTitle:LocalizedString(@"GetVerificationCode") forState:UIControlStateNormal];
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
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"PleaseInputPhoneAndCode");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        return;
    }

    [self resetKeyboard:nil];

    // 验证码登录且已通过滑动验证，直接执行登录
    if (!self.isPwdLogin && self.hasSlideVerifiedForCode) {
        [self performLogin];
        return;
    }

    // 密码登录或验证码登录但未通过滑动验证，显示滑动验证
    [self showSlideVerifyWithAction:^{
        [self performLogin];
    }];
}

- (void)performLogin {
    NSString *user = self.userNameField.text;
    NSString *password = self.passwordField.text;

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LocalizedString(@"Logining");
    [hud showAnimated:YES];

    void(^errorBlock)(int errCode, NSString *message) = ^(int errCode, NSString *message) {
        NSLog(@"login error with code %d, message %@", errCode, message);
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];

            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = LocalizedString(@"LoginFailed");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];

            // 登录失败，重置验证标志
            if (!self.isPwdLogin) {
                self.hasSlideVerifiedForCode = NO;
            }
        });
    };

    void(^successBlock)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) = ^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
        [[NSUserDefaults standardUserDefaults] setObject:user forKey:@"savedName"];
        [SSKeychain setPassword:token forWFService:@"savedToken"];
        [SSKeychain setPassword:userId forWFService:@"savedUserId"];
        [[NSUserDefaults standardUserDefaults] synchronize];


        //需要注意token跟clientId是强依赖的，一定要调用getClientId获取到clientId，然后用这个clientId获取token，这样connect才能成功，如果随便使用一个clientId获取到的token将无法链接成功。
        [[WFCCNetworkService sharedInstance] connect:userId token:token];
        if(ENABLE_WATER_MARKER) {
            [[UIApplication sharedApplication].delegate.window addSubview:[TYHWaterMarkView new]];
            [TYHWaterMarkView setCharacter:userId];
            [TYHWaterMarkView autoUpdateDate:YES];
        }

        [hud hideAnimated:YES];
        WFCBaseTabBarController *tabBarVC = [WFCBaseTabBarController new];
        [UIApplication sharedApplication].delegate.window.rootViewController =  tabBarVC;
        if (resetCode) {
            if ([tabBarVC.childViewControllers.firstObject isKindOfClass:[UINavigationController class]]) {
                WFCResetPasswordViewController *vc = [[WFCResetPasswordViewController alloc] init];
                vc.resetCode = resetCode;
                vc.hidesBottomBarWhenPushed = YES;
                UINavigationController *nav = (UINavigationController *)tabBarVC.childViewControllers.firstObject;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [nav pushViewController:vc animated:YES];
                });
            }
        }
    };


    if (self.isPwdLogin) {
        [[AppService sharedAppService] loginWithMobile:user password:password success:^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
            successBlock(userId, token, newUser, resetCode);
        } error:errorBlock];
    } else {
        [[AppService sharedAppService] loginWithMobile:user verifyCode:password success:successBlock error:errorBlock];
    }
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
    // 验证码发送按钮：只依赖手机号是否有效
    if ([self isValidNumber]) {
        // 手机号有效，启用"获取验证码"按钮（如果没有倒计时）
        if (!self.countdownTimer) {
            self.sendCodeBtn.enabled = YES;
            [self.sendCodeBtn setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
            self.sendCodeBtn.layer.borderColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9].CGColor;
        } else {
            // 倒计时中，禁用按钮
            self.sendCodeBtn.enabled = NO;
            self.sendCodeBtn.layer.borderColor = [UIColor colorWithHexString:@"0x191919"].CGColor;
            [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateNormal];
            [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateSelected];
        }

        // 登录按钮：依赖验证码是否有效（验证码登录模式）或密码是否有效（密码登录模式）
        if ([self isValidCode]) {
            [self.loginBtn setBackgroundColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9]];
            self.loginBtn.enabled = YES;
        } else {
            [self.loginBtn setBackgroundColor:[UIColor grayColor]];
            self.loginBtn.enabled = NO;
        }
    } else {
        // 手机号无效，禁用所有按钮
        self.sendCodeBtn.enabled = NO;
        [self.sendCodeBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];

        [self.loginBtn setBackgroundColor:[UIColor grayColor]];
        self.loginBtn.enabled = NO;
    }
}

- (BOOL)isValidNumber {
    NSString * MOBILE = @"^((1[23456789]))\\d{9}$";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    if (self.userNameField.text.length == 11 && ([regextestmobile evaluateWithObject:self.userNameField.text] == YES)) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isValidCode {
    // 验证码登录模式：验证码至少1位
    // 密码登录模式：密码至少1位
    if (self.passwordField.text.length >= 1) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Slide Verify
- (void)showSlideVerifyWithAction:(void(^)(void))action {
    self.pendingLoginAction = action;

    // 创建半透明背景
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    backgroundView.tag = 9999;
    [self.view addSubview:backgroundView];

    // 添加点击背景取消的手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelSlideVerify)];
    [backgroundView addGestureRecognizer:tapGesture];

    // 创建滑动验证视图容器
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(20, (self.view.bounds.size.height - 280) / 2, self.view.bounds.size.width - 40, 280)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 12;
    containerView.layer.masksToBounds = YES;
    containerView.tag = 10000; // 给容器设置tag，防止点击容器时触发取消
    [backgroundView addSubview:containerView];

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, containerView.bounds.size.width, 30)];
    titleLabel.text = @"安全验证";
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [containerView addSubview:titleLabel];

    // 滑动验证视图
    self.slideVerifyView = [[WFCSlideVerifyView alloc] initWithFrame:CGRectMake(10, 55, containerView.bounds.size.width - 20, 215)];
    self.slideVerifyView.delegate = self;
    [containerView addSubview:self.slideVerifyView];
}

- (void)cancelSlideVerify {
    [self hideSlideVerify];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = @"已取消";
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.0];

    // 清理待执行的操作
    self.pendingLoginAction = nil;
}

- (void)hideSlideVerify {
    UIView *backgroundView = [self.view viewWithTag:9999];
    if (backgroundView) {
        [backgroundView removeFromSuperview];
    }
    self.slideVerifyView = nil;
    self.slideVerifyToken = nil;
}

#pragma mark - WFCSlideVerifyViewDelegate
- (void)slideVerifyViewDidVerifySuccess:(NSString *)token {
    self.slideVerifyToken = token;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideSlideVerify];

        if (self.pendingLoginAction) {
            self.pendingLoginAction();
            self.pendingLoginAction = nil;
        }
    });
}

- (void)slideVerifyViewDidVerifyFailed {
    // 验证失败（滑动位置不对），不关闭窗口，让用户重试
    // 这个方法现在不需要做任何事，因为 WFCSlideVerifyView 已经处理了提示和重置
}

- (void)slideVerifyViewDidLoadFailed {
    // 加载验证码失败，需要关闭窗口
    [self hideSlideVerify];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = @"加载验证码失败";
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.5];

    // 清理待执行的操作
    self.pendingLoginAction = nil;
}

@end
