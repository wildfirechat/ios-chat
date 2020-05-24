//
//  WFCPrivacyTableViewController.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCPrivacyTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>


@interface WFCPrivacyTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCPrivacyTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
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
        WFCUBlackListViewController *vc = [[WFCUBlackListViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if(indexPath.section == 2) {
        UIViewController *vc = [[NSClassFromString(@"MomentSettingsTableViewController") alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (NSClassFromString(@"MomentSettingsTableViewController")) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if(section == 1) {
        return 1;
    } else if(section == 2) {
       return 1;
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"style1Cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"style1Cell"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if(indexPath.section == 2) {
            cell.textLabel.text = LocalizedString(@"Moments");
        } else {
            cell.textLabel.text = LocalizedString(@"Blacklist");
        }
        return cell;;
    } else if(indexPath.section == 1) {
        WFCUGeneralSwitchTableViewCell *switchCell = [[WFCUGeneralSwitchTableViewCell alloc] init];
        switchCell.textLabel.text = LocalizedString(@"MsgReceipt");
        if ([[WFCCIMService sharedWFCIMService] isUserEnableReceipt]) {
            switchCell.on = YES;
        } else {
            switchCell.on = NO;
        }
        __weak typeof(self)ws = self;
        [switchCell setOnSwitch:^(BOOL value, void (^result)(BOOL success)) {
            [[WFCCIMService sharedWFCIMService] setUserEnableReceipt:value success:^{
                result(YES);
            } error:^(int error_code) {
                [ws.view makeToast:@"网络错误"];
                result(NO);
            }];
        }];
        
        return switchCell;
    }
    return nil;
}

@end
