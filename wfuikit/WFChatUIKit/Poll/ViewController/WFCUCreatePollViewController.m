//
//  WFCUCreatePollViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCreatePollViewController.h"
#import "WFCUConfigManager.h"
#import "WFCUPoll.h"
#import "WFCUForwardViewController.h"
#import "MBProgressHUD.h"
#import "UIView+Toast.h"
#import "WFCUUtilities.h"
#import <WFChatClient/WFCChatClient.h>

#define MAX_OPTIONS 10
#define MIN_OPTIONS 2

typedef NS_ENUM(NSInteger, CreatePollSection) {
    CreatePollSectionBasic = 0,      // 标题、描述
    CreatePollSectionOptions = 1,    // 选项
    CreatePollSectionSettings = 2,   // 设置
    CreatePollSectionCount
};

@interface WFCUCreatePollViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;

// 数据
@property (nonatomic, strong) NSString *pollTitle;   // 投票标题
@property (nonatomic, strong) NSString *desc;        // 投票描述
@property (nonatomic, strong) NSMutableArray<NSString *> *options;
@property (nonatomic, assign) int visibility;      // 1=仅群内, 2=公开
@property (nonatomic, assign) int type;            // 1=单选, 2=多选
@property (nonatomic, assign) int maxSelect;
@property (nonatomic, assign) int anonymous;       // 0=实名, 1=匿名
@property (nonatomic, assign) long long endTime;

@end

@implementation WFCUCreatePollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupData];
    [self setupUI];
}

- (void)setupData {
    self.pollTitle = @"";
    self.desc = @"";
    self.options = [NSMutableArray arrayWithObjects:@"", @"", nil]; // 默认2个空选项
    self.visibility = 1;    // 默认仅群内
    self.type = 1;          // 默认单选
    self.maxSelect = 1;
    self.anonymous = 0;     // 默认实名
    self.endTime = 0;       // 默认无截止时间
}

- (void)setupUI {
    self.title = WFCString(@"CreatePoll");
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    
    // 导航栏按钮
    // 返回按钮（创建投票是被 push 的）
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onCancel:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem = backItem;
    
    UIBarButtonItem *publishItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Publish") style:UIBarButtonItemStyleDone target:self action:@selector(onPublish:)];
    self.navigationItem.rightBarButtonItem = publishItem;
    
    // TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    // 设置section header高度，让header更明显
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 30;
    [self.view addSubview:self.tableView];
}

#pragma mark - Actions

- (void)onCancel:(id)sender {
    // 返回上一个页面（投票首页）
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onPublish:(id)sender {
    // 校验
    if (self.pollTitle.length == 0) {
        [self.view makeToast:WFCString(@"PollTitleRequired") duration:2 position:CSToastPositionCenter];
        return;
    }
    
    // 过滤空选项
    NSMutableArray *validOptions = [NSMutableArray array];
    for (NSString *option in self.options) {
        NSString *trimmed = [option stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [validOptions addObject:trimmed];
        }
    }
    
    if (validOptions.count < MIN_OPTIONS) {
        [self.view makeToast:[NSString stringWithFormat:WFCString(@"PollOptionsRequired"), MIN_OPTIONS] duration:2 position:CSToastPositionCenter];
        return;
    }
    
    [self createPoll:validOptions];
}

- (void)createPoll:(NSArray *)options {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Publishing");
    
    id<WFCUPollService> service = [WFCUConfigManager globalManager].pollServiceProvider;
    if (!service) {
        [hud hideAnimated:YES];
        [self.view makeToast:WFCString(@"PollServiceNotConfigured") duration:2 position:CSToastPositionCenter];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [service createPoll:self.groupId
                  title:self.pollTitle
            description:self.desc
                options:options
             visibility:self.visibility
                   type:self.type
              maxSelect:self.maxSelect
              anonymous:self.anonymous
                endTime:self.endTime
             showResult:0
                success:^(WFCUPoll *poll) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            
            // 判断是否是公开投票
            if (weakSelf.visibility == 2) {
                // 公开投票：提示是否转发
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"PollCreated") message:WFCString(@"ForwardPublicPollTip") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"No") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    // 不转发，直接关闭
                    [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Forward") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // 显示转发界面
                    [weakSelf showForwardPoll:poll];
                }]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            } else {
                // 群内投票：提示已发送到本群
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"PollCreated") message:WFCString(@"PollSentToGroup") preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                }]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        });
    } error:^(int errorCode, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [weakSelf.view makeToast:message ?: WFCString(@"Failed") duration:2 position:CSToastPositionCenter];
        });
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CreatePollSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CreatePollSectionBasic:
            return 2; // 标题、描述
        case CreatePollSectionOptions:
            return self.options.count + 1; // 选项 + 添加按钮
        case CreatePollSectionSettings:
            return 4; // 单/多选、匿名、截止时间、可见性
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CreatePollSectionBasic) {
        return [self cellForBasicSection:tableView indexPath:indexPath];
    } else if (indexPath.section == CreatePollSectionOptions) {
        return [self cellForOptionsSection:tableView indexPath:indexPath];
    } else {
        return [self cellForSettingsSection:tableView indexPath:indexPath];
    }
}

