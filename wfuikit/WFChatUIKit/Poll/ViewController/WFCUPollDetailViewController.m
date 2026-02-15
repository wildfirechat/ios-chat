//
//  WFCUPollDetailViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUPollDetailViewController.h"
#import "WFCUPoll.h"
#import "WFCUConfigManager.h"
#import "MBProgressHUD.h"
#import "UIView+Toast.h"
#import "WFCUForwardViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatClient/WFCCPollMessageContent.h>
#import <WFChatClient/WFCCPollResultMessageContent.h>
#import <SDWebImage/SDWebImage.h>

#define HEADER_HEIGHT 140
#define OPTION_CELL_HEIGHT 50
#define BOTTOM_BAR_HEIGHT 60

@interface WFCUPollHeaderView : UIView
@property (nonatomic, strong) UIImageView *creatorAvatarView;
@property (nonatomic, strong) UILabel *creatorLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *statusLabel;
- (void)configureWithPoll:(WFCUPoll *)poll;
@end

@implementation WFCUPollHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    
    CGFloat margin = 16;
    
    // 创建者头像
    self.creatorAvatarView = [[UIImageView alloc] initWithFrame:CGRectMake(margin, 16, 40, 40)];
    self.creatorAvatarView.layer.cornerRadius = 20;
    self.creatorAvatarView.layer.masksToBounds = YES;
    self.creatorAvatarView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [self addSubview:self.creatorAvatarView];
    
    // 创建者名称
    self.creatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin + 50, 20, self.bounds.size.width - margin * 2 - 50, 16)];
    self.creatorLabel.font = [UIFont systemFontOfSize:13];
    self.creatorLabel.textColor = [UIColor grayColor];
    self.creatorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.creatorLabel];
    
    // 状态标签
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - margin - 80, 20, 80, 20)];
    self.statusLabel.font = [UIFont systemFontOfSize:11];
    self.statusLabel.textAlignment = NSTextAlignmentRight;
    self.statusLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:self.statusLabel];
    
    // 标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 68, self.bounds.size.width - margin * 2, 24)];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.titleLabel];
    
    // 描述
    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 96, self.bounds.size.width - margin * 2, 20)];
    self.descLabel.font = [UIFont systemFontOfSize:14];
    self.descLabel.textColor = [UIColor grayColor];
    self.descLabel.numberOfLines = 0;
    self.descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.descLabel];
}

- (void)configureWithPoll:(WFCUPoll *)poll {
    CGFloat margin = 16;
    CGFloat currentY = 68;
    
    // 加载创建者头像
    WFCCUserInfo *creatorInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:poll.creatorId refresh:NO];
    if (creatorInfo.portrait.length > 0) {
        [self.creatorAvatarView sd_setImageWithURL:[NSURL URLWithString:creatorInfo.portrait] 
                                  placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    } else {
        self.creatorAvatarView.image = [UIImage imageNamed:@"PersonalChat"];
    }
    
    // 创建者名称
    NSString *creatorName = creatorInfo.displayName ?: creatorInfo.name ?: poll.creatorId;
    self.creatorLabel.text = [NSString stringWithFormat:WFCString(@"PollCreator"), creatorName];
    
    // 状态标签
    NSString *remainingTime = [poll remainingTimeText];
    if (remainingTime) {
        self.statusLabel.text = remainingTime;
        self.statusLabel.textColor = [UIColor systemOrangeColor];
    } else if (poll.status == 1) {
        self.statusLabel.text = WFCString(@"PollStatusEnded");
        self.statusLabel.textColor = [UIColor grayColor];
    } else {
        self.statusLabel.text = @"";
    }
    
    // 标题
    self.titleLabel.text = poll.title;
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.bounds.size.width - margin * 2, 60)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                      attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                         context:nil].size;
    self.titleLabel.frame = CGRectMake(margin, currentY, self.bounds.size.width - margin * 2, ceil(titleSize.height));
    currentY += ceil(titleSize.height) + 8;
    
    // 描述
    if (poll.desc.length > 0) {
        self.descLabel.text = poll.desc;
        self.descLabel.hidden = NO;
        CGSize descSize = [self.descLabel.text boundingRectWithSize:CGSizeMake(self.bounds.size.width - margin * 2, 60)
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:@{NSFontAttributeName: self.descLabel.font}
                                                            context:nil].size;
        self.descLabel.frame = CGRectMake(margin, currentY, self.bounds.size.width - margin * 2, ceil(descSize.height));
        currentY += ceil(descSize.height) + 8;
    } else {
        self.descLabel.hidden = YES;
    }
    
    // 调整header高度
    CGRect frame = self.frame;
    frame.size.height = MAX(HEADER_HEIGHT, currentY + 16);
    self.frame = frame;
}

