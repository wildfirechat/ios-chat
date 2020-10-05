//
//  PCSessionViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "PCSessionViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "MBProgressHUD.h"
#import "AppService.h"

@interface PCSessionViewController ()

@end

@implementation PCSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 200)/2, 120, 200, 200)];
    pcView.image = [UIImage imageNamed:@"pc"];
    [self.view addSubview:pcView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, 320, 200, 16)];
    [label setText:@"电脑已登录"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];
    
    UIButton *logoutBtn = [[UIButton alloc] initWithFrame:CGRectMake(90, height - 150, width - 180, 36)];
    [logoutBtn setBackgroundColor:[UIColor redColor]];
    [logoutBtn setTitle:@"退出电脑登录" forState:UIControlStateNormal];
    logoutBtn.layer.masksToBounds = YES;
    logoutBtn.layer.cornerRadius = 5.f;
    [logoutBtn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            [logoutBtn setTitle:@"退出 Windows 登录" forState:UIControlStateNormal];
            [label setText:@"Windows 已登录"];
        } else if(infos[0].platform == PlatformType_OSX) {
            [logoutBtn setTitle:@"退出 Mac 登录" forState:UIControlStateNormal];
            [label setText:@"Mac 已登录"];
        } else if(infos[0].platform == PlatformType_Linux) {
            [logoutBtn setTitle:@"退出 Linux 登录" forState:UIControlStateNormal];
            [label setText:@"Linux 已登录"];
        } else if(infos[0].platform == PlatformType_WEB) {
            [logoutBtn setTitle:@"退出 Web 登录" forState:UIControlStateNormal];
            [label setText:@"Web 已登录"];
        } else if(infos[0].platform == PlatformType_WX) {
            [logoutBtn setTitle:@"退出小程序登录" forState:UIControlStateNormal];
            [label setText:@"小程序已登录"];
        }
    }
    
    
    [self.view addSubview:logoutBtn];

}

- (void)onLogoutBtn:(id)sender {
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] kickoffPCClient:self.pcClientInfo.clientId success:^{
        [ws sendLogoutDone:YES isLogin:YES];
    } error:^(int error_code) {
        [ws sendLogoutDone:NO isLogin:YES];
    }];
}

- (void)sendLogoutDone:(BOOL)result isLogin:(BOOL)isLogin {
    if (!result) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"网络错误";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        [hud hideAnimated:YES afterDelay:1.f];
    } else if(isLogin) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"成功";
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        __weak typeof(self)ws = self;
        [hud setCompletionBlock:^{
            [ws.navigationController popViewControllerAnimated:YES];
        }];
        [hud hideAnimated:YES afterDelay:1.f];
    }
}
@end
