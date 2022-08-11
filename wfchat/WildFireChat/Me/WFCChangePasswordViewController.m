//
//  WFCChangePasswordViewController.m
//  WildFireChat
//
//  Created by Rain on 2022/8/4.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCChangePasswordViewController.h"
#import "AppService.h"
#import "MBProgressHUD.h"

@interface WFCChangePasswordViewController () <UITextFieldDelegate>
@property(nonatomic, strong)UILabel *oldLabel;
@property(nonatomic, strong)UITextField *oldPasswordfield;
@property(nonatomic, strong)UIView *oldLine;

@property(nonatomic, strong)UILabel *label;
@property(nonatomic, strong)UITextField *passwordfield;
@property(nonatomic, strong)UIView *line;

@property(nonatomic, strong)UILabel *repeatLabel;
@property(nonatomic, strong)UITextField *repeatPasswordField;
@property(nonatomic, strong)UIView *repeatLine;
@end

@implementation WFCChangePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置新密码";
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat inputHeight = 40;
    CGFloat topPos = kStatusBarAndNavigationBarHeight + 16;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat labelWidth = 72;
    
    self.oldLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, topPos, labelWidth, inputHeight)];
    self.oldLabel.font = [UIFont systemFontOfSize:16];
    self.oldLabel.text = @"原密码";
    self.oldPasswordfield = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16, inputHeight)];
    self.oldPasswordfield.placeholder = @"请输入原密码";
    self.oldPasswordfield.delegate = self;
    self.oldPasswordfield.keyboardType = UIKeyboardTypeASCIICapable;
    self.oldPasswordfield.secureTextEntry = YES;
    topPos += inputHeight;
    self.oldLine = [[UIView alloc] initWithFrame:CGRectMake(16, topPos, screenWidth - 16 - 16, 1)];
    self.oldLine.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.oldLabel];
    [self.view addSubview:self.oldPasswordfield];
    [self.view addSubview:self.oldLine];
    topPos += 1;
    
    topPos += 16;
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(16, topPos, labelWidth, inputHeight)];
    self.label.font = [UIFont systemFontOfSize:16];
    self.label.text = @"新密码";
    self.passwordfield = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16, inputHeight)];
    self.passwordfield.placeholder = @"请输入新密码";
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
    self.repeatLabel.text = @"确认密码";
    
    self.repeatPasswordField = [[UITextField alloc] initWithFrame:CGRectMake(16 + labelWidth + 8, topPos, screenWidth - 16 - labelWidth - 8 - 16, inputHeight)];
    self.repeatPasswordField.placeholder = @"请输入确认密码";
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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)onRightBtn:(id)sender {
    NSString *password = self.passwordfield.text;
    NSString *old = self.oldPasswordfield.text;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"保存中...";
    [hud showAnimated:YES];
    __weak typeof(self)ws = self;
    [[AppService sharedAppService] changePassword:old newPassword:password success:^{
        NSLog(@"change success");
        [hud hideAnimated:YES];
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int errCode, NSString * _Nonnull message) {
        NSLog(@"change failure");
        [hud hideAnimated:YES];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"保存失败";
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
    NSString *old = self.oldPasswordfield.text;
    
    if (password.length && [password isEqualToString:repeat] && old.length >= 4) {
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
    NSString *old =self.oldPasswordfield.text;
    
    if(anotherTxt.length && [anotherTxt isEqualToString:txt] && old.length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    return YES;
}

@end
