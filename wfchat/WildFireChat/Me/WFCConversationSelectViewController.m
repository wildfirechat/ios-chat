//
//  WFCConversationSelectViewController.m
//  WildFireChat
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCConversationSelectViewController.h"
#import "WFCBackupOptionsViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>

// 自定义Cell类
@interface WFCConversationSelectCell : UITableViewCell
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIButton *radioButton;
- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle avatarURL:(NSString *)avatarURL defaultAvatar:(NSString *)defaultAvatar;
@end

@implementation WFCConversationSelectCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];

        // 头像视图 - 方形带圆角
        self.avatarImageView = [[UIImageView alloc] init];
        self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.avatarImageView.layer.cornerRadius = 6.0;  // 方形带6点圆角
        self.avatarImageView.clipsToBounds = YES;
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.avatarImageView];

        // 标题
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.contentView addSubview:self.titleLabel];

        // 副标题（消息条数）
        self.subtitleLabel = [[UILabel alloc] init];
        self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.subtitleLabel.font = [UIFont systemFontOfSize:14];
        self.subtitleLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.subtitleLabel];

        // 单选按钮
        self.radioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.radioButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.radioButton.userInteractionEnabled = NO;

        if (@available(iOS 13.0, *)) {
            [self.radioButton setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
            [self.radioButton setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
            self.radioButton.tintColor = [UIColor systemBlueColor];
        } else {
            [self.radioButton setTitle:@"○" forState:UIControlStateNormal];
            [self.radioButton setTitle:@"●" forState:UIControlStateSelected];
            [self.radioButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [self.radioButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateSelected];
            self.radioButton.titleLabel.font = [UIFont systemFontOfSize:20];
        }

        [self.contentView addSubview:self.radioButton];

        // 布局约束
        [NSLayoutConstraint activateConstraints:@[
            // 头像：左边距8，居中，固定40x40
            [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:8],
            [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.avatarImageView.widthAnchor constraintEqualToConstant:40],
            [self.avatarImageView.heightAnchor constraintEqualToConstant:40],

            // 单选按钮：右边距8，居中，固定24x24
            [self.radioButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-8],
            [self.radioButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [self.radioButton.widthAnchor constraintEqualToConstant:24],
            [self.radioButton.heightAnchor constraintEqualToConstant:24],

            // 标题：左边距距头像8，右边距距单选按钮8
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:8],
            [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.radioButton.leadingAnchor constant:-8],
            [self.titleLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor],

            // 副标题：左边距距头像8，右边距距单选按钮8，底部对齐头像
            [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:8],
            [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.radioButton.leadingAnchor constant:-8],
            [self.subtitleLabel.bottomAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor]
        ]];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.radioButton.selected = selected;
    self.contentView.backgroundColor = selected ? [[UIColor alloc] initWithWhite:0.95 alpha:1.0] : [UIColor clearColor];
}

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle avatarURL:(NSString *)avatarURL defaultAvatar:(NSString *)defaultAvatar {
    self.titleLabel.text = title;
    self.subtitleLabel.text = subtitle;

    if (avatarURL && avatarURL.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:avatarURL]
                               placeholderImage:[UIImage imageNamed:defaultAvatar]];
    } else {
        self.avatarImageView.image = [UIImage imageNamed:defaultAvatar];
    }
}

@end

@interface WFCConversationSelectViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<WFCCConversationInfo *> *conversations;
@property (nonatomic, strong) UIButton *selectAllButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, assign) BOOL isAllSelected;
@end