@end

@interface WFCUPollDetailViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) WFCUPollHeaderView *headerView;

// 数据
@property (nonatomic, strong) WFCUPoll *poll;
@property (nonatomic, strong) NSString *currentUserId;

// 选中的选项（投票前）
@property (nonatomic, strong) NSMutableSet<NSNumber *> *selectedOptions;

// 导航栏按钮
@property (nonatomic, strong) UIBarButtonItem *submitItem;
@property (nonatomic, strong) UIBarButtonItem *forwardItem;

// 底部操作栏（管理者界面）
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UIButton *closeButton;    // 关闭投票按钮
@property (nonatomic, strong) UIButton *deleteButton;   // 删除投票按钮

@end

@implementation WFCUPollDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupData];
    [self setupUI];
    [self fetchPollDetail];
}

- (void)setupData {
    self.currentUserId = [WFCCNetworkService sharedInstance].userId;
    self.selectedOptions = [NSMutableSet set];
    
    // 如果从消息进入，从消息内容获取 pollId 和 groupId
    // 如果从我的投票进入，使用外部传入的 pollId 和 groupId
    if (self.message) {
        if ([self.message.content isKindOfClass:[WFCCPollMessageContent class]]) {
            WFCCPollMessageContent *content = (WFCCPollMessageContent *)self.message.content;
            self.pollId = [content.pollId longLongValue];
            self.groupId = self.message.conversation.target;
        } else if ([self.message.content isKindOfClass:[WFCCPollResultMessageContent class]]) {
            WFCCPollResultMessageContent *content = (WFCCPollResultMessageContent *)self.message.content;
            self.pollId = [content.pollId longLongValue];
            self.groupId = content.groupId.length > 0 ? content.groupId : self.message.conversation.target;
        }
    }
    // 否则保留外部设置的 pollId 和 groupId
}

