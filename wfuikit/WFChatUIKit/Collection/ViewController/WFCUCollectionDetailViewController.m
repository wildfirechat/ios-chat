//
//  WFCUCollectionDetailViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCollectionDetailViewController.h"
#import "WFCUUtilities.h"
#import "WFCUConfigManager.h"
#import "WFCUCollection.h"
#import "MBProgressHUD.h"
#import "UIView+Toast.h"
#import "WFCUImage.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>

#define HEADER_HEIGHT 120
#define ENTRY_CELL_HEIGHT 50
#define EDIT_CELL_HEIGHT 50

@interface WFCUCollectionEntryCell : UITableViewCell
@property (nonatomic, strong) UIView *indexCircleView;
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UILabel *contentLabel;
- (void)setIndex:(int)index content:(NSString *)content;
@end

@implementation WFCUCollectionEntryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    // 序号圆圈背景
    self.indexCircleView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 28, 28)];
    self.indexCircleView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.indexCircleView.layer.cornerRadius = 14;
    self.indexCircleView.layer.borderWidth = 1;
    self.indexCircleView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    [self.contentView addSubview:self.indexCircleView];

    // 序号
    self.indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    self.indexLabel.font = [UIFont systemFontOfSize:12];
    self.indexLabel.textColor = [UIColor darkGrayColor];
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    [self.indexCircleView addSubview:self.indexLabel];

    // 内容
    self.contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 14, self.contentView.bounds.size.width - 66, 20)];
    self.contentLabel.font = [UIFont systemFontOfSize:14];
    self.contentLabel.textColor = [UIColor blackColor];
    self.contentLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentView addSubview:self.contentLabel];
}

- (void)setIndex:(int)index content:(NSString *)content {
    self.indexLabel.text = [NSString stringWithFormat:@"%d", index];
    self.contentLabel.text = content;
}

@end

#pragma mark - Edit Entry Cell

@interface WFCUCollectionEditCell : UITableViewCell <UITextFieldDelegate>
@property (nonatomic, strong) UIView *indexCircleView;
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UITextField *contentTextField;
@property (nonatomic, assign) BOOL isMyEntry;
@property (nonatomic, copy) NSString *originalContent;
@property (nonatomic, copy) NSString *autoFillContent;
@property (nonatomic, copy) void (^onContentChanged)(NSString *content);
- (void)setIndex:(int)index placeholder:(NSString *)placeholder isMyEntry:(BOOL)isMyEntry content:(NSString *)content;
- (NSString *)getContent;
- (void)focusTextField;
- (BOOL)hasContentChanged;
@end

@implementation WFCUCollectionEditCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    // 序号圆圈背景
    self.indexCircleView = [[UIView alloc] initWithFrame:CGRectMake(10, 11, 28, 28)];
    self.indexCircleView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    self.indexCircleView.layer.cornerRadius = 14;
    self.indexCircleView.layer.borderWidth = 1;
    self.indexCircleView.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    [self.contentView addSubview:self.indexCircleView];

    // 序号
    self.indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    self.indexLabel.font = [UIFont systemFontOfSize:12];
    self.indexLabel.textColor = [UIColor darkGrayColor];
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    [self.indexCircleView addSubview:self.indexLabel];

    // 内容输入框（占据剩余空间，无按钮）
    self.contentTextField = [[UITextField alloc] initWithFrame:CGRectMake(50, 8, self.contentView.bounds.size.width - 66, 34)];
    self.contentTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.contentTextField.font = [UIFont systemFontOfSize:14];
    self.contentTextField.delegate = self;
    self.contentTextField.returnKeyType = UIReturnKeyDone;
    self.contentTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.contentTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.contentView addSubview:self.contentTextField];
}

- (void)setIndex:(int)index placeholder:(NSString *)placeholder isMyEntry:(BOOL)isMyEntry content:(NSString *)content {
    self.isMyEntry = isMyEntry;
    self.indexLabel.text = [NSString stringWithFormat:@"%d", index];
    self.contentTextField.placeholder = placeholder;
    self.contentTextField.text = content ?: @"";
    // 保存原始内容用于比较
    self.originalContent = content ?: @"";
}

- (NSString *)getContent {
    return self.contentTextField.text ?: @"";
}

- (void)setAutoFillContent:(NSString *)autoFillContent {
    self.contentTextField.text = autoFillContent ?: @"";
    _autoFillContent = autoFillContent?:@"";
}

- (void)focusTextField {
    [self.contentTextField becomeFirstResponder];
}

