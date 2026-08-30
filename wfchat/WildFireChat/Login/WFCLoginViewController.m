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
#import <CoreImage/CoreImage.h>
#import <SDWebImage/SDWebImage.h>
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
@property (strong, nonatomic) UIView *userNameContainer;
@property (strong, nonatomic) UIView *passwordContainer;

@property (strong, nonatomic) UIButton *sendCodeBtn;
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval sendCodeTime;
@property (nonatomic, strong) UILabel *privacyLabel;

@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *registerButton;
//底部「扫码登录 ⇄ 密码/验证码登录」切换（参考 PC 端 LoginPage）
@property (strong, nonatomic) UIButton *qrSwitchButton;
//pad 端卡片式登录：所有内容放在这张白色圆角卡片上（参考 PC 端 LoginPage 的卡片容器）
@property (strong, nonatomic) UIView *cardView;

//登录方式：0 扫码登录，1 密码登录，2 验证码登录（参考 PC 端 loginType）
@property (nonatomic, assign) NSInteger loginType;

//扫码登录
@property (strong, nonatomic) UIView *qrContainer;
@property (strong, nonatomic) UIImageView *qrImageView;
@property (strong, nonatomic) UILabel *qrStatusLabel;
@property (strong, nonatomic) UIActivityIndicatorView *qrLoadingView;
@property (strong, nonatomic) NSString *pcSessionToken;
@property (nonatomic, strong) NSTimer *qrPollTimer;
@property (nonatomic, strong) NSTimer *qrRefreshTimer;
//0 等待扫码；1 已被扫码、等手机端确认
@property (nonatomic, assign) NSInteger qrStatus;

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
    BOOL isPad = [WFCUPadUtility isPad];

    //pad 端卡片式登录（参考 PC 端 LoginPage 的卡片容器）：所有内容放在白色圆角卡片上；
    //iPhone 保持原有的整页表单布局。
    UIView *contentHost = self.view;
    CGFloat contentWidth = 0;
    CGFloat cardHeight = 0;
    if (isPad) {
        CGFloat cardWidth = 420;
        cardHeight = 580;
        self.cardView = [[UIView alloc] initWithFrame:CGRectMake((bgRect.size.width - cardWidth) / 2, (bgRect.size.height - cardHeight) / 2 - 20, cardWidth, cardHeight)];
        self.cardView.backgroundColor = [UIColor whiteColor];
        self.cardView.layer.cornerRadius = 16;
        self.cardView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.cardView.layer.shadowOpacity = 0.12;
        self.cardView.layer.shadowOffset = CGSizeMake(0, 4);
        self.cardView.layer.shadowRadius = 14;
        //四周弹性边距：旋转 / 分屏 / 台前调度改窗口大小时，卡片始终保持在窗口中央
        self.cardView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:self.cardView];
        contentHost = self.cardView;
        contentWidth = cardWidth - 56;
    } else {
        contentWidth = bgRect.size.width - 2 * [self formPaddingEdge];
    }
    CGFloat paddingEdge = isPad ? 28 : [self formPaddingEdge];
    CGFloat inputHeight = 40;
    CGFloat hintHeight = 26;
    CGFloat topPos = isPad ? 40 : ([WFCUUtilities wf_navigationFullHeight] + 45);
    //内容区顶部起始位置。topPos 后面会被表单逐段累加，二维码区要用这个原始值，
    //否则二维码区域会从表单下方开始（二维码掉到卡片底部、把底部按钮盖住）。
    CGFloat contentTop = topPos;
    
    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(paddingEdge, topPos, contentWidth, hintHeight)];
    [self.hintLabel setText:LocalizedString(@"PhoneLogin")];
    self.hintLabel.textAlignment = NSTextAlignmentLeft;
    self.hintLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:hintHeight];
    
    topPos += hintHeight + 50;
    
    self.userNameContainer = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos, contentWidth, inputHeight)];
    
    UILabel *userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, inputHeight - 1)];
    userNameLabel.text = LocalizedString(@"PhoneNumber");
    userNameLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:17];
    
    self.userNameLine = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, self.userNameContainer.frame.size.width, 1.f)];
    self.userNameLine.backgroundColor = [UIColor colorWithHexString:@"0xd4d4d4"];
    
    
    self.userNameField = [[UITextField alloc] initWithFrame:CGRectMake(87, 0, self.userNameContainer.frame.size.width - 87, inputHeight - 1)];
    self.userNameField.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:16];
    self.userNameField.placeholder = LocalizedString(@"PhoneNumberPlaceholder");
    self.userNameField.returnKeyType = UIReturnKeyNext;
    self.userNameField.keyboardType = UIKeyboardTypePhonePad;
    self.userNameField.delegate = self;
    self.userNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.userNameField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    topPos += inputHeight + 1;

    self.passwordContainer  = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, topPos, contentWidth, inputHeight)];
    self.passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 52, inputHeight - 1)];
    self.passwordLabel.text = LocalizedString(@"VerificationCode");
    self.passwordLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:17];
    
    
    self.passwordLine = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, self.passwordContainer.frame.size.width, 1.f)];
    self.passwordLine.backgroundColor = [UIColor colorWithHexString:@"0xd4d4d4"];
    
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(87, 0, self.passwordContainer.frame.size.width - 87 - 72, inputHeight - 1)];
    self.passwordField.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:16];
    self.passwordField.placeholder = LocalizedString(@"VerificationCodePlaceholder");
    self.passwordField.returnKeyType = UIReturnKeyDone;
    self.passwordField.keyboardType = UIKeyboardTypeNumberPad;
    self.passwordField.delegate = self;
    self.passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.passwordField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.sendCodeBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.passwordContainer.frame.size.width - 72, (inputHeight - 1 - 23) / 2.0, 72, 23)];
    [self.sendCodeBtn setTitle:LocalizedString(@"GetVerificationCode") forState:UIControlStateNormal];
    self.sendCodeBtn.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:12];
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
    self.switchButton.titleLabel.font = [UIFont scaledSystemFontOfSize:12];
    [self.switchButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [self.switchButton addTarget:self action:@selector(onSwitchLoginType:) forControlEvents:UIControlEventTouchDown];
    
    self.registerButton = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge + contentWidth - 100, topPos, 100, 40)];
    [self.registerButton setTitle:LocalizedString(@"Register") forState:UIControlStateNormal];
    self.registerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.registerButton.titleLabel.font = [UIFont scaledSystemFontOfSize:12];
    [self.registerButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [self.registerButton addTarget:self action:@selector(onRegister:) forControlEvents:UIControlEventTouchDown];
    
    topPos += 40;
    topPos += 31;
    
    self.loginBtn = [[UIButton alloc] initWithFrame:CGRectMake(paddingEdge, topPos, contentWidth, 43)];
    [self.loginBtn addTarget:self action:@selector(onLoginButton:) forControlEvents:UIControlEventTouchDown];
    self.loginBtn.layer.masksToBounds = YES;
    self.loginBtn.layer.cornerRadius = 4.f;
    [self.loginBtn setTitle:LocalizedString(@"Login") forState:UIControlStateNormal];
    self.loginBtn.backgroundColor = [UIColor colorWithHexString:@"0xe1e1e1"];
    [self.loginBtn setTitleColor:[UIColor colorWithHexString:@"0xb1b1b1"] forState:UIControlStateNormal];
    self.loginBtn.titleLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleMedium size:16];
    self.loginBtn.enabled = NO;
    
    [contentHost addSubview:self.hintLabel];
    
    [self.userNameContainer addSubview:userNameLabel];
    [self.userNameContainer addSubview:self.userNameField];
    [self.userNameContainer addSubview:self.userNameLine];
    [contentHost addSubview:self.userNameContainer];
    
    [contentHost addSubview:self.passwordContainer];
    [self.passwordContainer addSubview:self.passwordLabel];
    [self.passwordContainer addSubview:self.passwordField];
    [self.passwordContainer addSubview:self.passwordLine];
    [self.passwordContainer addSubview:self.sendCodeBtn];
    
    [contentHost addSubview:self.switchButton];
    [contentHost addSubview:self.registerButton];
    [contentHost addSubview:self.loginBtn];

    //底部「扫码登录 ⇄ 密码/验证码登录」切换，参考 PC 端 LoginPage
    self.qrSwitchButton = [[UIButton alloc] init];
    [self.qrSwitchButton setTitle:LocalizedString(@"UsePasswordOrCodeLogin") forState:UIControlStateNormal];
    self.qrSwitchButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.qrSwitchButton.titleLabel.font = [UIFont scaledSystemFontOfSize:12];
    [self.qrSwitchButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [self.qrSwitchButton addTarget:self action:@selector(onSwitchQRLogin:) forControlEvents:UIControlEventTouchDown];
    //扫码登录仅 pad 提供（按用户要求参考 PC 端），iPhone 上不显示这个入口，登录界面与适配前一致
    self.qrSwitchButton.hidden = !isPad;
    if (isPad) {
        self.qrSwitchButton.frame = CGRectMake(paddingEdge, cardHeight - 96, contentWidth, 30);
    } else {
        self.qrSwitchButton.frame = CGRectMake(paddingEdge, bgRect.size.height - 30 - [WFCUUtilities wf_safeDistanceBottom] - 40, contentWidth, 30);
    }
    [contentHost addSubview:self.qrSwitchButton];

    //扫码登录区域（二维码 + 状态文字），与表单互斥显示
    //从 contentTop 起排：二维码显示在卡片顶部
    CGFloat qrAreaHeight = isPad ? (cardHeight - contentTop - 120) : 420;
    self.qrContainer = [[UIView alloc] initWithFrame:CGRectMake(paddingEdge, contentTop, contentWidth, qrAreaHeight)];
    self.qrContainer.hidden = YES;

    self.qrImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.qrContainer.frame.size.width - 250) / 2.0, 20, 250, 250)];
    self.qrImageView.backgroundColor = [UIColor whiteColor];
    self.qrImageView.layer.cornerRadius = 8;
    self.qrImageView.layer.masksToBounds = YES;
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrImageView.userInteractionEnabled = YES;
    [self.qrImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onQRTapped:)]];
    [self.qrContainer addSubview:self.qrImageView];

    self.qrLoadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.qrLoadingView.center = self.qrImageView.center;
    self.qrLoadingView.hidden = YES;
    [self.qrContainer addSubview:self.qrLoadingView];

    self.qrStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 290, self.qrContainer.frame.size.width - 32, 60)];
    self.qrStatusLabel.textAlignment = NSTextAlignmentCenter;
    self.qrStatusLabel.numberOfLines = 0;
    self.qrStatusLabel.font = [UIFont scaledSystemFontOfSize:14];
    self.qrStatusLabel.textColor = [UIColor grayColor];
    [self.qrContainer addSubview:self.qrStatusLabel];

    [contentHost addSubview:self.qrContainer];
    
    self.userNameField.text = savedName;
    
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetKeyboard:)]];
    
    self.privacyLabel = [[UILabel alloc] init];
    if (isPad) {
        self.privacyLabel.frame = CGRectMake(paddingEdge, cardHeight - 60, contentWidth, 40);
    } else {
        self.privacyLabel.frame = CGRectMake(16, self.view.bounds.size.height - 40 - [WFCUUtilities wf_safeDistanceBottom], self.view.bounds.size.width - 32, 40);
    }
    self.privacyLabel.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:LocalizedString(@"LoginAgreement") attributes:@{NSFontAttributeName : [UIFont scaledSystemFontOfSize:10],
                                                                                                                     NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
    [text setAttributes:@{NSFontAttributeName : [UIFont scaledSystemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(9, 10)];
    [text setAttributes:@{NSFontAttributeName : [UIFont scaledSystemFontOfSize:10],
                          NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(20, 10)];
    self.privacyLabel.attributedText = text ;
    __weak typeof(self)ws = self;
    [self.privacyLabel yb_addAttributeTapActionWithRanges:@[NSStringFromRange(NSMakeRange(9, 10)), NSStringFromRange(NSMakeRange(20, 10))] tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
        WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
        pvc.isPrivacy = (range.location == 19);
        [ws.navigationController pushViewController:pvc animated:YES];
    }];
    
    [contentHost addSubview:self.privacyLabel];
    //默认登录方式：pad 参考 PC 端默认扫码登录；iPhone 尊重 AppDelegate 预设（Prefer_Password_Login）
    [self setLoginType:isPad ? 0 : (self.isPwdLogin ? 1 : 2)];
}

/// 表单左右留白。iPad 屏幕很宽，登录表单限制到 420pt 并居中，不然输入框会横跨整屏。
- (CGFloat)formPaddingEdge {
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat contentWidth = MIN(viewWidth, 420);
    return 16 + (viewWidth - contentWidth) / 2;
}

- (void)setIsPwdLogin:(BOOL)isPwdLogin {
    [self setLoginType:isPwdLogin ? 1 : 2];
}

//登录方式切换：0 扫码登录，1 密码登录，2 验证码登录（参考 PC 端 LoginPage 的 loginType）
- (void)setLoginType:(NSInteger)loginType {
    //视图未加载时只记录、不布局：AppDelegate 会在 viewDidLoad 之前设置 isPwdLogin，
    //此刻子视图还不存在，一旦往下走访问 self.view 就会提前触发 viewDidLoad，
    //外层调用随后再把表单显示回来，造成启动时「二维码和表单同时显示」。
    if (!self.isViewLoaded) {
        _loginType = loginType;
        _isPwdLogin = (loginType == 1);
        return;
    }
    //扫码登录仅 pad 提供：iPhone 上即使外部试图切到扫码也回到验证码登录
    if (loginType == 0 && ![WFCUPadUtility isPad]) {
        loginType = 2;
    }
    _loginType = loginType;
    _isPwdLogin = (loginType == 1);

    if (loginType == 0) {
        //扫码登录：显示二维码区，隐藏表单
        [self hideFormLogin];
        [self.qrSwitchButton setTitle:LocalizedString(@"UsePasswordOrCodeLogin") forState:UIControlStateNormal];
        [self showQRLogin];
    } else {
        //密码/验证码登录：显示表单，停掉扫码轮询
        [self stopQRPolling];
        [self.qrContainer setHidden:YES];
        [self.qrSwitchButton setTitle:LocalizedString(@"ScanCodeLogin") forState:UIControlStateNormal];
        [self configureFormForLoginType:loginType];
        [self showFormLogin];
    }

    // 切换登录模式后，重置验证标志并更新按钮状态
    self.hasSlideVerifiedForCode = NO;
    [self updateBtn];
}

- (void)showFormLogin {
    self.hintLabel.hidden = NO;
    self.userNameContainer.hidden = NO;
    self.passwordContainer.hidden = NO;
    self.switchButton.hidden = NO;
    self.registerButton.hidden = NO;
    self.loginBtn.hidden = NO;
}

- (void)hideFormLogin {
    self.hintLabel.hidden = YES;
    self.userNameContainer.hidden = YES;
    self.passwordContainer.hidden = YES;
    self.switchButton.hidden = YES;
    self.registerButton.hidden = YES;
    self.loginBtn.hidden = YES;
}

- (void)configureFormForLoginType:(NSInteger)loginType {
    CGRect pwdFeildFrame = self.passwordField.frame;
    //按输入框容器的实际宽度算（iPhone 上 = 屏宽减两侧留白，与原来一致；pad 卡片上 = 卡片内容宽）
    CGFloat pwdFeildWidth = self.passwordContainer.frame.size.width - 87;
    BOOL isPwdLogin = (loginType == 1);
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
    //离开登录页（登录成功切根 / 被 push 走）时停掉扫码轮询与刷新
    [self stopQRPolling];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onSwitchLoginType:(id)sender {
    //表单内：密码 ⇄ 验证码
    [self setLoginType:self.loginType == 1 ? 2 : 1];
}

- (void)onSwitchQRLogin:(id)sender {
    //扫码登录仅 pad 提供，iPhone 上按钮本身也不显示，双保险
    if (![WFCUPadUtility isPad]) {
        return;
    }
    //底部：扫码 ⇄ 密码/验证码
    [self setLoginType:self.loginType == 0 ? 2 : 0];
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

    if (!ENABLE_SLIDE_VERIFY) {
        self.sendCodeBtn.enabled = NO;
        [self.sendCodeBtn setTitle:LocalizedString(@"SMSSending") forState:UIControlStateNormal];
        __weak typeof(self)ws = self;
        [[AppService sharedAppService] sendLoginCode:self.userNameField.text slideVerifyToken:nil success:^{
           [ws sendCodeDone:YES];
           // 标记已通过滑动验证
           ws.hasSlideVerifiedForCode = YES;
        } error:^(NSString * _Nonnull message) {
            [ws sendCodeDone:NO];
            // 发送失败，重置验证标志
            ws.hasSlideVerifiedForCode = NO;
        }];
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

    if (!ENABLE_SLIDE_VERIFY) {
        [self performLogin];
        return;
    }

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
        [hud hideAnimated:YES];
        [self loginSuccessWithUserId:userId token:token savedName:user resetCode:resetCode];
    };


    if (self.isPwdLogin) {
        [[AppService sharedAppService] loginWithMobile:user password:password success:^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
            successBlock(userId, token, newUser, resetCode);
        } error:errorBlock];
    } else {
        [[AppService sharedAppService] loginWithMobile:user verifyCode:password success:successBlock error:errorBlock];
    }
}

//登录成功：保存凭证、连接 IM、切换到主界面（密码/验证码/扫码三种方式共用）
- (void)loginSuccessWithUserId:(NSString *)userId token:(NSString *)token savedName:(NSString *)savedName resetCode:(NSString *)resetCode {
    [[NSUserDefaults standardUserDefaults] setObject:(savedName.length ? savedName : userId) forKey:@"savedName"];
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

    UIViewController *rootVC = [WFCBaseTabBarController rootViewController];
    [UIApplication sharedApplication].delegate.window.rootViewController = rootVC;
    WFCBaseTabBarController *tabBarVC = [WFCBaseTabBarController tabBarControllerInRoot:rootVC];
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
}

#pragma mark - 扫码登录（参考 PC 端 LoginPage 的扫码流程）

- (void)showQRLogin {
    self.qrContainer.hidden = NO;
    self.qrStatus = 0;
    self.qrStatusLabel.text = LocalizedString(@"QRLoginWaiting");
    [self refreshQRCode];
}

- (void)onQRTapped:(id)sender {
    //生成失败时点击重试；轮询中点击直接刷新二维码
    [self refreshQRCode];
}

- (void)refreshQRCode {
    [self stopQRPolling];
    self.pcSessionToken = nil;
    self.qrImageView.image = nil;
    self.qrImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.qrLoadingView.hidden = NO;
    [self.qrLoadingView startAnimating];
    self.qrStatus = 0;
    self.qrStatusLabel.text = LocalizedString(@"QRLoginWaiting");

    __weak typeof(self) ws = self;
    [[AppService sharedAppService] createPCLoginSession:nil success:^(NSString *token) {
        if (!ws || ws.loginType != 0) {
            return;
        }
        ws.pcSessionToken = token;
        ws.qrLoadingView.hidden = YES;
        [ws.qrLoadingView stopAnimating];
        //二维码内容与手机端扫码识别的格式一致：wildfirechat://pcsession/<token>
        ws.qrImageView.image = [WFCLoginViewController qrCodeImageWithString:[NSString stringWithFormat:@"wildfirechat://pcsession/%@", token] size:240];
        [ws startQRPolling];
    } error:^(int errCode, NSString *message) {
        if (!ws || ws.loginType != 0) {
            return;
        }
        ws.qrLoadingView.hidden = YES;
        [ws.qrLoadingView stopAnimating];
        ws.qrStatusLabel.text = LocalizedString(@"QRCodeGenerateFailed");
    }];
}

- (void)startQRPolling {
    if (self.qrPollTimer) {
        return;
    }
    self.qrPollTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(pollQRStatus) userInfo:nil repeats:YES];
    [self.qrPollTimer fire];
    //60秒后自动刷新二维码（与 PC 端 refreshQrCode 一致）
    self.qrRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(refreshQRCode) userInfo:nil repeats:YES];
}

