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
#import "WFCUConfigManager.h"
#import "UIView+Toast.h"

@interface WFCUModifyMyProfileViewController () <UITextFieldDelegate>
@property(nonatomic, strong)UITextField *textField;
@property(nonatomic, assign)BOOL isAccount;
@end

@implementation WFCUModifyMyProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    NSString *title = nil;
    NSString *defaultValue = nil;
    self.isAccount = NO;
    switch (self.modifyType) {
        case Modify_Email:
            title = WFCString(@"ModifyEmail");
            defaultValue = userInfo.email;
            self.textField.keyboardType = UIKeyboardTypeEmailAddress;
            break;
        
        case Modify_Mobile:
            title = WFCString(@"ModifyMobile");
            defaultValue = userInfo.mobile;
            self.textField.keyboardType = UIKeyboardTypePhonePad;
            break;
        
        case Modify_Social:
            title = WFCString(@"ModifySocialAccount");
            defaultValue = userInfo.social;
            break;
            
        case Modify_Address:
            title = WFCString(@"ModifyAddress");
            defaultValue = userInfo.address;
            break;
            
        case Modify_Company:
            title = WFCString(@"ModifyCompanyInfo");
            defaultValue = userInfo.company;
            break;
            
        case Modify_DisplayName:
            title = WFCString(@"ModifyNickname");
            defaultValue = userInfo.displayName;
            break;
        case 100:
            title = @"修改账户名";
            defaultValue = userInfo.name;
            self.isAccount = YES;
            self.textField.keyboardType = UIKeyboardTypeASCIICapable;
            break;
        default:
            break;
    }
    
    self.textField.text = defaultValue;
    self.textField.returnKeyType = UIReturnKeyDone;
    [self setTitle:title];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Ok") style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    [self.textField becomeFirstResponder];
}

- (void)onDone:(id)sender {
    [self.textField resignFirstResponder];
    __weak typeof(self) ws = self;
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Updating");
    [hud showAnimated:YES];
    
    if (self.modifyType == 100) {
        [[WFCUConfigManager globalManager].appServiceProvider changeName:self.textField.text success:^{
            [hud hideAnimated:NO];
            self.onModified(self.modifyType, self.textField.text);
            [ws.navigationController popViewControllerAnimated:YES];
        } error:^(int errorCode, NSString * _Nonnull message) {
            [hud hideAnimated:NO];
            
            hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = message;
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];
    } else {
        [[WFCCIMService sharedWFCIMService] modifyMyInfo:@{@(self.modifyType):self.textField.text} success:^{
            [hud hideAnimated:NO];
            self.onModified(self.modifyType, self.textField.text);
            [ws.navigationController popViewControllerAnimated:YES];
        } error:^(int error_code) {
            [hud hideAnimated:NO];
            
            hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = WFCString(@"UpdateFailure");
            hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
            [hud hideAnimated:YES afterDelay:1.f];
        }];
    }
    
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
        [_textField addTarget:self action:@selector(textFieldChange:) forControlEvents:UIControlEventEditingChanged];
        [self.view addSubview:_textField];
    }
    return _textField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    BOOL ret = [string isEqualToString:filtered];
    if(!ret) {
        [self.view makeToast:@"不支持的字符！仅支持英文字母和数字！" duration:0.5 position:CSToastPositionCenter];
    }
    return ret;
}

- (void)textFieldChange:(UITextField *)field {
    if (self.textField.text.length) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self onDone:textField];
    return YES;
}

@end
