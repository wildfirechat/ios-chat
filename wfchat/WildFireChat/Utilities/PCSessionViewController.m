//
//  PCSessionViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "PCSessionViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "MBProgressHUD.h"
#import "AppService.h"


@interface PCSessionViewController ()
@property(nonatomic, strong)UIButton *muteBtn;
@end

@implementation PCSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 200)/2, 100, 200, 200)];
    pcView.image = [UIImage imageNamed:@"pc"];
    [self.view addSubview:pcView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, 300, 200, 16)];
    [label setText:@"电脑已登录"];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];
    
    self.muteBtn = [[UIButton alloc] initWithFrame:CGRectMake((width-width/3)/2-35, 336, 70, 70)];
    [self.muteBtn setImage:[UIImage imageNamed:@"mute_notification"] forState:UIControlStateNormal];
    [self.muteBtn setImage:[UIImage imageNamed:@"mute_notification_hover"] forState:UIControlStateSelected];
    self.muteBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    self.muteBtn.layer.cornerRadius = 35;
    self.muteBtn.layer.masksToBounds = YES;
    if ([[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
        [self.muteBtn setSelected:YES];
        self.muteBtn.backgroundColor = [UIColor colorWithRed:62.f/255 green:100.f/255 blue:228.f/255 alpha:1.f];
    }
    [self.muteBtn addTarget:self action:@selector(onMuteBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.muteBtn];
    UILabel *muteLabel = [[UILabel alloc] initWithFrame:CGRectMake((width-width/3)/2-35, 410, 70, 15)];
    [muteLabel setText:@"手机静音"];
    [muteLabel setFont:[UIFont systemFontOfSize:12]];
    [muteLabel setTextColor:[UIColor grayColor]];
    [muteLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:muteLabel];
    
    UIButton *fileBtn = [[UIButton alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 336, 70, 70)];
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateNormal];
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateSelected];
    fileBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    fileBtn.layer.cornerRadius = 35;
    fileBtn.layer.masksToBounds = YES;
    [fileBtn addTarget:self action:@selector(onFileBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fileBtn];
    UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 410, 70, 15)];
    [fileLabel setText:@"传输文件"];
    [fileLabel setFont:[UIFont systemFontOfSize:12]];
    [fileLabel setTextColor:[UIColor grayColor]];
    [fileLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:fileLabel];
    
    
    UIButton *logoutBtn = [[UIButton alloc] initWithFrame:CGRectMake(90, height - 120, width - 180, 36)];
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

- (void)onMuteBtn:(id)sender {
    BOOL pre = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] muteNotificationWhenPcOnline:!pre success:^{
        if ([[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
            ws.muteBtn.selected = YES;
            ws.muteBtn.backgroundColor = [UIColor colorWithRed:62.f/255 green:100.f/255 blue:228.f/255 alpha:1.f];
        } else {
            ws.muteBtn.selected = NO;
            ws.muteBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
        }
    } error:^(int error_code) {
        
    }];
}

- (void)onFileBtn:(id)sender {
    if ([WFCUConfigManager globalManager].fileTransferId) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:[WFCUConfigManager globalManager].fileTransferId line:0];
    
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}
@end