- (void)stopQRPolling {
    if (self.qrPollTimer) {
        [self.qrPollTimer invalidate];
        self.qrPollTimer = nil;
    }
    if (self.qrRefreshTimer) {
        [self.qrRefreshTimer invalidate];
        self.qrRefreshTimer = nil;
    }
}

- (void)pollQRStatus {
    if (!self.pcSessionToken.length || self.loginType != 0) {
        return;
    }
    NSString *token = self.pcSessionToken;
    __weak typeof(self) ws = self;
    [[AppService sharedAppService] loginWithPCLoginSession:token success:^(NSString *userId, NSString *imToken) {
        if (!ws || ws.loginType != 0 || ![token isEqualToString:ws.pcSessionToken]) {
            //二维码已刷新，丢弃过期结果
            return;
        }
        [ws stopQRPolling];
        [ws loginSuccessWithUserId:userId token:imToken savedName:nil resetCode:nil];
    } scanned:^(NSString *userName, NSString *portrait) {
        if (!ws || ws.loginType != 0 || ![token isEqualToString:ws.pcSessionToken]) {
            return;
        }
        if (ws.qrStatus != 1) {
            ws.qrStatus = 1;
            //扫码后、手机端确认前：二维码区域换成扫码用户的头像（参考 PC 端 LoginPage），
            //下方提示「XXX 已扫码，请在手机上确认登录」
            ws.qrImageView.contentMode = UIViewContentModeScaleAspectFill;
            if (portrait.length) {
                [ws.qrImageView sd_setImageWithURL:[NSURL URLWithString:portrait] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
            } else {
                ws.qrImageView.image = [WFCUImage imageNamed:@"PersonalChat"];
            }
            ws.qrStatusLabel.text = [NSString stringWithFormat:LocalizedString(@"QRLoginScanned"), userName ?: @""];
        }
    } canceled:^{
        if (!ws || ws.loginType != 0 || ![token isEqualToString:ws.pcSessionToken]) {
            return;
        }
        //手机端取消/拒绝登录，重新生成二维码
        [ws refreshQRCode];
    } error:^(int errCode, NSString *message) {
        //网络波动等暂时性错误：继续轮询即可
    }];
}

+ (UIImage *)qrCodeImageWithString:(NSString *)string size:(CGFloat)size {
    if (!string.length) {
        return nil;
    }
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setDefaults];
    [filter setValue:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:@"inputMessage"];
    [filter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *output = filter.outputImage;
    if (!output) {
        return nil;
    }
    CGFloat scale = size / output.extent.size.width;
    CIImage *scaled = [output imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:scaled fromRect:scaled.extent];
    if (!cgImage) {
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
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
    CGFloat verifyWidth = MIN(self.view.bounds.size.width - 40, 400);
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - verifyWidth) / 2, (self.view.bounds.size.height - 280) / 2, verifyWidth, 280)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 12;
    containerView.layer.masksToBounds = YES;
    containerView.tag = 10000; // 给容器设置tag，防止点击容器时触发取消
    [backgroundView addSubview:containerView];

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, containerView.bounds.size.width, 30)];
    titleLabel.text = LocalizedString(@"SecurityVerification");
    titleLabel.font = [UIFont scaledBoldSystemFontOfSize:18];
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
    hud.label.text = LocalizedString(@"Cancelled");
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
    hud.label.text = LocalizedString(@"LoadVerificationCodeFailed");
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.5];

    // 清理待执行的操作
    self.pendingLoginAction = nil;
}

@end