- (BOOL)hasContentChanged {
    NSString *currentContent = self.contentTextField.text ?: @"";
    return ![currentContent isEqualToString:self.originalContent] && ![currentContent isEqualToString:self.autoFillContent];
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (self.onContentChanged) {
        self.onContentChanged(textField.text ?: @"");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

@end

#pragma mark - Main ViewController

@interface WFCUCollectionDetailViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerView;

// Header 控件
@property (nonatomic, strong) UIImageView *creatorAvatarView;
@property (nonatomic, strong) UILabel *creatorLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *templateLabel;

// 数据
@property (nonatomic, strong) WFCUCollection *collection;
@property (nonatomic, assign) long collectionId;
@property (nonatomic, strong) NSString *groupId;
@property (nonatomic, assign) BOOL hasJoined;
@property (nonatomic, assign) BOOL isCreator;
@property (nonatomic, strong) NSString *myEntryContent;
@property (nonatomic, assign) NSInteger myEntryIndex;

// 编辑 cell 引用
@property (nonatomic, weak) WFCUCollectionEditCell *editCell;

// 导航栏按钮
@property (nonatomic, strong) UIBarButtonItem *submitItem;

@end

@implementation WFCUCollectionDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupData];
    [self setupUI];

    // 从服务器获取接龙详情
    [self fetchCollectionDetail];
}

- (void)setupData {
    // 从消息中获取接龙ID和群ID
    WFCCCollectionMessageContent *content = (WFCCCollectionMessageContent *)self.message.content;
    self.collectionId = [content.collectionId longLongValue];
    self.groupId = self.message.conversation.target;

    // 初始化默认值
    self.hasJoined = NO;
    self.isCreator = NO;
    self.myEntryIndex = -1;
    self.myEntryContent = nil;
}

- (void)setupUI {
    self.title = WFCString(@"CollectionDetail");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

    // 导航栏按钮
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Close") style:UIBarButtonItemStylePlain target:self action:@selector(onClose:)];
    self.navigationItem.leftBarButtonItem = closeItem;

    // 右侧提交按钮
    self.submitItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Submit") style:UIBarButtonItemStyleDone target:self action:@selector(onNavSubmit:)];
    self.navigationItem.rightBarButtonItem = self.submitItem;

    // 创建 TableView
    CGFloat tableHeight = self.view.bounds.size.height - [WFCUUtilities wf_navigationFullHeight] - [WFCUUtilities wf_safeDistanceBottom];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [WFCUUtilities wf_navigationFullHeight], self.view.bounds.size.width, tableHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.tableHeaderView = [self createHeaderView];
    [self.view addSubview:self.tableView];

    // 注册 Cell
    [self.tableView registerClass:[WFCUCollectionEntryCell class] forCellReuseIdentifier:@"EntryCell"];
    [self.tableView registerClass:[WFCUCollectionEditCell class] forCellReuseIdentifier:@"EditCell"];
}

- (UIView *)createHeaderView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor whiteColor];

    CGFloat margin = 16;
    CGFloat currentY = 16;

    // 创建者信息区域（头像 + 文字）
    self.creatorAvatarView = [[UIImageView alloc] initWithFrame:CGRectMake(margin, currentY, 36, 36)];
    self.creatorAvatarView.layer.cornerRadius = 18;
    self.creatorAvatarView.layer.masksToBounds = YES;
    self.creatorAvatarView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [headerView addSubview:self.creatorAvatarView];

    self.creatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin + 44, currentY + 8, headerView.bounds.size.width - margin * 2 - 44, 20)];
    self.creatorLabel.font = [UIFont systemFontOfSize:13];
    self.creatorLabel.textColor = [UIColor grayColor];
    [headerView addSubview:self.creatorLabel];
    currentY += 44;


    // 标题
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, currentY, headerView.bounds.size.width - margin * 2, 22)];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.numberOfLines = 0;
    [headerView addSubview:self.titleLabel];
    currentY += 26;

    // 描述
    self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, currentY, headerView.bounds.size.width - margin * 2, 18)];
    self.descLabel.font = [UIFont systemFontOfSize:14];
    self.descLabel.textColor = [UIColor grayColor];
    self.descLabel.numberOfLines = 2;
    [headerView addSubview:self.descLabel];
    currentY += 22;

    // 模板
    self.templateLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, currentY, headerView.bounds.size.width - margin * 2, 16)];
    self.templateLabel.font = [UIFont systemFontOfSize:12];
    self.templateLabel.textColor = [UIColor systemBlueColor];
    [headerView addSubview:self.templateLabel];
    currentY += 20;

    // 调整 header 高度
    CGRect frame = headerView.frame;
    frame.size.height = currentY;
    headerView.frame = frame;

    return headerView;
}

