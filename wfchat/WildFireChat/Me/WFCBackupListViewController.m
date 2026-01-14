//
//  WFCBackupListViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupListViewController.h"
#import "WFCRestoreOptionsViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCBackupItem : NSObject
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSDate *fileDate;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, strong) NSDictionary *backupInfo;
@end

@implementation WFCBackupItem
@end

@interface WFCBackupListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCBackupItem *> *backupItems;
@end

@implementation WFCBackupListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"SelectBackup");
    self.backupItems = [NSMutableArray array];

    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // 添加编辑按钮
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self.view addSubview:self.tableView];

    // 加载备份列表
    [self loadBackupList];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadBackupList];
}

#pragma mark - Data Loading

- (void)loadBackupList {
    [self.backupItems removeAllObjects];

    // 获取文档目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *backupDirectory = [documentsDirectory stringByAppendingPathComponent:@"Backups"];

    // 创建备份目录（如果不存在）
    [[NSFileManager defaultManager] createDirectoryAtPath:backupDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    // 遍历备份目录
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:backupDirectory error:nil];
    for (NSString *fileName in files) {
        NSString *filePath = [backupDirectory stringByAppendingPathComponent:fileName];

        // 检查是否为目录
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];

        NSDictionary *backupInfo = nil;
        NSDate *fileDate = nil;
        long long fileSize = 0;

        if (isDirectory) {
            // 新格式 v2.0：目录备份
            NSString *metadataPath = [filePath stringByAppendingPathComponent:@"metadata.json"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:metadataPath]) {
                backupInfo = [[WFCCMessageBackupManager sharedManager] getDirectoryBackupInfo:filePath];
                if (backupInfo) {
                    // 获取目录信息
                    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
                    fileDate = attrs[NSFileModificationDate];
                    fileSize = [attrs fileSize];

                    WFCBackupItem *item = [[WFCBackupItem alloc] init];
                    item.filePath = filePath;
                    item.fileName = fileName;
                    item.fileDate = fileDate;
                    item.fileSize = fileSize;
                    item.backupInfo = backupInfo;
                    [self.backupItems addObject:item];
                }
            }
        }
    }

    // 按日期排序（最新的在前）
    [self.backupItems sortUsingComparator:^NSComparisonResult(WFCBackupItem *obj1, WFCBackupItem *obj2) {
        return [obj2.fileDate compare:obj1.fileDate];
    }];

    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.backupItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"BackupCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    WFCBackupItem *item = self.backupItems[indexPath.row];
    NSDictionary *info = item.backupInfo;

    // 文件名（去除扩展名）
    NSString *fileName = [item.fileName stringByDeletingPathExtension];
    cell.textLabel.text = fileName;

    // 显示详细信息
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    NSString *dateStr = [formatter stringFromDate:item.fileDate];

    NSInteger totalConversations = [info[@"totalConversations"] integerValue];
    NSInteger totalMessages = [info[@"totalMessages"] integerValue];
    NSInteger mediaFileCount = [info[@"mediaFileCount"] integerValue];
    long long mediaTotalSize = [info[@"mediaTotalSize"] longLongValue];

    // 构建显示文本
    NSMutableArray *detailParts = [NSMutableArray array];
    [detailParts addObject:dateStr];
    [detailParts addObject:[NSString stringWithFormat:LocalizedString(@"ConversationsUnit"), (long)totalConversations]];
    [detailParts addObject:[NSString stringWithFormat:LocalizedString(@"MessagesUnit"), (long)totalMessages]];

    // 只有在有媒体文件时才显示媒体信息
    if (mediaFileCount > 0) {
        NSString *mediaSizeStr = [self formatFileSize:mediaTotalSize];
        [detailParts addObject:[NSString stringWithFormat:LocalizedString(@"MediaUnit"), (long)mediaFileCount, mediaSizeStr]];
    }

    cell.detailTextLabel.text = [detailParts componentsJoinedByString:@" • "];
    cell.detailTextLabel.numberOfLines = 0;

    // 图标
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"doc.fill"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    WFCBackupItem *item = self.backupItems[indexPath.row];

    // 显示恢复选项
    WFCRestoreOptionsViewController *vc = [[WFCRestoreOptionsViewController alloc] init];
    vc.backupFilePath = item.filePath;
    vc.backupInfo = item.backupInfo;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCBackupItem *item = self.backupItems[indexPath.row];

        // 删除备份（可能是文件或文件夹）
        NSError *error;
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:item.filePath isDirectory:&isDirectory];

        if (isDirectory) {
            // 新格式 v2.0：删除整个目录
            [[NSFileManager defaultManager] removeItemAtPath:item.filePath error:&error];
        } else {
            // 旧格式 v1.0：删除 JSON 文件
            [[NSFileManager defaultManager] removeItemAtPath:item.filePath error:&error];

            // 如果有媒体文件夹，也删除
            NSString *mediaDir = [item.filePath stringByDeletingPathExtension];
            if ([[NSFileManager defaultManager] fileExistsAtPath:mediaDir isDirectory:&isDirectory] && isDirectory) {
                [[NSFileManager defaultManager] removeItemAtPath:mediaDir error:nil];
            }
        }

        // 从列表中移除
        [self.backupItems removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Helper Methods

- (NSString *)formatFileSize:(long long)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%lld B", size];
    } else if (size < 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f KB", size / 1024.0];
    } else if (size < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%.1f MB", size / (1024.0 * 1024)];
    } else {
        return [NSString stringWithFormat:@"%.1f GB", size / (1024.0 * 1024 * 1024)];
    }
}

@end
