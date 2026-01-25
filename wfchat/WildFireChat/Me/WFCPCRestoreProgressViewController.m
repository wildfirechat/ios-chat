//
//  WFCPCRestoreProgressViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCPCRestoreProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCMessageBackupManager.h>

@interface WFCPCRestoreProgressViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSMutableDictionary *metadata;
@property (nonatomic, strong) NSString *tempDirectory;
@property (nonatomic, assign) NSInteger totalFiles;
@property (nonatomic, assign) NSInteger downloadedFiles;
@end

@implementation WFCPCRestoreProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"RestoreFromPC_Title");
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self setupUI];
    [self beginRestoreProcess];
}

- (void)setupUI {
    // 创建进度视图
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.progressView setProgress:0.0 animated:NO];
    [self.view addSubview:self.progressView];

    // 创建状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = LocalizedString(@"Preparing");
    self.statusLabel.font = [UIFont boldSystemFontOfSize:18];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // 创建详细标签
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.text = LocalizedString(@"DownloadingBackupInfo");
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textColor = [UIColor secondaryLabelColor];
    self.detailLabel.textAlignment = NSTextAlignmentCenter;
    self.detailLabel.numberOfLines = 0;
    self.detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.detailLabel];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.progressView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.progressView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-80],
        [self.progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.progressView.bottomAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.detailLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:15],
        [self.detailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.detailLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];

    // 创建临时目录
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"restore_pc"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    self.tempDirectory = tempDir;
}

- (void)beginRestoreProcess {
    // 先下载metadata.json
    [self downloadMetadata];
}

- (void)downloadMetadata {
    self.statusLabel.text = LocalizedString(@"DownloadingBackupInfo");
    self.detailLabel.text = LocalizedString(@"ConnectingToPC");

    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/restore_metadata?path=%@",
                           self.serverIP,
                           (long)self.serverPort,
                           [self.backupPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];

    __weak typeof(self) weakSelf = self;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [strongSelf showError:[NSString stringWithFormat:LocalizedString(@"DownloadBackupInfoFailed"), error.localizedDescription]];
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200 && data) {
                [strongSelf parseMetadata:data];
            } else {
                [strongSelf showError:[NSString stringWithFormat:LocalizedString(@"DownloadFailedStatusCode"), (long)httpResponse.statusCode]];
            }
        });
    }];

    [task resume];
}

- (void)parseMetadata:(NSData *)data {
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error || ![json isKindOfClass:[NSDictionary class]]) {
        [self showError:LocalizedString(@"ParseBackupInfoFailed")];
        return;
    }

    self.metadata = [json mutableCopy];

    // 显示备份信息
    NSDictionary *statistics = json[@"statistics"];
    NSInteger totalConversations = [statistics[@"totalConversations"] integerValue];
    NSInteger totalMessages = [statistics[@"totalMessages"] integerValue];
    NSInteger totalMediaFiles = [statistics[@"mediaFileCount"] integerValue];

    self.statusLabel.text = LocalizedString(@"ReadyToRestore");
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"BackupInfoDetail"),
                             (long)totalConversations,
                             (long)totalMessages,
                             (long)totalMediaFiles];

    // 延迟后开始下载文件
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showConfirmDialog];
    });
}

- (void)showConfirmDialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:LocalizedString(@"ConfirmRestore")
                                                                   message:self.detailLabel.text
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:LocalizedString(@"StartRestore_Action")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *action) {
        [self downloadAllFiles];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LocalizedString(@"Cancel")
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];

    [alert addAction:confirmAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)downloadAllFiles {
    self.statusLabel.text = LocalizedString(@"SyncingFiles");
    [self.progressView setProgress:0.0 animated:YES];
    self.downloadedFiles = 0;
    self.totalFiles = 0;

    // 先统计需要下载的文件数
    NSMutableArray *filesToDownload = [NSMutableArray array];

    // 首先添加metadata.json（放在临时目录根目录）
    [filesToDownload addObject:@{@"type": @"metadata", @"path": @"metadata.json"}];

    // 添加会话文件
    NSArray *conversations = self.metadata[@"conversations"];
    for (NSDictionary *conv in conversations) {
        NSString *directory = conv[@"directory"]; // 会话目录名
        // 会话的messages.json文件
        [filesToDownload addObject:@{@"type": @"conversation", @"path": [NSString stringWithFormat:@"conversations/%@/messages.json", directory]}];

        // 添加媒体文件
        NSArray *mediaFiles = conv[@"mediaFiles"];
        for (NSString *mediaPath in mediaFiles) {
            // 媒体文件路径：conversations/{directory}/media/{mediaPath}
            [filesToDownload addObject:@{@"type": @"media", @"path": [NSString stringWithFormat:@"conversations/%@/media/%@", directory, mediaPath]}];
        }
    }

    self.totalFiles = filesToDownload.count;

    // 开始下载所有文件
    [self downloadFilesSequentially:filesToDownload currentIndex:0];
}