- (void)refreshUI {
    if (!self.collection) {
        return;
    }

    // 刷新 Header 数据
    // 创建者信息
    WFCCUserInfo *creatorInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.collection.creatorId refresh:NO];
    NSString *creatorName = creatorInfo.displayName ?: creatorInfo.name ?: self.collection.creatorId;
    self.creatorLabel.text = [NSString stringWithFormat:WFCString(@"CollectionCreatorInfo"), creatorName, self.collection.participantCount];
    // 加载头像
    if (creatorInfo.portrait.length > 0) {
        [self.creatorAvatarView sd_setImageWithURL:[NSURL URLWithString:[creatorInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    } else {
        self.creatorAvatarView.image = [WFCUImage imageNamed:@"PersonalChat"];
    }

    self.titleLabel.text = self.collection.title;

    if (self.collection.desc.length > 0) {
        self.descLabel.text = self.collection.desc;
        self.descLabel.hidden = NO;
    } else {
        self.descLabel.hidden = YES;
    }

    if (self.collection.template.length > 0) {
        self.templateLabel.text = [NSString stringWithFormat:@"%@: %@", WFCString(@"Template"), self.collection.template];
        self.templateLabel.hidden = NO;
    } else {
        self.templateLabel.hidden = YES;
    }

    // 刷新表格
    [self.tableView reloadData];

    // 延迟更新提交按钮状态（等 cell 创建完成后）
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSubmitButtonState];
    });
}

