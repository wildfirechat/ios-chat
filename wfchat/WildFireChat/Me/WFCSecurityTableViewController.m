//
//  SettingTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCSecurityTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCChangePasswordViewController.h"
#import "WFCResetPasswordViewController.h"

@interface WFCSecurityTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCSecurityTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LocalizedString(@"AccountSafety");
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"style1Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"style1Cell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        cell.textLabel.text = LocalizedString(@"ChangePassword");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIAlertController* actionSheet = [UIAlertController alertControllerWithTitle:nil message:@"修改密码" preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self)ws = self;
    UIAlertAction *actionCode = [UIAlertAction actionWithTitle:@"短信验证码验证" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCResetPasswordViewController *vc = [[WFCResetPasswordViewController alloc] init];
        [ws.navigationController pushViewController:vc animated:YES];
    }];
    
    UIAlertAction *actionPwd = [UIAlertAction actionWithTitle:@"使用密码验证" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WFCChangePasswordViewController *vc = [[WFCChangePasswordViewController alloc] init];
        [ws.navigationController pushViewController:vc animated:YES];
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    [actionSheet addAction:actionCode];
    [actionSheet addAction:actionPwd];
    [actionSheet addAction:actionCancel];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

@end