- (UITableViewCell *)cellForBasicSection:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    NSString *cellId = indexPath.row == 0 ? @"TitleCell" : @"DescCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(16, 0, cell.bounds.size.width - 32, 44)];
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textField.tag = 100;
        [cell.contentView addSubview:textField];
        
        if (indexPath.row == 0) {
            textField.placeholder = WFCString(@"PollTitlePlaceholder");
            [textField addTarget:self action:@selector(titleChanged:) forControlEvents:UIControlEventEditingChanged];
        } else {
            textField.placeholder = WFCString(@"PollDescPlaceholder");
            [textField addTarget:self action:@selector(descChanged:) forControlEvents:UIControlEventEditingChanged];
        }
    }
    
    UITextField *textField = [cell.contentView viewWithTag:100];
    if (indexPath.row == 0) {
        textField.text = self.pollTitle;
    } else {
        textField.text = self.desc;
    }
    
    return cell;
}

- (UITableViewCell *)cellForOptionsSection:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.options.count) {
        // 添加选项按钮
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddCell"];
            cell.textLabel.textColor = [UIColor systemBlueColor];
        }
        cell.textLabel.text = WFCString(@"AddOption");
        return cell;
    }
    
    // 选项输入 - 每个cell用独立的identifier，避免重用问题
    NSString *cellId = [NSString stringWithFormat:@"OptionCell_%ld", (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(16, 0, cell.bounds.size.width - 60, 44)];
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        textField.tag = 100;
        textField.placeholder = WFCString(@"OptionPlaceholder");
        [textField addTarget:self action:@selector(optionChanged:) forControlEvents:UIControlEventEditingChanged];
        [cell.contentView addSubview:textField];
        
        UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        deleteBtn.frame = CGRectMake(cell.bounds.size.width - 44, 7, 30, 30);
        deleteBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        deleteBtn.tag = 101;
        [deleteBtn setTitle:@"×" forState:UIControlStateNormal];
        deleteBtn.titleLabel.font = [UIFont systemFontOfSize:24];
        [deleteBtn addTarget:self action:@selector(deleteOption:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:deleteBtn];
    }
    
    UITextField *textField = [cell.contentView viewWithTag:100];
    textField.text = self.options[indexPath.row];
    // 使用accessibilityIdentifier存储row索引，不修改tag
    textField.accessibilityIdentifier = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    
    UIButton *deleteBtn = [cell.contentView viewWithTag:101];
    deleteBtn.accessibilityIdentifier = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    deleteBtn.hidden = self.options.count <= MIN_OPTIONS; // 最少保留2个
    
    return cell;
}

- (UITableViewCell *)cellForSettingsSection:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SettingCell"];
    }
    
    switch (indexPath.row) {
        case 0: // 单/多选
            cell.textLabel.text = WFCString(@"PollType");
            cell.detailTextLabel.text = self.type == 1 ? WFCString(@"SingleChoice") : WFCString(@"MultipleChoice");
            break;
        case 1: // 匿名
            cell.textLabel.text = WFCString(@"AnonymousPoll");
            cell.accessoryView = [self switchForAnonymous];
            break;
        case 2: // 截止时间
            cell.textLabel.text = WFCString(@"EndTime");
            cell.detailTextLabel.text = self.endTime > 0 ? [self formatTime:self.endTime] : WFCString(@"NoEndTime");
            break;
        case 3: // 可见性
            cell.textLabel.text = WFCString(@"Visibility");
            cell.detailTextLabel.text = self.visibility == 1 ? WFCString(@"GroupOnly") : WFCString(@"Public");
            break;
    }
    
    return cell;
}

