//
//  ModifyMyProfileViewController.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/20.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUModifyMyProfileViewController.h"
#import "MBProgressHUD.h"
#import <WFChatClient/WFCChatClient.h>


@interface WFCUModifyMyProfileViewController () <UITextFieldDelegate, UITextInputDelegate>
@property(nonatomic, strong)UITextField *textField;
@end

@implementation WFCUModifyMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    NSString *title = nil;
    NSString *defaultValue = nil;
    switch (self.modifyType) {
        case Modify_Email:
            title = @"修改邮箱";
            defaultValue = userInfo.email;
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        
        case Modify_Mobile:
            title = @"修改电话";
            defaultValue = userInfo.mobile;
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            break;
        
        case Modify_Social:
            title = @"修改社交账号";
            defaultValue = userInfo.social;
            break;
            
        case Modify_Address:
            title = @"修改地址";
            defaultValue = userInfo.address;
            break;
            
        case Modify_Company:
            title = @"修改公司信息";
            defaultValue = userInfo.company;
            break;
            
        case Modify_DisplayName:
            title = @"修改昵称";
            defaultValue = userInfo.displayName;
            break;
        default:
            break;
    }
    
    self.textField.text = defaultValue;
    [self setTitle:title];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:232/255.f green:232/255.f blue:232/255.f alpha:1.f]];
    
    [self.textField becomeFirstResponder];
}

- (void)onDone:(id)sender {
    [self.textField resignFirstResponder];
    __weak typeof(self) ws = self;
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"修改中...";
    [hud showAnimated:YES];
    
    [[WFCCIMService sharedWFCIMService] modifyMyInfo:@{@(self.modifyType):self.textField.text} success:^{
        [hud hideAnimated:NO];
        self.onModified(self.modifyType, self.textField.text);
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"修改失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITextField *)textField {
    if(!_textField) {
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, kStatusBarAndNavigationBarHeight + 20, [UIScreen mainScreen].bounds.size.width, 32)];
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.clearButtonMode = UITextFieldViewModeAlways;
        _textField.delegate = self;
        _textField.inputDelegate = self;
        [self.view addSubview:_textField];
    }
    return _textField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onDone:textField];
    return YES;
}

#pragma mark - UITextInputDelegate
- (void)textDidChange:(nullable id <UITextInput>)textInput {
    if (self.textField.text.length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

@end
