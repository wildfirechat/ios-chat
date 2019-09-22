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
        default:
            break;
    }
    
    self.textField.text = defaultValue;
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

- (void)selectionDidChange:(nullable id<UITextInput>)textInput {
    
}


- (void)selectionWillChange:(nullable id<UITextInput>)textInput {
    
}


- (void)textWillChange:(nullable id<UITextInput>)textInput {

}


@end
