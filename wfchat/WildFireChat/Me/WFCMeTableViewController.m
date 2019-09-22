//
//  MeTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/4.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCMeTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCSettingTableViewController.h"
#import "WFCSecurityTableViewController.h"
#import "WFCMeTableViewCell.h"

@interface WFCMeTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UIImageView *portraitView;
@end

@implementation WFCMeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableHeaderView = nil;
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:note.object]) {
            [ws.tableView reloadData];
        }
    }];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 2;
    } else if (section == 2) {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        WFCMeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
        if (cell == nil) {
            cell = [[WFCMeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"profileCell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:YES];
        cell.userInfo = me;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"styleDefault"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"styleDefault"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                cell.textLabel.text = LocalizedString(@"AccountSafety");
                cell.imageView.image = [UIImage imageNamed:@"safe_setting"];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = LocalizedString(@"MessageNotification");
                cell.imageView.image = [UIImage imageNamed:@"notification_setting"];
            }
        } else if(indexPath.section == 2) {
            cell.textLabel.text = LocalizedString(@"Settings");
            cell.imageView.image = [UIImage imageNamed:@"MoreSetting"];
        }

        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 68;
    } else {
        return 48;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WFCUMyProfileTableViewController *vc = [[WFCUMyProfileTableViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            WFCSecurityTableViewController * stvc = [[WFCSecurityTableViewController alloc] init];
            stvc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:stvc animated:YES];
        } else if(indexPath.row == 1) {
            WFCUMessageNotificationViewController *mnvc = [[WFCUMessageNotificationViewController alloc] init];
            mnvc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:mnvc animated:YES];
        }
    } else if(indexPath.section == 2)  {
        WFCSettingTableViewController *vc = [[WFCSettingTableViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
