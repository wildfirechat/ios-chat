//
//  PCSessionViewController.m
//  WildFireChat
//
//  Created by heavyrain lee on 2019/3/2.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "PCSessionViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCNetworkService.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "MBProgressHUD.h"
#import "AppService.h"

#define CELL_HEIGHT 56

@interface PCSessionViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UISwitch *muteSwitch;
@property(nonatomic, strong)UISwitch *lockSwitch;
@property(nonatomic, strong)NSString *pcStatusText;
@end

@implementation PCSessionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.f]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self checkPCOnlineStatus];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    [self checkPCOnlineStatus];
}

- (void)checkPCOnlineStatus {
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    BOOL pcStillOnline = NO;
    for (WFCCPCOnlineInfo *info in infos) {
        if ([info.clientId isEqualToString:self.pcClientInfo.clientId]) {
            pcStillOnline = YES;
            break;
        }
    }
    if (!pcStillOnline) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)setupUI {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    
    // 计算导航栏和状态栏高度
    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].keyWindow.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    CGFloat topOffset = navBarHeight + statusBarHeight;
    
    // PC图标
    UIImageView *pcView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 120)/2, topOffset + 20, 120, 120)];
    pcView.image = [UIImage imageNamed:@"pc"];
    [self.view addSubview:pcView];
    
    // 状态标签
    self.pcStatusText = LocalizedString(@"PCLoggedIn");
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            self.pcStatusText = LocalizedString(@"WindowsLoggedIn");
        } else if(infos[0].platform == PlatformType_OSX) {
            self.pcStatusText = LocalizedString(@"MacLoggedIn");
        } else if(infos[0].platform == PlatformType_Linux) {
            self.pcStatusText = LocalizedString(@"LinuxLoggedIn");
        } else if(infos[0].platform == PlatformType_WEB) {
            self.pcStatusText = LocalizedString(@"WebLoggedIn");
        } else if(infos[0].platform == PlatformType_WX) {
            self.pcStatusText = LocalizedString(@"MiniProgramLoggedIn");
        } else if(infos[0].platform == PlatformType_iPad) {
            self.pcStatusText = LocalizedString(@"IPadLoggedIn");
        } else if(infos[0].platform == PlatformType_Android) {
            self.pcStatusText = LocalizedString(@"AndroidTabletLoggedIn");
        }
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((width - 200)/2, topOffset + 150, 200, 20)];
    [label setText:self.pcStatusText];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:16]];
    [label setTextColor:[UIColor darkGrayColor]];
    [self.view addSubview:label];
    
    // 列表
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, topOffset + 190, width, 56 * 3) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    // 退出登录按钮
    UIButton *logoutBtn = [[UIButton alloc] initWithFrame:CGRectMake(40, height - 80, width - 80, 44)];
    [logoutBtn setBackgroundColor:[UIColor redColor]];
    [logoutBtn setTitle:LocalizedString(@"LogoutPC") forState:UIControlStateNormal];
    logoutBtn.layer.masksToBounds = YES;
    logoutBtn.layer.cornerRadius = 5.f;
    [logoutBtn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            [logoutBtn setTitle:LocalizedString(@"LogoutWindows") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_OSX) {
            [logoutBtn setTitle:LocalizedString(@"LogoutMac") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_Linux) {
            [logoutBtn setTitle:LocalizedString(@"LogoutLinux") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_WEB) {
            [logoutBtn setTitle:LocalizedString(@"LogoutWeb") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_WX) {
            [logoutBtn setTitle:LocalizedString(@"LogoutMiniProgram") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_iPad) {
            [logoutBtn setTitle:LocalizedString(@"LogoutIPad") forState:UIControlStateNormal];
        } else if(infos[0].platform == PlatformType_Android) {
            [logoutBtn setTitle:LocalizedString(@"LogoutAndroidTablet") forState:UIControlStateNormal];
        }
    }
    
    [self.view addSubview:logoutBtn];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PCSessionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // 移除之前的accessoryView
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.row) {
        case 0: {
            // 静音
            cell.textLabel.text = LocalizedString(@"MutePhone");
            self.muteSwitch = [[UISwitch alloc] init];
            self.muteSwitch.on = [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline];
            [self.muteSwitch addTarget:self action:@selector(onMuteSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.muteSwitch;
            break;
        }
        case 1: {
            // 锁定
            cell.textLabel.text = LocalizedString(@"LockPC");
            self.lockSwitch = [[UISwitch alloc] init];
            self.lockSwitch.on = [[WFCCIMService sharedWFCIMService] isPCClientLocked:self.pcClientInfo.clientId];
            [self.lockSwitch addTarget:self action:@selector(onLockSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.lockSwitch;
            break;
        }
        case 2: {
            // 文件助手
            cell.textLabel.text = LocalizedString(@"TransferFile");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 2) {
        // 文件助手
        [self openFileTransfer];
    }
}

#pragma mark - Actions

- (void)onMuteSwitchChanged:(UISwitch *)sender {
    BOOL isMute = sender.on;
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] muteNotificationWhenPcOnline:isMute success:^{
        // 成功
    } error:^(int error_code) {
        // 失败，恢复开关状态
        [ws.muteSwitch setOn:!isMute animated:YES];
        [ws showError:@"设置失败"];
    }];
}

- (void)onLockSwitchChanged:(UISwitch *)sender {
    BOOL isLock = sender.on;
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] lockPCClient:self.pcClientInfo.clientId isLock:isLock success:^{
        // 成功
    } error:^(int error_code) {
        // 失败，恢复开关状态
        [ws.lockSwitch setOn:!isLock animated:YES];
        [ws showError:@"设置失败"];
    }];
}

- (void)openFileTransfer {
    if ([WFCUConfigManager globalManager].fileTransferId) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:[WFCUConfigManager globalManager].fileTransferId line:0];
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
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
        [self showError:LocalizedString(@"NetworkError")];
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

- (void)showError:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
    [hud hideAnimated:YES afterDelay:1.f];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
