//
//  WFCBackupRequestProgressViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupRequestProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCBackupRequestNotificationContent.h>
#import <WFChatClient/WFCCBackupResponseNotificationContent.h>
#import <CommonCrypto/CommonDigest.h>

@interface WFCBackupRequestProgressViewController ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, assign) BOOL isWaitingForResponse;
@property (nonatomic, copy) NSString *serverIP;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, assign) NSInteger uploadedFileCount; // 记录上传的文件数量
@end

@implementation WFCBackupRequestProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"BackupRequestTitle");
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    // 创建进度指示器
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    if (@available(iOS 13.0, *)) {
        self.activityIndicator.color = [UIColor systemBlueColor];
    }
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicator];

    // 创建状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = LocalizedString(@"WaitingForPCResponse");
    self.statusLabel.font = [UIFont boldSystemFontOfSize:18];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // 创建详细标签
    self.detailLabel = [[UILabel alloc] init];
    self.detailLabel.text = LocalizedString(@"PleaseConfirmBackupOnPC");
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textColor = [UIColor secondaryLabelColor];
    self.detailLabel.textAlignment = NSTextAlignmentCenter;
    self.detailLabel.numberOfLines = 0;
    self.detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.detailLabel];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-50],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.activityIndicator.bottomAnchor constant:30],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],

        [self.detailLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:15],
        [self.detailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.detailLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];

    // 注册消息监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveBackupResponse:)
                                                 name:kReceiveMessages
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timeoutTimer invalidate];
}

- (void)startBackupRequest {
    self.isWaitingForResponse = YES;
    [self.activityIndicator startAnimating];

    // 启动超时计时器（30秒）
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                         target:self
                                                       selector:@selector(onTimeout)
                                                       userInfo:nil
                                                        repeats:NO];

    // 发送备份请求消息
    NSString *currentUserId = [[WFCCNetworkService sharedInstance] userId];

    // 准备会话列表数据
    NSMutableArray *convsArray = [NSMutableArray array];
    for (WFCCConversationInfo *convInfo in self.conversations) {
        WFCCConversation *conversation = convInfo.conversation;
        int messageCount = [[WFCCIMService sharedWFCIMService] getMessageCount:conversation];

        [convsArray addObject:@{
            @"conversation": @{
                @"type": @(conversation.type),
                @"target": conversation.target,
                @"line": @(conversation.line)
            },
            @"messageCount": @(messageCount)
        }];
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:convsArray options:0 error:&error];
    NSString *conversationsJson = jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"";

    // 创建备份请求通知消息
    WFCCBackupRequestNotificationContent *content = [[WFCCBackupRequestNotificationContent alloc] initWithConversations:conversationsJson
                                                                                                        includeMedia:self.includeMedia
                                                                                                           timestamp:[[NSDate date] timeIntervalSince1970] * 1000];

    // 创建一个给自己（PC端）的通知消息
    WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:currentUserId line:0];

    __weak typeof(self) weakSelf = self;
    [[WFCCIMService sharedWFCIMService] send:conversation
                                     content:content
                                     success:^(long long messageUid, long long timestamp) {
        NSLog(@"备份请求已发送");
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showErrorMessage:[NSString stringWithFormat:LocalizedString(@"SendBackupRequestFailed"), error_code]];
        });
    }];
}

- (void)onReceiveBackupResponse:(NSNotification *)notification {
    if (!self.isWaitingForResponse) {
        return;
    }

    NSArray *messages = notification.object;
    for (WFCCMessage *msg in messages) {
        if ([msg.content isKindOfClass:[WFCCBackupResponseNotificationContent class]]) {
            WFCCBackupResponseNotificationContent *response = (WFCCBackupResponseNotificationContent *)msg.content;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.timeoutTimer invalidate];
                self.isWaitingForResponse = NO;

                if (response.approved) {
                    // 同意备份
                    [self onBackupApproved:response];
                } else {
                    // 拒绝备份
                    [self onBackupRejected];
                }
            });
            break;
        }
    }
}

