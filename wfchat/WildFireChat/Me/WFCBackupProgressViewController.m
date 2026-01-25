//
//  WFCBackupProgressViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCBackupProgressViewController ()
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIProgressView *progressBar;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, assign) BOOL isCancelled;
@end

@implementation WFCBackupProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.isRestoreMode ? LocalizedString(@"RestoringBackup") : LocalizedString(@"CreatingBackup");
    self.isCancelled = NO;

    [self setupUI];

    // 开始操作
    if (self.isRestoreMode) {
        [self startRestore];
    } else {
        [self startBackup];
    }
}

- (void)setupUI {
    // 主容器
    self.progressView = [[UIView alloc] init];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.progressView];

    // 进度条
    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.progressTintColor = [UIColor systemBlueColor];
    [self.progressView addSubview:self.progressBar];

    // 进度标签
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressLabel.font = [UIFont boldSystemFontOfSize:24];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    self.progressLabel.text = @"0%";
    [self.progressView addSubview:self.progressLabel];

    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.text = @"正在准备...";
    [self.progressView addSubview:self.statusLabel];

    // 详情标签
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textAlignment = NSTextAlignmentCenter;
    self.detailLabel.textColor = [UIColor tertiaryLabelColor];
    self.detailLabel.numberOfLines = 0;
    [self.progressView addSubview:self.detailLabel];

    // 取消按钮
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton setTitle:LocalizedString(@"Cancel") forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.progressView addSubview:self.cancelButton];

    // 布局
    [NSLayoutConstraint activateConstraints:@[
        [self.progressView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.progressView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],

        [self.progressLabel.topAnchor constraintEqualToAnchor:self.progressView.topAnchor],
        [self.progressLabel.leadingAnchor constraintEqualToAnchor:self.progressView.leadingAnchor],
        [self.progressLabel.trailingAnchor constraintEqualToAnchor:self.progressView.trailingAnchor],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.progressLabel.bottomAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.progressView.leadingAnchor],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.progressView.trailingAnchor],

        [self.detailLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:10],
        [self.detailLabel.leadingAnchor constraintEqualToAnchor:self.progressView.leadingAnchor],
        [self.detailLabel.trailingAnchor constraintEqualToAnchor:self.progressView.trailingAnchor],

        [self.progressBar.topAnchor constraintEqualToAnchor:self.detailLabel.bottomAnchor constant:30],
        [self.progressBar.leadingAnchor constraintEqualToAnchor:self.progressView.leadingAnchor],
        [self.progressBar.trailingAnchor constraintEqualToAnchor:self.progressView.trailingAnchor],

        [self.cancelButton.topAnchor constraintEqualToAnchor:self.progressBar.bottomAnchor constant:30],
        [self.cancelButton.centerXAnchor constraintEqualToAnchor:self.progressView.centerXAnchor],
        [self.cancelButton.bottomAnchor constraintEqualToAnchor:self.progressView.bottomAnchor],
    ]];
}

#pragma mark - Backup

- (void)startBackup {
    // 生成备份文件夹路径（新格式 v2.0）
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *backupDirectory = [documentsDirectory stringByAppendingPathComponent:@"Backups"];
    [[NSFileManager defaultManager] createDirectoryAtPath:backupDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *folderName = [NSString stringWithFormat:@"backup_%@", [formatter stringFromDate:[NSDate date]]];
    NSString *backupFolderPath = [backupDirectory stringByAppendingPathComponent:folderName];

    // 显示会话数量
    NSInteger conversationCount = self.conversations.count;
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"TotalConversations"),
                              (long)conversationCount];

    // 使用新的目录备份API
    [[WFCCMessageBackupManager sharedManager] createDirectoryBasedBackup:backupFolderPath
                                                      conversations:self.conversations
                                                          password:self.backupPassword
                                                      passwordHint:nil
                                                           progress:^(NSProgress *progress) {
        [self handleProgress:progress];
    } success:^(NSString *backupPath, int msgCount, int mediaCount, long long mediaSize) {
        [self handleBackupSuccess:backupPath msgCount:msgCount mediaCount:mediaCount mediaSize:mediaSize];
    } error:^(int errorCode) {
        [self handleBackupError:errorCode];
    }];
}

- (void)handleBackupSuccess:(NSString *)backupPath msgCount:(int)msgCount mediaCount:(int)mediaCount mediaSize:(long long)mediaSize {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBar.progress = 1.0;
        self.progressLabel.text = @"100%";
        self.statusLabel.text = LocalizedString(@"BackupCompleted");
        self.cancelButton.hidden = YES;

        // 构建详细信息
        NSMutableString *detailMessage = [NSMutableString string];
        [detailMessage appendFormat:LocalizedString(@"BackupSuccessDetail"), msgCount];

        if (mediaCount > 0) {
            NSString *sizeStr = [self formatFileSize:mediaSize];
            [detailMessage appendFormat:LocalizedString(@"MediaFilesDetail"), mediaCount, sizeStr];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"BackupCompleted")
                                                                       message:detailMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalizedString(@"Ok")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
            [self popToBackupAndRestoreViewController];
        }];

        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)handleBackupError:(int)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = LocalizedString(@"BackupFailed");
        self.progressBar.progressTintColor = [UIColor systemRedColor];
        self.cancelButton.hidden = YES;

        NSString *errorMessage = [self errorMessageForCode:errorCode];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"BackupFailed")
                                                                       message:errorMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalizedString(@"Ok")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];

        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Restore