- (void)setupUI {
    self.title = WFCString(@"PollDetail");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 根据进入方式设置返回按钮
    if (self.message) {
        // 从消息点击进入（modal 展示）
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Close") style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
        self.navigationItem.leftBarButtonItem = closeItem;
    } else {
        // 从我的投票点击进入（push）
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(onClose:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        self.navigationItem.leftBarButtonItem = backItem;
    }
    
    // 提交按钮（参与者界面）
    self.submitItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Submit") style:UIBarButtonItemStyleDone target:self action:@selector(onSubmit:)];
    self.submitItem.enabled = NO;
    
    // 转发按钮（管理者界面）
    self.forwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrowshape.turn.up.right"] style:UIBarButtonItemStylePlain target:self action:@selector(onForward:)];
    
    // Header
    self.headerView = [[WFCUPollHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, HEADER_HEIGHT)];
    
    // 底部操作栏（管理者界面使用）
    [self setupBottomBar];
    
    // TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.headerView;
    [self.view addSubview:self.tableView];
}

- (void)setupBottomBar {
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - BOTTOM_BAR_HEIGHT - 34, self.view.bounds.size.width, BOTTOM_BAR_HEIGHT + 34)];
    self.bottomBar.backgroundColor = [UIColor whiteColor];
    self.bottomBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.bottomBar.hidden = YES; // 默认隐藏
    
    // 分隔线
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bottomBar.bounds.size.width, 0.5)];
    line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.bottomBar addSubview:line];
    
    // 按钮高度和Y坐标
    CGFloat buttonY = 10;
    CGFloat buttonHeight = 40;
    
    // 导出数据按钮（实名投票显示，匿名投票隐藏）
    self.exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.exportButton.backgroundColor = [UIColor systemBlueColor];
    [self.exportButton setTitle:WFCString(@"ExportPoll") forState:UIControlStateNormal];
    [self.exportButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.exportButton.layer.cornerRadius = 8;
    self.exportButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.exportButton addTarget:self action:@selector(onExport:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.exportButton];
    
    // 关闭投票按钮（投票进行中显示）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.backgroundColor = [UIColor systemRedColor];
    [self.closeButton setTitle:WFCString(@"EndPoll") forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 8;
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.closeButton addTarget:self action:@selector(onClosePoll:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.closeButton];
    
    // 删除投票按钮（投票结束后显示）
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.deleteButton.backgroundColor = [UIColor systemRedColor];
    [self.deleteButton setTitle:WFCString(@"DeletePoll") forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.deleteButton.layer.cornerRadius = 8;
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.deleteButton addTarget:self action:@selector(onDeletePoll:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.deleteButton];
    
    [self.view addSubview:self.bottomBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // 调整 tableView 大小，为底部栏留出空间
    BOOL isManager = (!self.message && self.poll.isCreator);
    CGFloat bottomHeight = isManager ? (BOTTOM_BAR_HEIGHT + 34) : 0;
    self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - bottomHeight);
    self.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height - bottomHeight, self.view.bounds.size.width, bottomHeight);
}

#pragma mark - Actions

- (void)onClose:(id)sender {
    if (self.message) {
        // 从消息点击进入（modal 展示）
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // 从我的投票列表点击进入（push）
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onSubmit:(id)sender {
    if (self.selectedOptions.count == 0) {
        [self.view makeToast:WFCString(@"PleaseSelectOption") duration:2 position:CSToastPositionCenter];
        return;
    }
    
    [self doVote];
}

- (void)onClosePoll:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Confirm") message:WFCString(@"ConfirmClosePoll") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Close") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self doClosePoll];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onDeletePoll:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Confirm") message:WFCString(@"ConfirmDeletePoll") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self doDeletePoll];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)onExport:(id)sender {
    [self doExport];
}

- (void)onForward:(id)sender {
    if (!self.poll) return;
    
    // 使用现有的转发组件 WFCUForwardViewController
    // 构建投票消息内容
    WFCCPollMessageContent *content = [[WFCCPollMessageContent alloc] init];
    content.pollId = [NSString stringWithFormat:@"%lld", self.poll.pollId];
    content.groupId = self.poll.groupId;
    content.creatorId = self.poll.creatorId;
    content.title = self.poll.title;
    content.desc = self.poll.desc;
    content.visibility = self.poll.visibility;
    content.type = self.poll.type;
    content.anonymous = self.poll.anonymous;
    content.status = self.poll.status;
    content.endTime = self.poll.endTime;
    content.totalVotes = self.poll.totalVotes;
    
    // 构建消息对象
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.content = content;
    message.conversation = [[WFCCConversation alloc] init];
    message.conversation.type = Group_Type;
    message.conversation.target = self.poll.groupId;
    message.conversation.line = 0;
    
    // 创建转发控制器
    WFCUForwardViewController *forwardVC = [[WFCUForwardViewController alloc] init];
    forwardVC.message = message;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:forwardVC];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)doExport {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service exportPollDetails:self.pollId success:^(NSArray<WFCUPollVoterDetail *> *details) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf showExportResult:details];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)showExportResult:(NSArray<WFCUPollVoterDetail *> *)details {
    if (details.count == 0) {
        [self.view makeToast:WFCString(@"NoVoterDetails") duration:2 position:CSToastPositionCenter];
        return;
    }
    
    // 生成CSV内容
    NSMutableString *csv = [NSMutableString string];
    NSString *csvHeader = [NSString stringWithFormat:@"\uFEFF%@,%@,%@\n", 
                          WFCString(@"CSVOption"), WFCString(@"CSVUser"), WFCString(@"CSVTime")];
    [csv appendString:csvHeader]; // UTF-8 BOM
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    for (WFCUPollVoterDetail *detail in details) {
        NSString *timeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:detail.createdAt / 1000.0]];
        [csv appendFormat:@"%@,%@,%@\n", detail.optionText, detail.userName, timeStr];
    }
    
    // 生成安全的文件名
    NSString *safeTitle = [self safeFileName:self.poll.title];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@.csv", safeTitle, WFCString(@"PollDetails")];
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    
    // 写入文件
    NSData *csvData = [csv dataUsingEncoding:NSUTF8StringEncoding];
    BOOL success = [csvData writeToFile:tempPath atomically:YES];
    
    if (!success) {
        [self.view makeToast:WFCString(@"ExportFailed") duration:2 position:CSToastPositionCenter];
        return;
    }
    
    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityVC.modalPresentationStyle = UIModalPresentationPopover;
        activityVC.popoverPresentationController.barButtonItem = self.forwardItem;
    }
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