- (void)downloadFilesSequentially:(NSArray *)files currentIndex:(NSInteger)index {
    if (index >= files.count) {
        // 所有文件下载完成
        [self startRestore];
        return;
    }

    NSDictionary *fileInfo = files[index];
    NSString *type = fileInfo[@"type"];
    NSString *relativePath = fileInfo[@"path"];

    // 更新进度（下载阶段占0-50%）
    dispatch_async(dispatch_get_main_queue(), ^{
        float progress = (float)self.downloadedFiles / (float)self.totalFiles;
        float displayProgress = progress * 0.5; // 映射到0-50%
        [self.progressView setProgress:displayProgress animated:YES];
        self.statusLabel.text = [NSString stringWithFormat:LocalizedString(@"SyncingFileProgress"),
                                  (long)(self.downloadedFiles + 1),
                                  (long)self.totalFiles];
        self.detailLabel.text = [NSString stringWithFormat:@"%.0f%% - %@", displayProgress * 100, relativePath];
    });

    // 构建URL
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/restore_file?path=%@",
                           self.serverIP,
                           (long)self.serverPort,
                           [[self.backupPath stringByAppendingPathComponent:relativePath] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:120];

    __weak typeof(self) weakSelf = self;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (error || !data) {
            NSLog(@"下载文件失败 %@: %@", relativePath, error.localizedDescription);
            // 继续下载下一个文件
            strongSelf.downloadedFiles++;
            [strongSelf downloadFilesSequentially:files currentIndex:index + 1];
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            // 保存文件
            NSString *savePath = [strongSelf.tempDirectory stringByAppendingPathComponent:relativePath];
            NSString *saveDir = [savePath stringByDeletingLastPathComponent];

            [[NSFileManager defaultManager] createDirectoryAtPath:saveDir
                                              withIntermediateDirectories:YES
                                                               attributes:nil
                                                                    error:nil];

            if ([data writeToFile:savePath atomically:YES]) {
                NSLog(@"已下载: %@", relativePath);
            }
        }

        // 继续下载下一个文件
        strongSelf.downloadedFiles++;
        [strongSelf downloadFilesSequentially:files currentIndex:index + 1];
    }];

    [task resume];
}

- (void)startRestore {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = LocalizedString(@"ImportingData");
        self.detailLabel.text = LocalizedString(@"PleaseWait");
        [self.progressView setProgress:0.5 animated:YES];
    });

    // 使用备份管理器恢复
    __weak typeof(self) weakSelf = self;
    [[WFCCMessageBackupManager sharedManager] restoreFromBackup:self.tempDirectory
                                                      password:[WFCCNetworkService sharedInstance].userId
                                            overwriteExisting:self.overwriteExisting
                                                     progress:^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleProgress:progress];
        });
    }
                                                      success:^(int restoredMessageCount, int restoredMediaCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleRestoreSuccess:restoredMessageCount mediaCount:restoredMediaCount];
        });
    }
                                                        error:^(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleRestoreError:errorCode];
        });
    }];
}

- (void)handleProgress:(NSProgress *)progress {
    CGFloat completed = progress.fractionCompleted;
    CGFloat displayProgress = 0.5 + (completed * 0.5); // 映射到50-100%
    [self.progressView setProgress:displayProgress animated:YES];
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"ImportingProgress"), displayProgress * 100];
}

- (void)handleRestoreSuccess:(int)restoredMessageCount mediaCount:(int)restoredMediaCount {
    [self.progressView setProgress:1.0 animated:YES];
    self.statusLabel.text = LocalizedString(@"RestoreCompleted");
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"TotalRestored"), restoredMessageCount];

    // 清理临时文件
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSFileManager defaultManager] removeItemAtPath:self.tempDirectory error:nil];
        // 返回到备份与恢复主界面
        [self popToBackupAndRestoreViewController];
    });
}

- (void)handleRestoreError:(int)errorCode {
    [self showError:[NSString stringWithFormat:LocalizedString(@"RestoreFailedWithError"), errorCode]];
}

- (void)showError:(NSString *)message {
    self.statusLabel.text = LocalizedString(@"RestoreFailed");
    self.detailLabel.text = message;

    // 清理临时文件
    [[NSFileManager defaultManager] removeItemAtPath:self.tempDirectory error:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self popToBackupAndRestoreViewController];
    });
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