- (void)startRestore {
    // 显示预估信息
    NSInteger totalMessages = [self.backupInfo[@"totalMessages"] integerValue];
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"TotalMessages"), (long)totalMessages];

    // 开始恢复（如果是加密备份，isRestoreMode时self.backupPassword会有值）
    NSString *password = self.isRestoreMode ? self.backupPassword : nil;
    [[WFCCMessageBackupManager sharedManager] restoreFromBackup:self.backupFilePath
                                                      password:password
                                            overwriteExisting:self.overwriteExisting
                                                     progress:^(NSProgress *progress) {
        [self handleProgress:progress];
    }
                                                      success:^(int restoredMessageCount, int restoredMediaCount) {
        [self handleRestoreSuccess:restoredMessageCount mediaCount:restoredMediaCount];
    }
                                                        error:^(int errorCode) {
        [self handleRestoreError:errorCode];
    }];
}

- (void)handleRestoreSuccess:(int)restoredMessageCount mediaCount:(int)restoredMediaCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBar.progress = 1.0;
        self.progressLabel.text = @"100%";
        self.statusLabel.text = LocalizedString(@"RestoreCompleted");
        self.cancelButton.hidden = YES;

        // 构建详细信息
        NSMutableString *message = [NSMutableString string];
        [message appendFormat:LocalizedString(@"RestoreSuccessDetail"), restoredMessageCount];

        // 只显示有媒体文件的数量
        if (restoredMediaCount > 0) {
            [message appendFormat:LocalizedString(@"MediaFilesOnly"), restoredMediaCount];
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"RestoreCompleted")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalizedString(@"Ok")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
            [self popToBackupAndRestoreViewController];
        }];

        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)handleRestoreError:(int)errorCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = LocalizedString(@"RestoreFailed");
        self.progressBar.progressTintColor = [UIColor systemRedColor];
        self.cancelButton.hidden = YES;

        NSString *errorMessage = [self errorMessageForCode:errorCode];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"RestoreFailed")
                                                                       message:errorMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:LocalizedString(@"Ok")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
            [self.navigationController popViewControllerAnimated:YES];
        }];

        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Progress Handler

- (void)handleProgress:(NSProgress *)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isCancelled) {
            return;
        }

        self.progress = progress;
        CGFloat progressValue = progress.fractionCompleted;
        self.progressBar.progress = progressValue;
        self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%", progressValue * 100];

        if (self.isRestoreMode) {
            self.statusLabel.text = LocalizedString(@"RestoringMessage");
        } else {
            self.statusLabel.text = LocalizedString(@"BackingUpMessage");
        }
    });
}

#pragma mark - Actions

- (void)cancelButtonClicked:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"ConfirmCancel")
                                                                   message:LocalizedString(@"ConfirmCancelMessage")
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LocalizedString(@"CancelOperation")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
        self.isCancelled = YES;
        [[WFCCMessageBackupManager sharedManager] cancelCurrentOperation];
        self.statusLabel.text = LocalizedString(@"Cancelled");
        self.cancelButton.hidden = YES;
        self.progressBar.progressTintColor = [UIColor systemOrangeColor];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalizedString(@"ContinueOperation")
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];

    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
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

- (NSString *)errorMessageForCode:(int)errorCode {
    switch (errorCode) {
        case BackupError_FileNotFound:
            return LocalizedString(@"BackupError_FileNotFound");
        case BackupError_InvalidFormat:
            return LocalizedString(@"BackupError_InvalidFormat");
        case BackupError_IOError:
            return LocalizedString(@"BackupError_IOError");
        case BackupError_OutOfSpace:
            return LocalizedString(@"BackupError_OutOfSpace");
        case BackupError_Cancelled:
            return LocalizedString(@"BackupError_Cancelled");
        case BackupError_EncryptionFailed:
            return LocalizedString(@"BackupError_EncryptionFailed");
        case BackupError_DecryptionFailed:
            return LocalizedString(@"BackupError_DecryptionFailed");
        case BackupError_WrongPassword:
            return LocalizedString(@"BackupError_WrongPassword");
        case BackupError_RestoreFailed:
            return LocalizedString(@"BackupError_RestoreFailed");
        default:
            return [NSString stringWithFormat:LocalizedString(@"BackupError_Unknown"), errorCode];
    }
}

- (void)popToBackupAndRestoreViewController {
    // 遍历导航栈，找到WFCBackupAndRestoreViewController并返回到它
    NSArray *viewControllers = self.navigationController.viewControllers;
    for (UIViewController *vc in viewControllers) {
        if ([vc isKindOfClass:NSClassFromString(@"WFCBackupAndRestoreViewController")]) {
            [self.navigationController popToViewController:vc animated:YES];
            return;
        }
    }
    // 如果找不到，返回到根视图控制器
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
