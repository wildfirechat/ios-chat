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
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 200)/2, 100, 200, 200)];
    pcView.image = [UIImage imageNamed:@"pc"];
    pcView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:pcView];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, 300, 200, 16)];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [label setText:LocalizedString(@"PCLoggedIn")];
    [label setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:label];

    self.muteBtn = [[UIButton alloc] initWithFrame:CGRectMake((width-width/3)/2-35, 336, 70, 70)];
    self.muteBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
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
    muteLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [muteLabel setText:LocalizedString(@"MutePhone")];
    [muteLabel setFont:[UIFont systemFontOfSize:12]];
    [muteLabel setTextColor:[UIColor grayColor]];
    [muteLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:muteLabel];

    UIButton *fileBtn = [[UIButton alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 336, 70, 70)];
    fileBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateNormal];
    [fileBtn setImage:[UIImage imageNamed:@"pc_file_transfer"] forState:UIControlStateSelected];
    fileBtn.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f];
    fileBtn.layer.cornerRadius = 35;
    fileBtn.layer.masksToBounds = YES;
    [fileBtn addTarget:self action:@selector(onFileBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fileBtn];
    UILabel *fileLabel = [[UILabel alloc] initWithFrame:CGRectMake((width+width/3)/2-35, 410, 70, 15)];
    fileLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [fileLabel setText:LocalizedString(@"TransferFile")];
    [fileLabel setFont:[UIFont systemFontOfSize:12]];
    [fileLabel setTextColor:[UIColor grayColor]];
    [fileLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:fileLabel];


    UIButton *logoutBtn = [[UIButton alloc] initWithFrame:CGRectMake(90, height - 120, width - 180, 36)];
    logoutBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [logoutBtn setBackgroundColor:[UIColor redColor]];
    [logoutBtn setTitle:LocalizedString(@"LogoutPC") forState:UIControlStateNormal];
    logoutBtn.layer.masksToBounds = YES;
    logoutBtn.layer.cornerRadius = 5.f;
    [logoutBtn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            [logoutBtn setTitle:LocalizedString(@"LogoutWindows") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"WindowsLoggedIn")];
        } else if(infos[0].platform == PlatformType_OSX) {
            [logoutBtn setTitle:LocalizedString(@"LogoutMac") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"MacLoggedIn")];
        } else if(infos[0].platform == PlatformType_Linux) {
            [logoutBtn setTitle:LocalizedString(@"LogoutLinux") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"LinuxLoggedIn")];
        } else if(infos[0].platform == PlatformType_WEB) {
            [logoutBtn setTitle:LocalizedString(@"LogoutWeb") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"WebLoggedIn")];
        } else if(infos[0].platform == PlatformType_WX) {
            [logoutBtn setTitle:LocalizedString(@"LogoutMiniProgram") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"MiniProgramLoggedIn")];
        } else if(infos[0].platform == PlatformType_iPad) {
            [logoutBtn setTitle:LocalizedString(@"LogoutIPad") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"IPadLoggedIn")];
        } else if(infos[0].platform == PlatformType_Android) {
            [logoutBtn setTitle:LocalizedString(@"LogoutAndroidTablet") forState:UIControlStateNormal];
            [label setText:LocalizedString(@"AndroidTabletLoggedIn")];
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
        hud.label.text = LocalizedString(@"NetworkError");
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        
        [hud hideAnimated:YES afterDelay:1.f];
    } else if(isLogin) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = LocalizedString(@"Success");
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