// 生成安全的文件名
- (NSString *)safeFileName:(NSString *)fileName {
    if (fileName.length == 0) {
        return WFCString(@"Poll");
    }
    
    // 替换文件系统中的非法字符
    NSCharacterSet *illegalCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    NSString *safeName = [[fileName componentsSeparatedByCharactersInSet:illegalCharacters] componentsJoinedByString:@"_"];
    
    // 限制文件名长度（避免路径过长）
    if (safeName.length > 50) {
        safeName = [safeName substringToIndex:50];
    }
    
    return safeName.length > 0 ? safeName : WFCString(@"Poll");
}

- (void)doVote {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service vote:self.pollId
        optionIds:[self.selectedOptions allObjects]
          success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // 先刷新投票详情，显示结果
            [weakSelf fetchPollDetail];
            [hud hideAnimated:YES];
            // 刷新后显示成功提示
            [weakSelf.view makeToast:WFCString(@"VoteSuccess") duration:1 position:CSToastPositionCenter];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            NSString *errorMsg = message;
            if (errorCode == 4005) {
                errorMsg = WFCString(@"NotInGroup");
            } else if (errorCode == 4002) {
                errorMsg = WFCString(@"AlreadyVoted");
            }
            [weakSelf.view makeToast:errorMsg ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)doClosePoll {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service closePoll:self.pollId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"PollClosed") duration:1 position:CSToastPositionCenter];
            [weakSelf fetchPollDetail];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)doDeletePoll {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    
    __weak typeof(self) weakSelf = self;
    [service deletePoll:self.pollId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"PollDeleted") duration:1 position:CSToastPositionCenter];
            // 删除成功后返回上一页
            [weakSelf.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)fetchPollDetail {
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    if (!service) return;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");
    
    __weak typeof(self) weakSelf = self;
    [service getPoll:self.pollId success:^(WFCUPoll *poll) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            weakSelf.poll = poll;
            [weakSelf.headerView configureWithPoll:poll];
            weakSelf.tableView.tableHeaderView = weakSelf.headerView;
            [weakSelf.tableView reloadData];
            [weakSelf updateNavigationBar];
            [weakSelf updateBottomBar];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)updateNavigationBar {
    // 判断是否是管理者界面（从我的投票进入且是创建者）
    BOOL isManager = (!self.message && self.poll.isCreator);
    
    if (isManager) {
        // 管理者界面：导航栏右侧显示转发按钮
        self.navigationItem.rightBarButtonItem = self.forwardItem;
    } else {
        // 参与者界面：更新提交按钮状态
        [self updateSubmitButton];
    }
}

- (void)updateBottomBar {
    // 判断是否是管理者界面（从我的投票进入且是创建者）
    BOOL isManager = (!self.message && self.poll.isCreator);
    
    if (isManager) {
        self.bottomBar.hidden = NO;
        
        // 判断是否是匿名投票
        BOOL isAnonymous = (self.poll.anonymous != 0);
        
        // 判断投票是否已结束
        BOOL isEnded = (self.poll.status == 1 || self.poll.isExpired);
        
        CGFloat buttonY = 10;
        CGFloat buttonHeight = 40;
        CGFloat barWidth = self.bottomBar.bounds.size.width;
        
        if (isAnonymous) {
            // 匿名投票：只显示关闭/删除按钮，居中显示
            CGFloat centerButtonWidth = 200; // 居中按钮宽度
            CGFloat centerButtonX = (barWidth - centerButtonWidth) / 2;
            
            self.exportButton.hidden = YES;
            
            if (isEnded) {
                // 已结束：显示删除按钮（居中）
                self.closeButton.hidden = YES;
                self.deleteButton.hidden = NO;
                self.deleteButton.frame = CGRectMake(centerButtonX, buttonY, centerButtonWidth, buttonHeight);
            } else {
                // 进行中：显示关闭按钮（居中）
                self.closeButton.hidden = NO;
                self.deleteButton.hidden = YES;
                self.closeButton.frame = CGRectMake(centerButtonX, buttonY, centerButtonWidth, buttonHeight);
                self.closeButton.enabled = YES;
                self.closeButton.alpha = 1.0;
            }
        } else {
            // 实名投票：显示导出按钮 + 关闭/删除按钮（并排）
            CGFloat buttonWidth = (barWidth - 48) / 2; // 16*3 间距
            
            self.exportButton.hidden = NO;
            self.exportButton.frame = CGRectMake(16, buttonY, buttonWidth, buttonHeight);
            self.exportButton.backgroundColor = [UIColor systemBlueColor];
            [self.exportButton setTitle:WFCString(@"ExportPoll") forState:UIControlStateNormal];
            
            CGFloat rightButtonX = 16 + buttonWidth + 16;
            
            if (isEnded) {
                // 已结束：显示删除按钮
                self.closeButton.hidden = YES;
                self.deleteButton.hidden = NO;
                self.deleteButton.frame = CGRectMake(rightButtonX, buttonY, buttonWidth, buttonHeight);
            } else {
                // 进行中：显示关闭按钮
                self.closeButton.hidden = NO;
                self.deleteButton.hidden = YES;
                self.closeButton.frame = CGRectMake(rightButtonX, buttonY, buttonWidth, buttonHeight);
                self.closeButton.enabled = YES;
                self.closeButton.alpha = 1.0;
            }
        }
        
        // 调整 tableView 大小
        self.tableView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - BOTTOM_BAR_HEIGHT - 34);
        self.bottomBar.frame = CGRectMake(0, self.view.bounds.size.height - BOTTOM_BAR_HEIGHT - 34, self.view.bounds.size.width, BOTTOM_BAR_HEIGHT + 34);
    } else {
        self.bottomBar.hidden = YES;
        self.tableView.frame = self.view.bounds;
    }
}

