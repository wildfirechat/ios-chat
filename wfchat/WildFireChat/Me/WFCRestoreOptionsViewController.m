//
//  WFCRestoreOptionsViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCRestoreOptionsViewController.h"
#import "WFCBackupProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCRestoreOptionsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL overwriteExisting;
@end

@implementation WFCRestoreOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"恢复选项";
    self.overwriteExisting = NO;

    // 创建开始恢复按钮
    UIBarButtonItem *restoreButton = [[UIBarButtonItem alloc] initWithTitle:@"开始恢复"
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(startRestore)];
    self.navigationItem.rightBarButtonItem = restoreButton;

    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Actions

- (void)startRestore {
    // 确认对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认恢复"
                                                                   message:@"恢复操作将会添加备份中的消息到当前设备。是否继续？"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
        [self performRestore];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    [alert addAction:confirmAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)performRestore {
    // 跳转到进度界面
    WFCBackupProgressViewController *vc = [[WFCBackupProgressViewController alloc] init];
    vc.backupFilePath = self.backupFilePath;
    vc.backupInfo = self.backupInfo;
    vc.overwriteExisting = self.overwriteExisting;
    vc.isRestoreMode = YES;
    // 使用当前用户ID作为恢复密码
    vc.backupPassword = [WFCCNetworkService sharedInstance].userId;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 基础信息3行 + 可选的媒体信息
    NSInteger mediaFileCount = [self.backupInfo[@"mediaFileCount"] integerValue];
    NSInteger baseRows = 3; // 备份时间、会话数量、消息数量
    return mediaFileCount > 0 ? baseRows + 1 : baseRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"备份信息";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"InfoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    switch (indexPath.row) {
        case 0: {
            // 备份时间
            cell.textLabel.text = @"备份时间";
            NSString *backupTime = self.backupInfo[@"backupTime"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
            NSDate *date = [formatter dateFromString:backupTime];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm";
            cell.detailTextLabel.text = [formatter stringFromDate:date];
            break;
        }
        case 1: {
            // 会话数量
            cell.textLabel.text = @"会话数量";
            NSInteger count = [self.backupInfo[@"totalConversations"] integerValue];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld 个", (long)count];
            break;
        }
        case 2: {
            // 消息数量
            cell.textLabel.text = @"消息数量";
            NSInteger count = [self.backupInfo[@"totalMessages"] integerValue];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld 条", (long)count];
            break;
        }
        case 3: {
            // 媒体文件
            cell.textLabel.text = @"媒体文件";
            NSInteger mediaFileCount = [self.backupInfo[@"mediaFileCount"] integerValue];
            long long mediaTotalSize = [self.backupInfo[@"mediaTotalSize"] longLongValue];
            NSString *sizeStr = [self formatFileSize:mediaTotalSize];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld 个 (%@)", (long)mediaFileCount, sizeStr];
            break;
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark - Helper Methods

- (NSString *)formatFileSize:(long long)bytes {
    if (bytes < 1024) {
        return [NSString stringWithFormat:@"%lld B", bytes];
    } else if (bytes < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", bytes / 1024.0];
    } else if (bytes < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", bytes / (1024.0 * 1024)];
    } else {
        return [NSString stringWithFormat:@"%.2f GB", bytes / (1024.0 * 1024 * 1024)];
    }
}

@end
