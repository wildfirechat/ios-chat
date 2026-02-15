//
//  WFCUPollListViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPollListViewController.h"
#import "WFCUPollDetailViewController.h"
#import "WFCUConfigManager.h"
#import "WFCUPollService.h"
#import "WFCUPoll.h"
#import "WFCUImage.h"
#import "MBProgressHUD.h"
#import "UIView+Toast.h"

#define WFCString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:key value:@"" table:@"wfc"]

@interface WFCUPollListCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *typeIcon;
@end

@implementation WFCUPollListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // 类型图标
    self.typeIcon = [[UIImageView alloc] init];
    self.typeIcon.tintColor = [UIColor systemBlueColor];
    [self.contentView addSubview:self.typeIcon];
    
    // 标题
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.numberOfLines = 2;
    [self.contentView addSubview:self.titleLabel];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.layer.cornerRadius = 4;
    self.statusLabel.clipsToBounds = YES;
    [self.contentView addSubview:self.statusLabel];
    
    // 参与人数
    self.countLabel = [[UILabel alloc] init];
    self.countLabel.font = [UIFont systemFontOfSize:13];
    self.countLabel.textColor = [UIColor grayColor];
    [self.contentView addSubview:self.countLabel];
    
    // 创建时间
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.timeLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat padding = 16;
    CGFloat iconSize = 40;
    
    self.typeIcon.frame = CGRectMake(padding, (self.contentView.frame.size.height - iconSize) / 2, iconSize, iconSize);
    
    CGFloat contentX = padding + iconSize + 12;
    CGFloat contentWidth = self.contentView.frame.size.width - contentX - padding - 30; // 30 for accessory
    
    self.titleLabel.frame = CGRectMake(contentX, 12, contentWidth - 90, 44);
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = CGRectMake(contentX, 12, contentWidth - 90, MIN(self.titleLabel.frame.size.height, 44));
    
    // 时间右侧对齐，距离右边 16 个点
    CGFloat rightPadding = 16;
    self.timeLabel.frame = CGRectMake(self.contentView.frame.size.width - 80 - rightPadding, 12, 80, 20);
    self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    self.statusLabel.frame = CGRectMake(contentX, 40, 50, 20);
    
    CGFloat countX = contentX + 60;
    self.countLabel.frame = CGRectMake(countX, 40, contentWidth - 60 - 80, 20);
}

- (void)configureWithPoll:(WFCUPoll *)poll {
    self.titleLabel.text = poll.title;
    
    // 类型图标
    if (poll.type == 1) {
        self.typeIcon.image = [UIImage systemImageNamed:@"checkmark.circle.fill"];
    } else {
        self.typeIcon.image = [UIImage systemImageNamed:@"checkmark.seal.fill"];
    }
    
    // 状态标签
    if (poll.status == 1 || [poll isExpired]) {
        self.statusLabel.text = WFCString(@"PollStatusEnded");
        self.statusLabel.backgroundColor = [UIColor systemGrayColor];
    } else {
        self.statusLabel.text = WFCString(@"PollInProgress");
        self.statusLabel.backgroundColor = [UIColor systemGreenColor];
    }
    
    // 参与人数（使用 voterCount 去重后的实际人数）
    self.countLabel.text = [NSString stringWithFormat:@"%d %@", 
        poll.voterCount, WFCString(@"Participants")];
    
    // 创建时间
    self.timeLabel.text = [self formatTime:poll.createdAt];
}

- (NSString *)formatTime:(long long)time {
    if (time <= 0) return @"";
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time / 1000.0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM-dd HH:mm";
    return [formatter stringFromDate:date];
}

@end

@interface WFCUPollListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<WFCUPoll *> *polls;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation WFCUPollListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WFCString(@"MyPolls");
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.polls = [NSMutableArray array];
    
    [self setupNavigationBar];
    [self setupTableView];
    [self loadPolls];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 从详情页返回时刷新列表（关闭或删除投票后需要更新状态）
    [self loadPolls];
}

- (void)setupNavigationBar {
    // 返回按钮（我的投票是被 push 的）
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.rowHeight = 80;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView registerClass:[WFCUPollListCell class] forCellReuseIdentifier:@"PollListCell"];
    [self.view addSubview:self.tableView];
    
    // 下拉刷新（使用原生 UIRefreshControl）
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    // 空数据提示
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = WFCString(@"NoPolls");
    emptyLabel.textColor = [UIColor grayColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.font = [UIFont systemFontOfSize:16];
    self.tableView.backgroundView = emptyLabel;
    self.tableView.backgroundView.hidden = YES;
}

- (void)closeButtonTapped:(id)sender {
    // 从导航栈 pop 回投票首页
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)handleRefresh:(UIRefreshControl *)sender {
    [self loadPolls];
}

- (void)loadPolls {
    if (self.isLoading) return;
    self.isLoading = YES;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service getMyPollsWithSuccess:^(NSArray<WFCUPoll *> *polls) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.tableView.refreshControl endRefreshing];
            weakSelf.isLoading = NO;
            
            [weakSelf.polls removeAllObjects];
            [weakSelf.polls addObjectsFromArray:polls];
            [weakSelf.tableView reloadData];
            
            weakSelf.tableView.backgroundView.hidden = weakSelf.polls.count > 0;
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.tableView.refreshControl endRefreshing];
            weakSelf.isLoading = NO;
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.polls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUPollListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PollListCell" forIndexPath:indexPath];
    WFCUPoll *poll = self.polls[indexPath.row];
    [cell configureWithPoll:poll];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WFCUPoll *poll = self.polls[indexPath.row];
    WFCUPollDetailViewController *vc = [[WFCUPollDetailViewController alloc] init];
    vc.pollId = poll.pollId;
    vc.groupId = poll.groupId;
    [self.navigationController pushViewController:vc animated:YES];
}

// 左滑操作：结束投票（进行中）或删除投票（已结束）
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
    WFCUPoll *poll = self.polls[indexPath.row];
    
    // 只有创建者才显示操作
    if (!poll.isCreator) {
        return nil;
    }
    
    // 判断投票是否已结束
    BOOL isEnded = (poll.status == 1 || [poll isExpired]);
    
    if (isEnded) {
        // 已结束：显示删除按钮
        UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                   title:WFCString(@"Delete")
                                                                                 handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [self showDeletePollConfirm:poll];
            completionHandler(NO);
        }];
        deleteAction.backgroundColor = [UIColor systemRedColor];
        
        return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    } else {
        // 进行中：显示结束按钮
        UIContextualAction *closeAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                                   title:WFCString(@"EndPoll")
                                                                                 handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
            [self showClosePollConfirm:poll];
            completionHandler(NO);
        }];
        closeAction.backgroundColor = [UIColor systemOrangeColor];
        
        return [UISwipeActionsConfiguration configurationWithActions:@[closeAction]];
    }
}

- (void)showClosePollConfirm:(WFCUPoll *)poll {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Confirm")
                                                                   message:WFCString(@"ConfirmClosePoll")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self doClosePoll:poll];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doClosePoll:(WFCUPoll *)poll {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service closePoll:poll.pollId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"PollClosed") duration:1 position:CSToastPositionCenter];
            [weakSelf loadPolls]; // 刷新列表
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)showDeletePollConfirm:(WFCUPoll *)poll {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Confirm")
                                                                   message:WFCString(@"ConfirmDeletePoll")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self doDeletePoll:poll];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doDeletePoll:(WFCUPoll *)poll {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service deletePoll:poll.pollId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"PollDeleted") duration:1 position:CSToastPositionCenter];
            [weakSelf loadPolls]; // 刷新列表
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

@end