- (void)onBackupApproved:(WFCCBackupResponseNotificationContent *)response {
    self.serverIP = response.serverIP;
    self.serverPort = response.serverPort;

    self.statusLabel.text = LocalizedString(@"PCApprovedBackup");
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"CreatingBackupData"), response.serverIP, (long)response.serverPort];

    // 开始创建备份并上传
    [self createAndUploadBackup];
}

- (void)createAndUploadBackup {
    // 创建临时备份目录
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"backup_upload"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    // 使用备份管理器创建备份
    __weak typeof(self) weakSelf = self;
    [[WFCCMessageBackupManager sharedManager] createDirectoryBasedBackup:tempDirectory
                                                      conversations:self.conversations
                                                          password:[[WFCCNetworkService sharedInstance] userId]
                                                      passwordHint:nil
                                                           progress:^(NSProgress *progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateProgress:progress];
        });
    } success:^(NSString *backupPath, int msgCount, int mediaCount, long long mediaSize) {
        [weakSelf uploadBackupToPC:backupPath];
    } error:^(int errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showErrorMessage:[NSString stringWithFormat:LocalizedString(@"CreateBackupFailed"), errorCode]];
        });
    }];
}

- (void)updateProgress:(NSProgress *)progress {
    CGFloat completed = progress.fractionCompleted;
    NSInteger percent = (NSInteger)(completed * 100);

    self.statusLabel.text = [NSString stringWithFormat:LocalizedString(@"BackingUpProgress"), (long)percent];
    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"CompletedCount"), progress.completedUnitCount, progress.totalUnitCount];
}

- (void)uploadBackupToPC:(NSString *)backupPath {
    self.statusLabel.text = LocalizedString(@"UploadingBackupToPC");
    self.detailLabel.text = LocalizedString(@"PreparingFileList");

    // 获取所有文件
    NSArray *files = [self getAllFilesAtPath:backupPath];

    if (files.count == 0) {
        [self showErrorMessage:LocalizedString(@"BackupFileNotFound")];
        return;
    }

    // 记录文件总数
    self.uploadedFileCount = files.count;

    self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"TotalFilesWaitingUpload"), (long)files.count];

    // 逐个发送文件
    [self uploadFilesSequentially:files currentIndex:0 basePath:backupPath];
}

- (void)uploadFilesSequentially:(NSArray *)files currentIndex:(NSInteger)index basePath:(NSString *)basePath {
    if (index >= files.count) {
        // 所有文件上传完成
        [self onUploadSuccess];
        return;
    }

    NSString *filePath = files[index];

    // 更新进度
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progress = (CGFloat)index / files.count;
        NSInteger percent = (NSInteger)(progress * 100);
        self.statusLabel.text = [NSString stringWithFormat:LocalizedString(@"UploadingProgress"), (long)percent];
        self.detailLabel.text = [NSString stringWithFormat:LocalizedString(@"FileProgress"), (long)(index + 1), (long)files.count];
    });

    // 读取文件数据
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (!fileData) {
        // 跳过这个文件，继续下一个
        [self uploadFilesSequentially:files currentIndex:index + 1 basePath:basePath];
        return;
    }

    // 获取相对路径
    NSString *relativePath = [filePath substringFromIndex:basePath.length];
    if ([relativePath hasPrefix:@"/"]) {
        relativePath = [relativePath substringFromIndex:1];
    }

    // 发送文件
    [self uploadFile:fileData relativePath:relativePath completion:^(BOOL success) {
        if (success) {
            // 成功，继续下一个
            [self uploadFilesSequentially:files currentIndex:index + 1 basePath:basePath];
        } else {
            // 失败，停止上传
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showErrorMessage:LocalizedString(@"UploadFileFailed")];
            });
        }
    }];
}

