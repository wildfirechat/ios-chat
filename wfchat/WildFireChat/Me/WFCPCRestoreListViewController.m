//
//  WFCPCRestoreListViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-12.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCPCRestoreListViewController.h"
#import "WFCRestoreOptionsViewController.h"
#import "WFCPCRestoreProgressViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCRestoreRequestNotificationContent.h>
#import <WFChatClient/WFCCRestoreResponseNotificationContent.h>

@interface WFCPCRestoreListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSArray<NSDictionary *> *backupList;
@property (nonatomic, strong) NSString *serverIP;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@end

@implementation WFCPCRestoreListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"PCBackupTitle");
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.isLoading = YES;
    self.backupList = [NSArray array];

    [self setupUI];

    // 发送恢复请求
    [self sendRestoreRequest];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // 返回时刷新表格布局，避免界面错乱
    if (!self.tableView.hidden && self.backupList.count > 0) {
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
    }
}

- (void)setupUI {
    // 创建状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = LocalizedString(@"WaitingForPCConfirm");
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];

    // 创建活动指示器
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    if (@available(iOS 13.0, *)) {
        self.activityIndicator.color = [UIColor systemBlueColor];
    }
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];

    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.hidden = YES;

    // 启用自动计算行高
    if (@available(iOS 8.0, *)) {
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 80;
    }

    [self.view addSubview:self.tableView];

    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-50],

        [self.statusLabel.topAnchor constraintEqualToAnchor:self.activityIndicator.bottomAnchor constant:20],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];

    // 注册消息监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onReceiveRestoreResponse:)
                                                 name:kReceiveMessages
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timeoutTimer invalidate];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Restore Request

- (void)sendRestoreRequest {
    // 启动超时计时器（30秒）
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                         target:self
                                                       selector:@selector(onTimeout)
                                                       userInfo:nil
                                                        repeats:NO];

    // 发送恢复请求消息
    NSString *currentUserId = [[WFCCNetworkService sharedInstance] userId];

    // 创建恢复请求通知消息
    WFCCRestoreRequestNotificationContent *content = [[WFCCRestoreRequestNotificationContent alloc] initWithTimestamp:[[NSDate date] timeIntervalSince1970] * 1000];

    // 创建一个给自己（PC端）的通知消息
    WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:currentUserId line:0];

    __weak typeof(self) weakSelf = self;
    [[WFCCIMService sharedWFCIMService] send:conversation
                                     content:content
                                     success:^(long long messageUid, long long timestamp) {
        NSLog(@"恢复请求已发送");
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showError:[NSString stringWithFormat:LocalizedString(@"SendRestoreRequestFailed"), error_code]];
        });
    }];
}

- (void)onReceiveRestoreResponse:(NSNotification *)notification {
    NSArray *messages = notification.object;
    for (WFCCMessage *msg in messages) {
        if ([msg.content isKindOfClass:[WFCCRestoreResponseNotificationContent class]]) {
            WFCCRestoreResponseNotificationContent *response = (WFCCRestoreResponseNotificationContent *)msg.content;

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.timeoutTimer invalidate];
                self.serverIP = response.serverIP;
                self.serverPort = response.serverPort;

                if (response.approved) {
                    // 同意恢复，获取备份列表
                    [self fetchBackupList];
                } else {
                    // 拒绝恢复
                    [self showError:LocalizedString(@"PCRejectedRestoreRequest")];
                }
            });
            break;
        }
    }
}

- (void)fetchBackupList {
    self.statusLabel.text = LocalizedString(@"FetchingBackupList");

    // 创建HTTP请求
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%ld/restore_list", self.serverIP, (long)self.serverPort];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self showError:[NSString stringWithFormat:LocalizedString(@"FetchBackupListFailed"), error.localizedDescription]];
                return;
            }

            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200 && data) {
                [self parseBackupList:data];
            } else {
                [self showError:[NSString stringWithFormat:LocalizedString(@"FetchBackupListFailedWithCode"), (long)httpResponse.statusCode]];
            }
        });
    }];

    [task resume];
}

- (void)parseBackupList:(NSData *)data {
    NSError *error;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error || ![json isKindOfClass:[NSArray class]]) {
        [self showError:LocalizedString(@"ParseBackupInfoFailed")];
        return;
    }

    self.backupList = json;

    if (self.backupList.count == 0) {
        [self showError:LocalizedString(@"NoBackupAvailableOnPC")];
        return;
    }

    // 显示备份列表
    [self.activityIndicator stopAnimating];
    self.statusLabel.hidden = YES;
    self.tableView.hidden = NO;
    [self.tableView reloadData];
}

- (void)showError:(NSString *)message {
    self.isLoading = NO;
    [self.activityIndicator stopAnimating];
    self.statusLabel.text = message;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

- (void)onTimeout {
    [self showError:LocalizedString(@"PCNotRespondInTime")];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.backupList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"BackupCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // 设置文本布局以支持自动高度
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;

        // 设置字体以确保布局计算正确
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:14];
    }

    NSDictionary *backup = self.backupList[indexPath.row];
    NSString *backupName = backup[@"name"] ?: LocalizedString(@"UnknownBackup");
    NSString *backupTime = backup[@"time"] ?: @"";
    NSString *deviceName = backup[@"deviceName"] ?: @"";
    NSInteger fileCount = [backup[@"fileCount"] integerValue];
    NSInteger conversationCount = [backup[@"conversationCount"] integerValue];
    NSInteger messageCount = [backup[@"messageCount"] integerValue];
    NSInteger mediaFileCount = [backup[@"mediaFileCount"] integerValue];

    cell.textLabel.text = backupName;

    // 构建详细信息字符串
    NSMutableArray *details = [NSMutableArray array];

    // 添加设备名称
    if (deviceName.length > 0) {
        [details addObject:[NSString stringWithFormat:LocalizedString(@"DeviceLabel"), deviceName]];
    }

    if (conversationCount > 0) {
        [details addObject:[NSString stringWithFormat:LocalizedString(@"ConversationsUnit"), (long)conversationCount]];
    }
    if (messageCount > 0) {
        [details addObject:[NSString stringWithFormat:LocalizedString(@"MessagesUnit"), (long)messageCount]];
    }
    if (mediaFileCount > 0) {
        [details addObject:[NSString stringWithFormat:LocalizedString(@"MediaFilesUnit"), (long)mediaFileCount]];
    }
    if (details.count == 0 && fileCount > 0) {
        [details addObject:[NSString stringWithFormat:LocalizedString(@"FileUnit"), (long)fileCount]];
    }

    NSString *detailText = [NSString stringWithFormat:@"%@ • %@", backupTime, [details componentsJoinedByString:@" • "]];
    cell.detailTextLabel.text = detailText;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *backup = self.backupList[indexPath.row];
    NSString *backupPath = backup[@"path"];

    // 跳转到PC恢复进度界面
    WFCPCRestoreProgressViewController *vc = [[WFCPCRestoreProgressViewController alloc] init];
    vc.backupPath = backupPath;
    vc.serverIP = self.serverIP;
    vc.serverPort = self.serverPort;
    vc.overwriteExisting = NO; // 默认不覆盖

    [self.navigationController pushViewController:vc animated:YES];
}

@end
