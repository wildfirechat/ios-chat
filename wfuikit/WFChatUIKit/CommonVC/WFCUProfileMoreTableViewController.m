//
//  WFCUProfileMoreTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/22.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUProfileMoreTableViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "WFCUMessageListViewController.h"
#import "MBProgressHUD.h"
#import "WFCUMyPortraitViewController.h"
#import "WFCUVerifyRequestViewController.h"
#import "WFCUGeneralModifyViewController.h"
#import "WFCUVideoViewController.h"
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#endif
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUConfigManager.h"
#import "WFCUUserMessageListViewController.h"
#import "WFCUImage.h"
#import "WFCUGroupTableViewController.h"
#import <MessageUI/MessageUI.h>


@interface WFCUProfileMoreTableViewController () <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>


@property (strong, nonatomic)UITableViewCell *commonGroupCell;
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UITableViewCell *> *cells;
@property (nonatomic, strong)WFCCUserInfo *userInfo;
@property (nonatomic, strong)UITableViewCell *emailCell; // 邮箱 cell
@end

@implementation WFCUProfileMoreTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = WFCString(@"More");
    self.userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:YES];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
    [keyWindow tintColorDidChange];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)loadData {
    self.cells = [[NSMutableArray alloc] init];

    if (self.userInfo.mobile.length > 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.text = @"电话";
        cell.detailTextLabel.text = self.userInfo.mobile;
        [self.cells addObject:cell];
    }

    if (self.userInfo.email.length > 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.text = @"邮箱";
        cell.detailTextLabel.text = self.userInfo.email;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; // 添加箭头表示可点击
        self.emailCell = cell; // 保存邮箱 cell 的引用
        [self.cells addObject:cell];
    }

    if (self.userInfo.address.length) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.text = @"地址";
        cell.detailTextLabel.text = self.userInfo.address;
        [self.cells addObject:cell];
    }

    if (self.userInfo.company.length) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.text = @"公司";
        cell.detailTextLabel.text = self.userInfo.company;
        [self.cells addObject:cell];
    }

    if (self.userInfo.social.length) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.textLabel.text = @"社交账号";
        cell.detailTextLabel.text = self.userInfo.social;
        [self.cells addObject:cell];
    }

    [self.tableView reloadData];
}

- (UITableViewCell *)commonGroupCell {
    if(!_commonGroupCell) {
        _commonGroupCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"common_group"];
        _commonGroupCell.textLabel.text = @"我和他的共同群组";
        _commonGroupCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld个", self.commonGroupIds.count];
        _commonGroupCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return _commonGroupCell;
}

- (void)setCommonGroupIds:(NSArray<NSString *> *)commonGroupIds {
    _commonGroupIds = commonGroupIds;
    self.commonGroupCell.detailTextLabel.text = [NSString stringWithFormat:@"%ld个", commonGroupIds.count];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource<NSObject>
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    }
    
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"section:%ld",(long)indexPath.section);
    if (indexPath.section == 0) {
        return self.commonGroupCell;
    } else {
        return self.cells[indexPath.row];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.cells.count) {
        return 2;
    } else {
        return 1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 10)];
        view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return view;
    } else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 10;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];

    if(selectedCell == self.commonGroupCell) {
        WFCUGroupTableViewController *groupsVC = [[WFCUGroupTableViewController alloc] init];
        groupsVC.groupIds = self.commonGroupIds;
        groupsVC.titleString = @"我和他的共同群组";
        [self.navigationController pushViewController:groupsVC animated:YES];
    } else if (selectedCell == self.emailCell) {
        // 点击邮箱 cell，发送邮件
        [self sendEmailTo:self.userInfo.email];
    }

    // 取消选中状态
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// 发送邮件
- (void)sendEmailTo:(NSString *)email {
    if (!email || email.length == 0) {
        return;
    }

    // 检查设备是否支持发送邮件
    if ([MFMailComposeViewController canSendMail]) {
        // 使用 MFMailComposeViewController
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        [mailComposeVC setToRecipients:@[email]];

        [self presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        // 如果不支持，使用 mailto: URL scheme
        NSString *emailString = [NSString stringWithFormat:@"mailto:%@", email];
        NSURL *emailURL = [NSURL URLWithString:emailString];

        if ([[UIApplication sharedApplication] canOpenURL:emailURL]) {
            [[UIApplication sharedApplication] openURL:emailURL options:@{} completionHandler:nil];
        } else {
            // 如果都无法发送，显示提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                           message:@"您的设备不支持发送邮件"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"邮件已发送");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"邮件已保存");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"邮件已取消");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"邮件发送失败: %@", error.localizedDescription);
            break;
        default:
            break;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
@end
