//
//  WFCBackupOptionsViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCBackupOptionsViewController.h"
#import "WFCBackupTargetViewController.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCBackupOptionsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL includeMedia;
@property (nonatomic, strong) UISwitch *mediaSwitch;
@end

@implementation WFCBackupOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LocalizedString(@"BackupOptions");
    self.includeMedia = NO;

    // 创建开始备份按钮
    UIBarButtonItem *startButton = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"NextStep")
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(startBackup)];
    self.navigationItem.rightBarButtonItem = startButton;

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

- (void)startBackup {
    // 跳转到备份目标选择界面
    WFCBackupTargetViewController *vc = [[WFCBackupTargetViewController alloc] init];
    vc.conversations = self.conversations;
    vc.includeMedia = self.includeMedia;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)mediaSwitchChanged:(UISwitch *)sender {
    self.includeMedia = sender.isOn;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1; // 包含媒体文件选项
    } else if (section == 1) {
        return self.conversations.count; // 显示选中的会话
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return LocalizedString(@"BackupSettings");
    } else if (section == 1) {
        return [NSString stringWithFormat:LocalizedString(@"SelectedConversationsCount"), (long)self.conversations.count];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        static NSString *cellIdentifier = @"OptionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            // 创建开关
            self.mediaSwitch = [[UISwitch alloc] init];
            [self.mediaSwitch addTarget:self action:@selector(mediaSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.mediaSwitch;
        }

        cell.textLabel.text = LocalizedString(@"IncludeMediaFiles");
        cell.textLabel.numberOfLines = 0;
        self.mediaSwitch.on = self.includeMedia;

        return cell;
    } else if (indexPath.section == 1) {
        static NSString *cellIdentifier = @"ConversationCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        WFCCConversationInfo *convInfo = self.conversations[indexPath.row];
        WFCCConversation *conversation = convInfo.conversation;

        if (conversation.type == Single_Type) {
            WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
            cell.textLabel.text = user.displayName;
            cell.imageView.image = [UIImage imageNamed:@"PersonalChat"];
        } else {
            WFCCGroupInfo *group = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
            cell.textLabel.text = group.name;
            cell.imageView.image = [UIImage imageNamed:@"GroupChat"];
        }

        // 显示消息数量
        int messageCount = [[WFCCIMService sharedWFCIMService] getMessageCount:conversation];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d %@", messageCount, LocalizedString(@"MessagesCount")];

        return cell;
    }

    return [[UITableViewCell alloc] init];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