- (void)updateSubmitButtonState {
    if (!self.editCell) {
        return;
    }

    // 检查内容是否有变化
    BOOL hasChanged = [self.editCell hasContentChanged];

    // 已参与且内容为空时也可以提交（表示删除）
    NSString *currentContent = [self.editCell getContent];
    NSString *trimmedContent = [currentContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL canSubmit = hasChanged || (self.hasJoined && trimmedContent.length == 0 && self.myEntryContent.length > 0);

    self.submitItem.enabled = canSubmit;
    if (canSubmit) {
        self.submitItem.tintColor = [UIColor systemBlueColor];
    } else {
        self.submitItem.tintColor = [UIColor lightGrayColor];
    }
}

#pragma mark - Actions

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onNavSubmit:(id)sender {
    // 从编辑 cell 获取内容
    NSString *content = [self.editCell getContent];
    NSString *trimmedContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (self.hasJoined) {
        // 已参与的条目
        if (trimmedContent.length == 0) {
            // 内容为空，执行删除
            [self confirmDeleteEntry:self.collectionId groupId:self.groupId];
        } else {
            // 有内容，执行更新
            [self updateEntry:self.collectionId groupId:self.groupId content:trimmedContent];
        }
    } else {
        // 新参与
        if (trimmedContent.length == 0) {
            [self.view makeToast:WFCString(@"ContentRequired") duration:2 position:CSToastPositionCenter];
            return;
        }
        [self joinCollection:self.collectionId groupId:self.groupId content:trimmedContent];
    }
}

- (void)scrollToMyEntry {
    if (self.myEntryIndex >= 0 && self.collection.status == 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.myEntryIndex inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (void)fetchCollectionDetail {
    id<WFCUCollectionService> service = [WFCUConfigManager globalManager].collectionServiceProvider;
    if (!service) {
        [self.view makeToast:WFCString(@"CollectionServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }

    // 显示加载提示
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");

    __weak typeof(self) weakSelf = self;
    [service getCollection:self.collectionId
                   groupId:self.groupId
                   success:^(WFCUCollection *collection) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            // 更新本地数据
            [weakSelf updateWithCollection:collection];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)updateWithCollection:(WFCUCollection *)collection {
    self.collection = collection;

    // 重新检查参与状态
    NSString *currentUserId = [WFCCNetworkService sharedInstance].userId;
    self.hasJoined = NO;
    self.myEntryIndex = -1;
    self.myEntryContent = nil;

    for (int i = 0; i < collection.entries.count; i++) {
        WFCUCollectionEntry *entry = collection.entries[i];
        if ([entry.userId isEqualToString:currentUserId]) {
            self.hasJoined = YES;
            self.myEntryIndex = i;
            self.myEntryContent = entry.content;
            break;
        }
    }

    // 检查是否是创建者
    self.isCreator = [collection.creatorId isEqualToString:currentUserId];

    // 刷新 UI
    [self refreshUI];

    // 延迟滚动到自己的行，聚焦输入框，并填入 displayname（如果内容为空）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToMyEntry];

        // 如果内容为空，填入当前用户的 displayname（不带空格）
        if (!self.hasJoined || self.myEntryContent.length == 0) {
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:currentUserId refresh:NO];
            NSString *displayName = userInfo.displayName ?: userInfo.name ?: currentUserId;
            NSString *content = [displayName stringByAppendingString:@" "];
            self.editCell.autoFillContent = content;
        }

        // 聚焦输入框
        [self.editCell focusTextField];

        // 更新提交按钮状态
        [self updateSubmitButtonState];
    });
}

- (void)joinCollection:(long)collectionId groupId:(NSString *)groupId content:(NSString *)content {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");

    id<WFCUCollectionService> service = [WFCUConfigManager globalManager].collectionServiceProvider;
    if (!service) {
        [hud hideAnimated:YES];
        [self.view makeToast:WFCString(@"CollectionServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [service joinOrUpdateCollection:collectionId
                            groupId:groupId
                            content:content
                            success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"Success") duration:1 position:CSToastPositionCenter];
            // 关闭页面
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            NSString *errorMsg = message;
            if (errorCode == 3003) {
                errorMsg = WFCString(@"NotInGroup");
            }
            [weakSelf.view makeToast:errorMsg ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)updateEntry:(long)collectionId groupId:(NSString *)groupId content:(NSString *)content {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");

    id<WFCUCollectionService> service = [WFCUConfigManager globalManager].collectionServiceProvider;
    if (!service) {
        [hud hideAnimated:YES];
        [self.view makeToast:WFCString(@"CollectionServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [service joinOrUpdateCollection:collectionId
                            groupId:groupId
                            content:content
                            success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"Success") duration:1 position:CSToastPositionCenter];
            // 关闭页面
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            NSString *errorMsg = message;
            if (errorCode == 3003) {
                errorMsg = WFCString(@"NotInGroup");
            }
            [weakSelf.view makeToast:errorMsg ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

- (void)confirmDeleteEntry:(long)collectionId groupId:(NSString *)groupId {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Confirm") message:WFCString(@"ConfirmDeleteEntry") preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];

    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf doDeleteEntry:collectionId groupId:groupId];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)doDeleteEntry:(long)collectionId groupId:(NSString *)groupId {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Loading");

    id<WFCUCollectionService> service = [WFCUConfigManager globalManager].collectionServiceProvider;
    if (!service) {
        [hud hideAnimated:YES];
        [self.view makeToast:WFCString(@"CollectionServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [service deleteCollectionEntry:collectionId groupId:groupId success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:WFCString(@"Success") duration:1 position:CSToastPositionCenter];
            // 关闭页面
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            NSString *errorMsg = message;
            if (errorCode == 3003) {
                errorMsg = WFCString(@"NotInGroup");
            }
            [weakSelf.view makeToast:errorMsg ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.collection || self.collection.status != 0) {
        // 接龙已结束或无数据，不显示编辑行
        return self.collection ? self.collection.entries.count : 0;
    }

    // 接龙进行中，多一行用于编辑
    if (self.hasJoined) {
        return self.collection.entries.count; // 用替换的方式显示编辑框
    } else {
        return self.collection.entries.count + 1; // 多一行用于新参与
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLastRow = indexPath.row == [self tableView:tableView numberOfRowsInSection:0] - 1;
    BOOL isEditRow = NO;

    if (self.collection && self.collection.status == 0) {
        // 接龙进行中
        if (self.hasJoined) {
            // 已参与：自己的那一行显示为编辑框
            isEditRow = (indexPath.row == self.myEntryIndex);
        } else {
            // 未参与：最后一行显示为编辑框
            isEditRow = isLastRow;
        }
    }

    if (isEditRow) {
        // 编辑行
        WFCUCollectionEditCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell" forIndexPath:indexPath];

        NSString *placeholder = self.collection.template.length > 0 ? self.collection.template : WFCString(@"JoinPlaceholder");
        NSString *content = self.hasJoined ? self.myEntryContent : @"";
        int displayIndex = (int)indexPath.row + 1;

        [cell setIndex:displayIndex placeholder:placeholder isMyEntry:self.hasJoined content:content];

        // 保存引用
        self.editCell = cell;

        // 设置内容变化回调
        __weak typeof(self) weakSelf = self;
        cell.onContentChanged = ^(NSString *content) {
            [weakSelf updateSubmitButtonState];
        };

        return cell;
    } else {
        // 普通展示行
        WFCUCollectionEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EntryCell" forIndexPath:indexPath];

        WFCUCollectionEntry *entry = self.collection.entries[indexPath.row];
        [cell setIndex:(int)indexPath.row + 1 content:entry.content];

        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isLastRow = indexPath.row == [self tableView:tableView numberOfRowsInSection:0] - 1;
    BOOL isEditRow = NO;

    if (self.collection && self.collection.status == 0) {
        if (self.hasJoined) {
            isEditRow = (indexPath.row == self.myEntryIndex);
        } else {
            isEditRow = isLastRow;
        }
    }

    return isEditRow ? EDIT_CELL_HEIGHT : ENTRY_CELL_HEIGHT;
}

@end
