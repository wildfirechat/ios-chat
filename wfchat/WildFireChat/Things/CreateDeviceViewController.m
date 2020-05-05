//
//  CreateDeviceViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "CreateDeviceViewController.h"
#import "AppService.h"
#import "MBProgressHUD.h"
@interface CreateDeviceViewController () <UITextFieldDelegate>
@property (nonatomic, strong)UITextField *deviceNameField;
@property (nonatomic, strong)UITextField *deviceIdField;
@property (nonatomic, strong)UIButton *createBtn;
@end

@implementation CreateDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    CGFloat width = self.view.frame.size.width;
    
    self.deviceNameField = [[UITextField alloc] initWithFrame:CGRectMake(16, 120, width - 32, 24)];
    self.deviceNameField.placeholder = @"请输入设备名称";
    self.deviceNameField.delegate = self;
    self.deviceNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.deviceNameField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.view addSubview:self.deviceNameField];
    
    self.deviceIdField = [[UITextField alloc] initWithFrame:CGRectMake(16, 160, width - 32, 24)];
    self.deviceIdField.placeholder = @"请输入设备ID，如果为空，系统会自动生成";
    self.deviceIdField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:self.deviceIdField];
    
    self.createBtn = [[UIButton alloc] initWithFrame:CGRectMake((width - 160)/2, self.view.bounds.size.height/2 - 20, 160, 40)];
    [self.createBtn setTitle:@"创建设备" forState:UIControlStateNormal];
    [self.createBtn addTarget:self action:@selector(onCreateBtn:) forControlEvents:UIControlEventTouchDown];
    self.createBtn.enabled = NO;
    [self.createBtn setBackgroundColor:[UIColor greenColor]];
    [self.view addSubview:self.createBtn];
    
}

- (void)onCreateBtn:(id)sender {
    self.createBtn.enabled = NO;
    
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"创建中...";
    [hud showAnimated:YES];
    
    [[AppService sharedAppService] addDevice:self.deviceNameField.text deviceId:self.deviceIdField.text owner:@[[WFCCNetworkService sharedInstance].userId] success:^(Device * _Nonnull device) {
        [hud hideAnimated:NO];
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"创建失败";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        NSLog(@"Create device error!!!!");
        ws.createBtn.enabled = YES;
    }];
}
- (void)textDidChange:(id<UITextInput>)textInput {
    self.createBtn.enabled = textInput.hasText;
}
@end
