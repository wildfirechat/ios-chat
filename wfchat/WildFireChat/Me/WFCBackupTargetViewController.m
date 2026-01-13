//
//  WFCBackupTargetViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupTargetViewController.h"
#import "WFCBackupProgressViewController.h"
#import "WFCBackupRequestProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCBackupRequestNotificationContent.h>

@interface WFCBackupTargetViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *targetOptions;
@property (nonatomic, assign) BOOL isPCOnline;
@end

@implementation WFCBackupTargetViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"选择备份位置";

    // 初始化备份目标选项
    self.targetOptions = @[
        @{
            @"title": @"备份到本地",
            @"subtitle": @"将备份保存到iPhone本地存储",
            @"icon": @"iphone",
            @"action": @"local"
        },
        @{
            @"title": @"备份到电脑端",
            @"subtitle": @"将备份保存到已登录的电脑端",
            @"icon": @"desktopcomputer",
            @"action": @"pc"
        }
    ];

    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.tableView];

    // 添加说明文字
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    infoLabel.text = @"请选择备份保存位置";
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.textColor = [UIColor secondaryLabelColor];
    infoLabel.font = [UIFont systemFontOfSize:14];
    self.tableView.tableHeaderView = infoLabel;

    // 监听连接状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePCOnlineStatus)
                                                 name:kSettingUpdated
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updatePCOnlineStatus];
}

- (void)updatePCOnlineStatus {
    BOOL previousStatus = self.isPCOnline;
    self.isPCOnline = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos].count > 0;

    // 如果状态发生变化，刷新表格
    if (previousStatus != self.isPCOnline) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.targetOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TargetCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSDictionary *option = self.targetOptions[indexPath.row];
    NSString *action = option[@"action"];

    cell.textLabel.text = option[@"title"];
    cell.detailTextLabel.text = option[@"subtitle"];
    cell.detailTextLabel.numberOfLines = 0;

    // 检查是否是PC选项且PC是否在线
    if ([action isEqualToString:@"pc"] && !self.isPCOnline) {
        // PC不在线时显示为灰色
        cell.textLabel.textColor = [UIColor tertiaryLabelColor];
        cell.detailTextLabel.textColor = [UIColor tertiaryLabelColor];
        cell.userInteractionEnabled = NO;
        if (@available(iOS 13.0, *)) {
            NSString *iconName = option[@"icon"];
            UIImage *icon = [UIImage systemImageNamed:iconName];
            if (icon) {
                cell.imageView.image = icon;
                cell.imageView.tintColor = [UIColor tertiaryLabelColor];
            }
        }
    } else {
        // 正常状态
        cell.textLabel.textColor = [UIColor labelColor];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.userInteractionEnabled = YES;
        if (@available(iOS 13.0, *)) {
            NSString *iconName = option[@"icon"];
            UIImage *icon = [UIImage systemImageNamed:iconName];
            if (icon) {
                cell.imageView.image = icon;
                cell.imageView.tintColor = [UIColor systemBlueColor];
            }
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *option = self.targetOptions[indexPath.row];
    NSString *action = option[@"action"];

    if ([action isEqualToString:@"local"]) {
        [self backupToLocal];
    } else if ([action isEqualToString:@"pc"]) {
        [self backupToPC];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Actions

- (void)backupToLocal {
    // 原有的本地备份流程
    WFCBackupProgressViewController *vc = [[WFCBackupProgressViewController alloc] init];
    vc.conversations = self.conversations;
    vc.includeMedia = self.includeMedia;
    // 使用当前用户ID作为备份密码
    vc.backupPassword = [[WFCCNetworkService sharedInstance] userId];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)backupToPC {
    // 跳转到备份请求进度界面
    WFCBackupRequestProgressViewController *vc = [[WFCBackupRequestProgressViewController alloc] init];
    vc.conversations = self.conversations;
    vc.includeMedia = self.includeMedia;
    [self.navigationController pushViewController:vc animated:YES];

    // 开始发送备份请求
    [vc startBackupRequest];
}

@end