- (UISwitch *)switchForAnonymous {
    UISwitch *switchView = [[UISwitch alloc] init];
    switchView.on = self.anonymous == 1;
    [switchView addTarget:self action:@selector(anonymousChanged:) forControlEvents:UIControlEventValueChanged];
    return switchView;
}

- (NSString *)formatTime:(long long)time {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time / 1000.0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM-dd HH:mm";
    return [formatter stringFromDate:date];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == CreatePollSectionOptions && indexPath.row == self.options.count) {
        // 添加选项
        if (self.options.count >= MAX_OPTIONS) {
            [self.view makeToast:[NSString stringWithFormat:WFCString(@"MaxOptionsLimit"), MAX_OPTIONS] duration:2 position:CSToastPositionCenter];
            return;
        }
        [self.options addObject:@""];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CreatePollSectionOptions] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (indexPath.section == CreatePollSectionSettings) {
        [self handleSettingTap:indexPath.row];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CreatePollSectionBasic:
            return WFCString(@"PollDescription");  // 投票描述
        case CreatePollSectionOptions:
            return WFCString(@"PollOptions");
        case CreatePollSectionSettings:
            return WFCString(@"PollSettings");
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == CreatePollSectionOptions) {
        return [NSString stringWithFormat:WFCString(@"OptionsTip"), MIN_OPTIONS, MAX_OPTIONS];
    }
    return nil;
}

#pragma mark - Actions

- (void)titleChanged:(UITextField *)textField {
    self.pollTitle = textField.text;
}

- (void)descChanged:(UITextField *)textField {
    self.desc = textField.text;
}

- (void)optionChanged:(UITextField *)textField {
    int index = [textField.accessibilityIdentifier intValue];
    if (index >= 0 && index < self.options.count) {
        self.options[index] = textField.text;
    }
}

- (void)deleteOption:(UIButton *)button {
    int index = [button.accessibilityIdentifier intValue];
    if (index >= 0 && index < self.options.count && self.options.count > MIN_OPTIONS) {
        [self.options removeObjectAtIndex:index];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CreatePollSectionOptions] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)anonymousChanged:(UISwitch *)switchView {
    self.anonymous = switchView.on ? 1 : 0;
}

- (void)handleSettingTap:(NSInteger)row {
    if (row == 0) {
        // 切换单/多选
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"SelectPollType") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"SingleChoice") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.type = 1;
            self.maxSelect = 1;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"MultipleChoice") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.type = 2;
            self.maxSelect = (int)self.options.count; // 默认不限制
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (row == 2) {
        // 选择截止时间
        [self showDatePicker];
    } else if (row == 3) {
        // 切换可见性
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"SelectVisibility") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"GroupOnly") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.visibility = 1;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Public") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.visibility = 2;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showDatePicker {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"SelectEndTime") message:@"\n\n\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.minimumDate = [NSDate date];
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    datePicker.frame = CGRectMake(0, 50, alert.view.bounds.size.width - 16, 200);
    [alert.view addSubview:datePicker];
    
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.endTime = (long long)([datePicker.date timeIntervalSince1970] * 1000);
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"NoEndTime") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.endTime = 0;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:CreatePollSectionSettings]] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showForwardPoll:(WFCUPoll *)poll {
    // 先关闭创建投票界面
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        // 构建投票消息内容
        WFCCPollMessageContent *content = [[WFCCPollMessageContent alloc] init];
        content.pollId = [NSString stringWithFormat:@"%lld", poll.pollId];
        content.groupId = poll.groupId ?: @"";
        content.creatorId = poll.creatorId;
        content.title = poll.title;
        content.desc = poll.desc;
        content.visibility = poll.visibility;
        content.type = poll.type;
        content.anonymous = poll.anonymous;
        content.status = poll.status;
        content.endTime = poll.endTime;
        content.totalVotes = poll.totalVotes;
        
        // 构建消息对象
        WFCCMessage *message = [[WFCCMessage alloc] init];
        message.content = content;
        message.conversation = [[WFCCConversation alloc] init];
        message.conversation.type = Group_Type;
        message.conversation.target = poll.groupId ?: @"";
        message.conversation.line = 0;
        
        // 创建转发控制器
        WFCUForwardViewController *forwardVC = [[WFCUForwardViewController alloc] init];
        forwardVC.message = message;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:forwardVC];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        
        // 获取根视图控制器来 present
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:nav animated:YES completion:nil];
    }];
}

@end
