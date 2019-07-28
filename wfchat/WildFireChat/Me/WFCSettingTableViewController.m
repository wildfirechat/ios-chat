//
//  SettingTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCSettingTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCSecurityTableViewController.h"
#import "WFCAboutViewController.h"
#import "WFCPrivacyViewController.h"
#import "WFCPrivacyTableViewController.h"

@interface WFCSettingTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WFCPrivacyTableViewController *pvc = [[WFCPrivacyTableViewController alloc] init];
        pvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:pvc animated:YES];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
            mvc.conversation = [[WFCCConversation alloc] init];
            mvc.conversation.type = Single_Type;
            mvc.conversation.target = @"cgc8c8VV";
            mvc.conversation.line = 0;
        
            mvc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:mvc animated:YES];
        } else if (indexPath.row == 2) {
            WFCAboutViewController *avc = [[WFCAboutViewController alloc] init];
            [self.navigationController pushViewController:avc animated:YES];
        }
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = NO;
            [self.navigationController pushViewController:pvc animated:YES];
        } else if(indexPath.row == 1) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = YES;
            [self.navigationController pushViewController:pvc animated:YES];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 3;
    } else if (section == 2) {
        return 2;
    } else if (section == 3) {
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
    
    if(indexPath.section == 0) {
        cell.textLabel.text = @"隐私设置";
    } else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"当前版本";
            cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } if (indexPath.row == 1) {
            cell.textLabel.text = @"帮助与反馈";
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"关于野火IM";
        }
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"用户协议";
        } if (indexPath.row == 1) {
            cell.textLabel.text = @"隐私政策";
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"关于野火IM";
        }
    } else if (indexPath.section == 3) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"buttonCell"];
        for (UIView *subView in cell.subviews) {
            [subView removeFromSuperview];
        }
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        [btn setTitle:@"退出登录" forState:UIControlStateNormal];

        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:btn];
    }
    
    return cell;
}
 
- (void)onLogoutBtn:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
    [[WFCCNetworkService sharedInstance] disconnect:YES];
}
@end