- (void)updateSubmitButton {
    // 判断是否是管理场景（从我的投票进入且是创建者）
    BOOL isManager = (!self.message && self.poll.isCreator);
    
    // 只有非管理场景、未投票且投票进行中才显示提交按钮
    BOOL canSubmit = !isManager && !self.poll.hasVoted && self.poll.status == 0 && !self.poll.isExpired;
    
    if (canSubmit) {
        self.navigationItem.rightBarButtonItem = self.submitItem;
        self.submitItem.enabled = self.selectedOptions.count > 0;
    } else {
        // 管理场景、已投票或已结束，不显示提交按钮
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // 更新标题显示已选数量（多选时）
    if (canSubmit && self.poll.type == 2 && self.selectedOptions.count > 0) {
        self.title = [NSString stringWithFormat:WFCString(@"SelectedCount"), (int)self.selectedOptions.count, self.poll.maxSelect];
    } else {
        self.title = WFCString(@"PollDetail");
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; // 信息、选项
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 0; // Header 已经显示信息
    return self.poll.options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 选项
    static NSString *cellId = @"OptionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
        // 选项文字标签
        UILabel *optionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, 44)];
        optionLabel.tag = 100;
        optionLabel.font = [UIFont systemFontOfSize:16];
        [cell.contentView addSubview:optionLabel];
        
        // 对勾标签（在选项后面，间隔16）
        UILabel *checkmarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 44)];
        checkmarkLabel.tag = 101;
        checkmarkLabel.text = @"✓";
        checkmarkLabel.font = [UIFont systemFontOfSize:18];
        checkmarkLabel.textColor = [UIColor systemBlueColor];
        checkmarkLabel.textAlignment = NSTextAlignmentCenter;
        checkmarkLabel.hidden = YES;
        [cell.contentView addSubview:checkmarkLabel];
        
        // 比例标签（最右侧，右对齐）
        UILabel *percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
        percentLabel.tag = 102;
        percentLabel.font = [UIFont systemFontOfSize:15];
        percentLabel.textColor = [UIColor grayColor];
        percentLabel.textAlignment = NSTextAlignmentRight;
        percentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [cell.contentView addSubview:percentLabel];
    }
    
    WFCUPollOption *option = self.poll.options[indexPath.row];
    
    UILabel *optionLabel = [cell.contentView viewWithTag:100];
    UILabel *checkmarkLabel = [cell.contentView viewWithTag:101];
    UILabel *percentLabel = [cell.contentView viewWithTag:102];
    
    // 计算布局
    CGFloat margin = 16;
    CGFloat cellWidth = cell.contentView.frame.size.width;
    CGFloat rightPadding = 16; // 右侧边距
    
    // 判断是否已投票/已结束/管理场景（管理场景不能投票）
    BOOL isManager = (!self.message && self.poll.isCreator);
    BOOL hasVoted = self.poll.hasVoted || self.poll.status == 1 || self.poll.isExpired || isManager;
    
    // 选项文字
    optionLabel.frame = CGRectMake(margin, 0, cellWidth - 100, 44);
    optionLabel.text = option.optionText;
    
    // 比例在最右侧
    percentLabel.frame = CGRectMake(cellWidth - 120 - rightPadding, 0, 120, 44);
    
    // 是否显示结果
    if ([self.poll shouldShowResult]) {
        percentLabel.text = [NSString stringWithFormat:WFCString(@"VoteCountFormat"), option.votePercent, option.voteCount];
    } else {
        percentLabel.text = @"";
    }
    
    // 选中状态
    BOOL isSelected = [self.selectedOptions containsObject:@(option.optionId)];
    BOOL isMyVote = [self.poll.myOptionIds containsObject:@(option.optionId)];
    
    if (isMyVote) {
        // 已投票状态：对勾紧跟选项
        checkmarkLabel.hidden = NO;
        checkmarkLabel.frame = CGRectMake(margin + MIN(optionLabel.intrinsicContentSize.width, cellWidth - 200) + 8, 0, 30, 44);
        checkmarkLabel.textColor = [UIColor systemBlueColor];
        optionLabel.textColor = [UIColor systemBlueColor];
    } else if (isSelected && !hasVoted) {
        // 投票前选中：对勾在最右侧（cell最右边 - 24 - padding）
        checkmarkLabel.hidden = NO;
        checkmarkLabel.frame = CGRectMake(cellWidth - 24 - rightPadding, 0, 30, 44);
        checkmarkLabel.textColor = [UIColor systemBlueColor];
        optionLabel.textColor = [UIColor blackColor];
    } else if (isSelected && hasVoted) {
        // 已投票后选中：对勾紧跟选项
        checkmarkLabel.hidden = NO;
        checkmarkLabel.frame = CGRectMake(margin + MIN(optionLabel.intrinsicContentSize.width, cellWidth - 200) + 8, 0, 30, 44);
        checkmarkLabel.textColor = [UIColor systemBlueColor];
        optionLabel.textColor = [UIColor blackColor];
    } else {
        checkmarkLabel.hidden = YES;
        optionLabel.textColor = [UIColor blackColor];
    }
    
    // 已投票或已结束则不可选
    if (hasVoted) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        if (self.poll.type == 2) {
            return [NSString stringWithFormat:@"%@ (%@)", WFCString(@"Options"), WFCString(@"MultipleChoice")];
        }
        return WFCString(@"Options");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        NSMutableArray *statusParts = [NSMutableArray array];
        
        // 投票类型
        [statusParts addObject:self.poll.anonymous == 1 ? WFCString(@"AnonymousPoll") : WFCString(@"NamedPoll")];
        
        // 参与人数（使用 voterCount 去重后的实际人数）
        [statusParts addObject:[NSString stringWithFormat:WFCString(@"VoterCount"), self.poll.voterCount]];
        
        // 剩余时间（放在参与人数后面）
        NSString *remainingTime = [self formatRemainingTime:self.poll];
        if (remainingTime.length > 0) {
            [statusParts addObject:remainingTime];
        }
        
        // 状态
        if (self.poll.status == 1) {
            [statusParts addObject:WFCString(@"PollStatusEnded")];
        } else if (self.poll.isExpired) {
            [statusParts addObject:WFCString(@"PollExpired")];
        } else if (self.poll.hasVoted) {
            [statusParts addObject:WFCString(@"AlreadyVoted")];
        }
        
        return [statusParts componentsJoinedByString:@" · "];
    }
    return nil;
}

