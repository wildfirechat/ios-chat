//
//  WFCResetPasswordViewController.m
//  WildFireChat
//
//  Created by Rain on 2022/8/4.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCResetPasswordViewController.h"
#import "AppService.h"
#import "MBProgressHUD.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCSlideVerifyView.h"

@interface WFCResetPasswordViewController () <UITextFieldDelegate, WFCSlideVerifyViewDelegate>
@property(nonatomic, strong)UILabel *codeLabel;
@property(nonatomic, strong)UITextField *codePasswordfield;
@property(nonatomic, strong)UIView *codeLine;

@property (strong, nonatomic) UIButton *sendCodeBtn;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval sendCodeTime;

@property(nonatomic, strong)UILabel *label;
@property(nonatomic, strong)UITextField *passwordfield;
@property(nonatomic, strong)UIView *line;

@property(nonatomic, strong)UILabel *repeatLabel;
@property(nonatomic, strong)UITextField *repeatPasswordField;
@property(nonatomic, strong)UIView *repeatLine;

@property (strong, nonatomic) WFCSlideVerifyView *slideVerifyView;
@property (strong, nonatomic) NSString *slideVerifyToken;
@property (nonatomic, copy) void (^pendingAction)(void);
@end

@implementation WFCResetPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalizedString(@"SetNewPassword");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    CGFloat inputHeight = 40;
    CGFloat topPos = [WFCUUtilities wf_navigationFullHeight] + 16;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat labelWidth = 72;
    
    if (!self.resetCode.length) {
        self.codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, topPos, labelWidth, inputHeight)];
        self.codeLabel.font = [UIFont systemFontOfSize:16];
        self.codeLabel.text = LocalizedString(@"VerificationCode");
        self.codePasswordfield = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16-72, inputHeight)];
        self.codePasswordfield.placeholder = LocalizedString(@"VerificationCodePlaceholder");
        self.codePasswordfield.delegate = self;
        self.codePasswordfield.keyboardType = UIKeyboardTypeASCIICapable;
        
        self.sendCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 16 - 72, topPos + (inputHeight - 23)/2, 72, 23)];
        [self.sendCodeBtn setTitle:LocalizedString(@"GetVerificationCode") forState:UIControlStateNormal];
        self.sendCodeBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        self.sendCodeBtn.layer.borderWidth = 1;
        self.sendCodeBtn.layer.cornerRadius = 4;
        self.sendCodeBtn.layer.borderColor = [UIColor colorWithHexString:@"0x191919"].CGColor;
        [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateNormal];
        [self.sendCodeBtn setTitleColor:[UIColor colorWithHexString:@"0x171717"] forState:UIControlStateSelected];
        [self.sendCodeBtn addTarget:self action:@selector(onSendCode:) forControlEvents:UIControlEventTouchDown];
        
        topPos += inputHeight;
        self.codeLine = [[UIView alloc] initWithFrame:CGRectMake(16, topPos, screenWidth - 16 - 16, 1)];
        self.codeLine.backgroundColor = [UIColor grayColor];
        [self.view addSubview:self.codeLabel];
        [self.view addSubview:self.codePasswordfield];
        [self.view addSubview:self.codeLine];
        [self.view addSubview:self.sendCodeBtn];
        topPos += 1;
        
        topPos += 16;
    }
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(16, topPos, labelWidth, inputHeight)];
    self.label.font = [UIFont systemFontOfSize:16];
    self.label.text = LocalizedString(@"NewPassword");
    self.passwordfield = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16, inputHeight)];
    self.passwordfield.placeholder = LocalizedString(@"NewPasswordPlaceholder");
    self.passwordfield.delegate = self;
    self.passwordfield.keyboardType = UIKeyboardTypeASCIICapable;
    self.passwordfield.secureTextEntry = YES;
    topPos += inputHeight;
    self.line = [[UIView alloc] initWithFrame:CGRectMake(16, topPos, screenWidth - 16 - 16, 1)];
    self.line.backgroundColor = [UIColor grayColor];
    topPos += 1;
    
    
    
    topPos += 16;
    self.repeatLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, topPos, labelWidth, inputHeight)];
    self.repeatLabel.font = [UIFont systemFontOfSize:16];
    self.repeatLabel.text = LocalizedString(@"ConfirmPassword");

    self.repeatPasswordField = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16, inputHeight)];
    self.repeatPasswordField.placeholder = LocalizedString(@"ConfirmPasswordPlaceholder");
    self.repeatPasswordField.delegate = self;
    self.repeatPasswordField.keyboardType = UIKeyboardTypeASCIICapable;
    self.repeatPasswordField.secureTextEntry = YES;
    
    topPos += inputHeight;
    self.repeatLine = [[UIView alloc] initWithFrame:CGRectMake(16, topPos, screenWidth - 16 - 16, 1)];
    self.repeatLine.backgroundColor = [UIColor grayColor];
    
    
    [self.view addSubview:self.label];
    [self.view addSubview:self.passwordfield];
    [self.view addSubview:self.line];
    [self.view addSubview:self.repeatLabel];
    [self.view addSubview:self.repeatPasswordField];
    [self.view addSubview:self.repeatLine];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"Done") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)onSendCode:(id)sender {
    // 显示滑动验证
    [self showSlideVerifyWithAction:^{
        self.sendCodeBtn.enabled = NO;
        [self.sendCodeBtn setTitle:LocalizedString(@"SMSSending") forState:UIControlStateNormal];
        __weak typeof(self)ws = self;
        [[AppService sharedAppService] sendResetCode:nil slideVerifyToken:self.slideVerifyToken success:^{
           [ws sendCodeDone:YES];
        } error:^(NSString * _Nonnull message) {
            [ws sendCodeDone:NO];
        }];
    }];
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

- (void)onRightBtn:(id)sender {
    NSString *password = self.passwordfield.text;
    NSString *code = self.resetCode.length ? self.resetCode : self.codePasswordfield.text;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LocalizedString(@"Saving");
    [hud showAnimated:YES];
    __weak typeof(self)ws = self;
    [[AppService sharedAppService] resetPassword:nil code:code newPassword:password success:^{
        NSLog(@"change success");
        [hud hideAnimated:YES];
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int errCode, NSString * _Nonnull message) {
        NSLog(@"change failure");
        [hud hideAnimated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"SaveFailed");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws.navigationController popViewControllerAnimated:YES];
        });
        
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *password = self.passwordfield.text;
    NSString *repeat = self.repeatPasswordField.text;
    NSString *code = self.resetCode.length ? self.resetCode : self.codePasswordfield.text;
    
    if (password.length && [password isEqualToString:repeat] && code.length >= 4) {
        [self onRightBtn:nil];
    }
    return NO;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == self.passwordfield) {
        self.line.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
        self.repeatLine.backgroundColor = [UIColor grayColor];
    } else if (textField == self.repeatPasswordField) {
        self.line.backgroundColor = [UIColor grayColor];
        self.repeatLine.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *txt = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSString *anotherTxt = self.passwordfield == textField ? self.repeatPasswordField.text : self.passwordfield.text;
    NSString *code = self.resetCode.length ? self.resetCode : self.codePasswordfield.text;

    if(anotherTxt.length && [anotherTxt isEqualToString:txt] && code.length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    return YES;
}

#pragma mark - Slide Verify
- (void)showSlideVerifyWithAction:(void(^)(void))action {
    self.pendingAction = action;

    // 创建半透明背景
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    backgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    backgroundView.tag = 9999;
    [self.view addSubview:backgroundView];

    // 创建滑动验证视图容器
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(20, (self.view.bounds.size.height - 280) / 2, self.view.bounds.size.width - 40, 280)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 12;
    containerView.layer.masksToBounds = YES;
    [backgroundView addSubview:containerView];

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, containerView.bounds.size.width, 30)];
    titleLabel.text = LocalizedString(@"SecurityVerification");
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [containerView addSubview:titleLabel];

    // 滑动验证视图
    self.slideVerifyView = [[WFCSlideVerifyView alloc] initWithFrame:CGRectMake(10, 55, containerView.bounds.size.width - 20, 215)];
    self.slideVerifyView.delegate = self;
    [containerView addSubview:self.slideVerifyView];
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

        if (self.pendingAction) {
            self.pendingAction();
            self.pendingAction = nil;
        }
    });
}

- (void)slideVerifyViewDidVerifyFailed {
    self.slideVerifyToken = nil;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = LocalizedString(@"VerificationFailed");
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.5];
}

@end
