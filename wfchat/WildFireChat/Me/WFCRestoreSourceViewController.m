//
//  WFCRestoreSourceViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCRestoreSourceViewController.h"
#import "WFCRestoreOptionsViewController.h"
#import "WFCPCRestoreListViewController.h"
#import "WFCBackupListViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCRestoreSourceViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *sourceOptions;
@property (nonatomic, assign) BOOL isPCOnline;
@end

@implementation WFCRestoreSourceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"SelectRestoreLocation");

    // 初始化恢复源选项
    self.sourceOptions = @[
        @{
            @"title": LocalizedString(@"RestoreFromLocal"),
            @"subtitle": LocalizedString(@"RestoreFromLocalDescription"),
            @"icon": @"iphone",
            @"action": @"local"
        },
        @{
            @"title": LocalizedString(@"RestoreFromPC"),
            @"subtitle": LocalizedString(@"RestoreFromPCDescription"),
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
    infoLabel.text = LocalizedString(@"PleaseSelectRestoreSource");
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
    return self.sourceOptions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SourceCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSDictionary *option = self.sourceOptions[indexPath.row];
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

    NSDictionary *option = self.sourceOptions[indexPath.row];
    NSString *action = option[@"action"];

    if ([action isEqualToString:@"local"]) {
        [self restoreFromLocal];
    } else if ([action isEqualToString:@"pc"]) {
        [self restoreFromPC];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Actions

- (void)restoreFromLocal {
    // 跳转到本地备份列表界面
    WFCBackupListViewController *vc = [[WFCBackupListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)restoreFromPC {
    // 跳转到PC恢复列表界面
    WFCPCRestoreListViewController *vc = [[WFCPCRestoreListViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