/// 格式化剩余时间
- (NSString *)formatRemainingTime:(WFCUPoll *)poll {
    // 已结束或已过期
    if (poll.status == 1 || poll.isExpired) {
        return @"";
    }
    
    // 无限期投票（endTime <= 0）
    if (poll.endTime <= 0) {
        return WFCString(@"NoDeadline");
    }
    
    // 计算剩余时间
    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    if (poll.endTime <= now) {
        return @"";
    }
    
    long long remainingMs = poll.endTime - now;
    long long remainingMinutes = remainingMs / (1000 * 60);
    long long remainingHours = remainingMs / (1000 * 60 * 60);
    
    if (remainingHours >= 1) {
        return [NSString stringWithFormat:WFCString(@"HoursLeft"), (int)remainingHours];
    } else if (remainingMinutes >= 1) {
        return [NSString stringWithFormat:WFCString(@"MinutesLeft"), (int)remainingMinutes];
    } else {
        return WFCString(@"LessThanOneMinute");
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section != 1) return;
    
    // 管理场景不能投票
    BOOL isManager = (!self.message && self.poll.isCreator);
    if (isManager) return;
    
    if (self.poll.hasVoted || self.poll.status == 1 || self.poll.isExpired) return;
    
    WFCUPollOption *option = self.poll.options[indexPath.row];
    NSNumber *optionId = @(option.optionId);
    
    if (self.poll.type == 1) {
        // 单选
        [self.selectedOptions removeAllObjects];
        [self.selectedOptions addObject:optionId];
    } else {
        // 多选
        if ([self.selectedOptions containsObject:optionId]) {
            [self.selectedOptions removeObject:optionId];
        } else {
            // 检查最大选择数
            if (self.poll.maxSelect > 0 && self.selectedOptions.count >= self.poll.maxSelect) {
                [self.view makeToast:[NSString stringWithFormat:WFCString(@"MaxSelectLimit"), self.poll.maxSelect] duration:2 position:CSToastPositionCenter];
                return;
            }
            [self.selectedOptions addObject:optionId];
        }
    }
    
    [self.tableView reloadData];
    [self updateSubmitButton];
}

@end