- (void)uploadFile:(NSData *)fileData relativePath:(NSString *)relativePath completion:(void(^)(BOOL success))completion {
    // 创建HTTP请求
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/backup", self.serverIP, (long)self.serverPort];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 60; // 每个文件60秒超时

    // 准备请求体：相对路径长度 + 相对路径 + 文件数据长度 + 文件数据
    NSMutableData *bodyData = [NSMutableData data];

    // 写入相对路径长度（4字节，小端序）
    int32_t pathLength = (int32_t)relativePath.length;
    int32_t pathLengthSwapped = CFSwapInt32HostToLittle(pathLength);
    [bodyData appendBytes:&pathLengthSwapped length:sizeof(pathLengthSwapped)];

    // 写入相对路径（UTF8编码）
    NSData *pathData = [relativePath dataUsingEncoding:NSUTF8StringEncoding];
    [bodyData appendData:pathData];

    // 写入文件数据长度（8字节，小端序）
    int64_t dataLength = (int64_t)fileData.length;
    int64_t dataLengthSwapped = CFSwapInt64HostToLittle(dataLength);
    [bodyData appendBytes:&dataLengthSwapped length:sizeof(dataLengthSwapped)];

    // 写入文件数据
    [bodyData appendData:fileData];

    // 设置请求头
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%llu", (unsigned long long)bodyData.length] forHTTPHeaderField:@"Content-Length"];

    // 发送请求
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                           fromData:bodyData
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"上传文件失败 %@: %@", relativePath, error.localizedDescription);
                completion(NO);
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                NSLog(@"上传文件成功: %@", relativePath);
                completion(YES);
            } else {
                NSLog(@"上传文件失败，状态码: %ld", (long)httpResponse.statusCode);
                completion(NO);
            }
        });
    }];

    [uploadTask resume];
}

- (NSArray *)getAllFilesAtPath:(NSString *)directoryPath {
    NSMutableArray *files = [NSMutableArray array];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:directoryPath];
    NSString *file;

    while ((file = [enumerator nextObject])) {
        NSString *filePath = [directoryPath stringByAppendingPathComponent:file];
        BOOL isDirectory;
        [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];

        if (!isDirectory) {
            [files addObject:filePath];
        }
    }

    return [files copy];
}

- (void)onUploadSuccess {
    self.statusLabel.text = LocalizedString(@"BackupCompleted");
    self.detailLabel.text = LocalizedString(@"NotifyingPC");

    // 发送完成请求给PC端
    [self sendCompletionRequest];

    // 清理临时文件
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"backup_upload"];
    [[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:nil];

    // 延迟返回
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        // 返回到备份与恢复主界面
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

- (void)sendCompletionRequest {
    // 准备完成请求数据：文件数量
    NSInteger fileCount = [self getAllFilesAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"backup_upload"]].count;
    // 注意：此时临时文件可能已被清理，所以我们需要在上传前记录文件数量

    NSMutableData *bodyData = [NSMutableData data];

    // 写入文件数量（4字节，小端序）
    int32_t fileCountSwapped = CFSwapInt32HostToLittle((int32_t)self.uploadedFileCount);
    [bodyData appendBytes:&fileCountSwapped length:sizeof(fileCountSwapped)];

    // 创建HTTP请求
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/backup_complete", self.serverIP, (long)self.serverPort];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    request.HTTPBody = bodyData;

    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)bodyData.length] forHTTPHeaderField:@"Content-Length"];

    // 发送请求
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"发送完成请求失败: %@", error.localizedDescription);
        } else {
            NSLog(@"已通知PC端备份完成");
        }
    }];
    [task resume];
}

- (void)onBackupRejected {
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = LocalizedString(@"BackupRequestRejected");
    self.detailLabel.text = LocalizedString(@"PCRejectedBackupRequest");

    // 延迟一下返回
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)onTimeout {
    self.isWaitingForResponse = NO;
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = LocalizedString(@"RequestTimeout");
    self.detailLabel.text = LocalizedString(@"PCNotRespondInTime");

    // 延迟一下返回
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self popToBackupAndRestoreViewController];
    });
}

- (void)showErrorMessage:(NSString *)message {
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = LocalizedString(@"OperationFailed");
    self.detailLabel.text = message;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

@end
