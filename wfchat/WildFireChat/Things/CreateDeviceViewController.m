//
//  CreateDeviceViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "CreateDeviceViewController.h"
#import "AppService.h"

@interface CreateDeviceViewController () <UITextFieldDelegate>
@property (nonatomic, strong)UITextField *deviceNameField;
@property (nonatomic, strong)UITextField *deviceIdField;
@property (nonatomic, strong)UIButton *createBtn;
@end

@implementation CreateDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
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
    __weak typeof(self) ws = self;
    [[AppService sharedAppService] addDevice:self.deviceNameField.text deviceId:self.deviceIdField.text owner:@[[WFCCNetworkService sharedInstance].userId] success:^(Device * _Nonnull device) {
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int error_code) {
        NSLog(@"Create device error!!!!");
    }];
}
- (void)textDidChange:(id<UITextInput>)textInput {
    self.createBtn.enabled = textInput.hasText;
}
@end