@implementation WFCConversationSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"选择会话";
    self.isAllSelected = NO;

    // 左侧取消按钮
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"取消"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(cancelButtonClicked:)];
    self.navigationItem.leftBarButtonItem = cancelButton;

    // 右侧按钮容器
    self.selectAllButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.selectAllButton setTitle:@"全选" forState:UIControlStateNormal];
    [self.selectAllButton addTarget:self action:@selector(selectAllButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    self.nextButton.enabled = NO;
    [self.nextButton addTarget:self action:@selector(nextButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    // 使用UIStackView布局按钮
    UIStackView *buttonStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.selectAllButton, self.nextButton]];
    buttonStack.spacing = 16;
    buttonStack.axis = UILayoutConstraintAxisHorizontal;

    // 创建自定义BarButtonItem
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:buttonStack];
    self.navigationItem.rightBarButtonItem = rightBarButton;

    // 创建表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES; // 允许多选
    self.tableView.allowsMultipleSelection = YES;
    [self.view addSubview:self.tableView];

    // 加载会话列表
    [self loadConversations];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - Data Loading

- (void)loadConversations {
    // 备份单聊、群聊和频道
    NSArray *conversationTypes = @[@(Single_Type), @(Group_Type), @(Channel_Type)];
    self.conversations = [[WFCCIMService sharedWFCIMService] getConversationInfos:conversationTypes
                                                                               lines:@[@0]];

    // 排序：最近消息时间倒序
    self.conversations = [self.conversations sortedArrayUsingComparator:^NSComparisonResult(WFCCConversationInfo *obj1, WFCCConversationInfo *obj2) {
        long long time1 = obj1.timestamp;
        long long time2 = obj2.timestamp;
        return time2 < time1 ? NSOrderedAscending : NSOrderedDescending;
    }];

    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)cancelButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectAllButtonClicked:(UIButton *)sender {
    self.isAllSelected = !self.isAllSelected;

    if (self.isAllSelected) {
        // 全选：遍历所有行
        for (NSInteger i = 0; i < self.conversations.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [self.selectAllButton setTitle:@"取消全选" forState:UIControlStateNormal];
    } else {
        // 取消全选：获取所有选中的行并取消
        NSArray<NSIndexPath *> *selectedRows = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *indexPath in selectedRows) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        [self.selectAllButton setTitle:@"全选" forState:UIControlStateNormal];
    }

    self.nextButton.enabled = self.tableView.indexPathsForSelectedRows.count > 0;
}

- (void)nextButtonClicked:(UIButton *)sender {
    NSArray<NSIndexPath *> *selectedRows = self.tableView.indexPathsForSelectedRows;
    if (selectedRows.count == 0) {
        return;
    }

    // 获取选中的会话
    NSMutableArray *selectedConversations = [NSMutableArray array];
    for (NSIndexPath *indexPath in selectedRows) {
        [selectedConversations addObject:self.conversations[indexPath.row]];
    }

    // 跳转到备份选项界面
    WFCBackupOptionsViewController *vc = [[WFCBackupOptionsViewController alloc] init];
    vc.conversations = selectedConversations;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ConversationCell";
    WFCConversationSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[WFCConversationSelectCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    WFCCConversationInfo *convInfo = self.conversations[indexPath.row];
    WFCCConversation *conversation = convInfo.conversation;

    // 获取消息条数
    int messageCount = [[WFCCIMService sharedWFCIMService] getMessageCount:conversation];
    NSString *subtitle = [NSString stringWithFormat:@"%d 条消息", messageCount];

    // 显示会话标题、头像和消息条数
    if (conversation.type == Single_Type) {
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
        NSString *title = user.displayName ?: @"未知用户";

        [cell configureWithTitle:title
                         subtitle:subtitle
                       avatarURL:user.portrait
                   defaultAvatar:@"PersonalChat"];
    } else {
        WFCCGroupInfo *group = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        NSString *title = group.name ?: @"未知群组";

        [cell configureWithTitle:title
                         subtitle:subtitle
                       avatarURL:group.portrait
                   defaultAvatar:@"GroupChat"];
    }

    // cell 会自动显示选中状态，不需要手动设置

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 更新"下一步"按钮状态
    self.nextButton.enabled = tableView.indexPathsForSelectedRows.count > 0;

    // 如果全部选中，更新全选按钮状态
    if (tableView.indexPathsForSelectedRows.count == self.conversations.count) {
        self.isAllSelected = YES;
        [self.selectAllButton setTitle:@"取消全选" forState:UIControlStateNormal];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 更新"下一步"按钮状态
    self.nextButton.enabled = tableView.indexPathsForSelectedRows.count > 0;

    // 如果之前是全选状态，取消选中任何一个时更新全选按钮
    if (self.isAllSelected) {
        self.isAllSelected = NO;
        [self.selectAllButton setTitle:@"全选" forState:UIControlStateNormal];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - Helper Methods

- (NSString *)formatLastMessage:(WFCCMessage *)message {
    if (!message || !message.content) {
        return @"暂无消息";
    }

    NSString *text = [message digest];
    if (text.length == 0) {
        text = @"[消息]";
    }

    return text;
}

@end
