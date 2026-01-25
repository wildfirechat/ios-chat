//
//  WFCBackupAndRestoreViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupAndRestoreViewController.h"
#import "WFCConversationSelectViewController.h"
#import "WFCBackupListViewController.h"
#import "WFCRestoreSourceViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCBackupAndRestoreViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *menuItems;
@end

@implementation WFCBackupAndRestoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"BackupAndRestore");

    // 初始化菜单项
    self.menuItems = @[
        @{
            @"title": LocalizedString(@"CreateBackup"),
            @"subtitle": LocalizedString(@"CreateBackupDescription"),
            @"icon": @"doc.fill",
            @"action": @"createBackup"
        },
        @{
            @"title": LocalizedString(@"RestoreBackup"),
            @"subtitle": LocalizedString(@"RestoreBackupDescription"),
            @"icon": @"arrow.down.doc.fill",
            @"action": @"restoreBackup"
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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"MenuItemCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSDictionary *item = self.menuItems[indexPath.row];
    cell.textLabel.text = item[@"title"];
    cell.detailTextLabel.text = item[@"subtitle"];
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    if (@available(iOS 13.0, *)) {
        NSString *iconName = item[@"icon"];
        UIImage *icon = [UIImage systemImageNamed:iconName];
        cell.imageView.image = icon;
        cell.imageView.tintColor = [UIColor systemBlueColor];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = self.menuItems[indexPath.row];
    NSString *action = item[@"action"];

    if ([action isEqualToString:@"createBackup"]) {
        [self createBackup];
    } else if ([action isEqualToString:@"restoreBackup"]) {
        [self restoreBackup];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - Actions

- (void)createBackup {
    WFCConversationSelectViewController *vc = [[WFCConversationSelectViewController alloc] init];
    vc.mode = ConversationSelectModeBackup;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)restoreBackup {
    WFCRestoreSourceViewController *vc = [[WFCRestoreSourceViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
