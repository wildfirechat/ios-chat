//
//  DeviceInfoViewController.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/5/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "DeviceInfoViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "MBProgressHUD.h"
#import "AppService.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface DeviceInfoViewController ()
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *idLabel;
@property(nonatomic, strong)UILabel *tokenLabel;
@property(nonatomic, strong)UILabel *ownerLabel;
@end

@implementation DeviceInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat width = self.view.bounds.size.width;
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 120, width - 32, 20)];
    self.nameLabel.text = [NSString stringWithFormat:LocalizedString(@"DeviceName"), self.device.name];
    [self.view addSubview:self.nameLabel];
    
    self.idLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 148, width - 32, 20)];
    self.idLabel.text = [NSString stringWithFormat:LocalizedString(@"DeviceIdLabel"), self.device.deviceId];
    [self.view addSubview:self.idLabel];
    
    self.tokenLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 176, width - 32, 20)];
    self.tokenLabel.text = [NSString stringWithFormat:LocalizedString(@"DeviceToken"), self.device.token];
    [self.view addSubview:self.tokenLabel];
    
    
    CGRect bounds = self.view.bounds;
    
    UIButton *modifyBtn = [[UIButton alloc] initWithFrame:CGRectMake((bounds.size.width - 100 - 100 - 20)/2, (bounds.size.height - 20)/2, 100, 40)];
    [modifyBtn addTarget:self action:@selector(onModifyBtn:) forControlEvents:UIControlEventTouchDown];
    [modifyBtn setTitle:LocalizedString(@"ModifyDeviceName") forState:UIControlStateNormal];
    [modifyBtn setBackgroundColor:[UIColor redColor]];
    modifyBtn.layer.masksToBounds = YES;
    modifyBtn.layer.cornerRadius = 5.f;
    modifyBtn.tag = 0;
    
    
    UIButton *delBtn = [[UIButton alloc] initWithFrame:CGRectMake((bounds.size.width - 100 - 100 - 20)/2 + 100 + 20, (bounds.size.height - 20)/2, 100, 40)];
    [delBtn addTarget:self action:@selector(onDeleteBtn:) forControlEvents:UIControlEventTouchDown];
    [delBtn setTitle:LocalizedString(@"DeleteDevice") forState:UIControlStateNormal];
    [delBtn setBackgroundColor:[UIColor redColor]];
    delBtn.layer.masksToBounds = YES;
    delBtn.layer.cornerRadius = 5.f;
    delBtn.tag = 1;
    
    [self.view addSubview:modifyBtn];
    [self.view addSubview:delBtn];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"SendToMe") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
}

- (void)onModifyBtn:(id)sender {
    WFCUGeneralModifyViewController *vc = [[WFCUGeneralModifyViewController alloc] init];
    vc.defaultValue = self.device.name;
    vc.titleText = LocalizedString(@"ModifyDeviceNameTitle");
    __weak typeof(self) ws = self;
    vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
        [[AppService sharedAppService] addDevice:newValue deviceId:ws.device.deviceId owner:ws.device.owners success:^(Device * _Nonnull device) {
            ws.device = device;
            ws.nameLabel.text = [NSString stringWithFormat:LocalizedString(@"DeviceName"), ws.device.name];
            result(YES);
        } error:^(int error_code) {
            result(NO);
        }];
    };
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)onDeleteBtn:(id)sender {
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LocalizedString(@"Deleting");
    [hud showAnimated:YES];
    
    [[AppService sharedAppService] delDevice:self.device.deviceId success:^(Device * _Nonnull device) {
        [hud hideAnimated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"Deleted");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
        if (ws.navigationController.viewControllers.count >= 3) {
            [ws.navigationController popToViewController:[ws.navigationController.viewControllers objectAtIndex:ws.navigationController.viewControllers.count-3] animated:YES];
        }
        
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"DeleteFailed");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

- (void)onRightBtn:(id)sender {
    __weak typeof(self) ws = self;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = LocalizedString(@"SendingTo");
    [hud showAnimated:YES];
    
    WFCCConversation *conv = [WFCCConversation conversationWithType:Single_Type target:[WFCCNetworkService sharedInstance].userId line:0];
    WFCCTextMessageContent *textContent = [WFCCTextMessageContent contentWith:[NSString stringWithFormat:@"DeviceName:%@, \nDeviceId:%@, \nToken:%@", self.device.name, self.device.deviceId, self.device.token]];
    [[WFCCIMService sharedWFCIMService] send:conv content:textContent success:^(long long messageUid, long long timestamp) {
        [hud hideAnimated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"SendToDeviceSuccess");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    } error:^(int error_code) {
        [hud hideAnimated:NO];
        hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"SendToDeviceFailed");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        [hud hideAnimated:YES afterDelay:1.f];
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
