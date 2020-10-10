//
//  SettingTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/6.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCSettingTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCSecurityTableViewController.h"
#import "WFCAboutViewController.h"
#import "WFCPrivacyViewController.h"
#import "WFCPrivacyTableViewController.h"
#import "WFCDiagnoseViewController.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCThemeTableViewController.h"
#import "AppService.h"


@interface WFCSettingTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@end

@implementation WFCSettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.title = LocalizedString(@"Settings");
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0.1)];
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
    }else if(indexPath.section == 1) {
        WFCThemeTableViewController *vc = [[WFCThemeTableViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.section == 2) {
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
    } else if(indexPath.section == 3) {
        if (indexPath.row == 0) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = NO;
            [self.navigationController pushViewController:pvc animated:YES];
        } else if(indexPath.row == 1) {
            WFCPrivacyViewController * pvc = [[WFCPrivacyViewController alloc] init];
            pvc.isPrivacy = YES;
            [self.navigationController pushViewController:pvc animated:YES];
        }
    } else if(indexPath.section == 4) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"举报" message:@"如果您发现有违反法律和道德的内容，或者您的合法权益受到侵犯，请截图之后发送给我们。我们会在24小时之内处理。处理办法包括不限于删除内容，对作者进行警告，冻结账号，甚至报警处理。举报请到\"设置->设置->举报\"联系我们！" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }];
        [alertController addAction:action1];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
            mvc.conversation = [[WFCCConversation alloc] init];
            mvc.conversation.type = Single_Type;
            mvc.conversation.target = @"cgc8c8VV";
            mvc.conversation.line = 0;
            
            mvc.hidesBottomBarWhenPushed = YES;
            [ws.navigationController pushViewController:mvc animated:YES];
        }];
        [alertController addAction:action2];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (indexPath.section == 5) {
        WFCDiagnoseViewController *vc = [[WFCDiagnoseViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0.01;
    } else {
        return 9;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else {
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 9)];
        v.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return v;
    }

}

//#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1; //
    } else if (section == 2) {
        return 3; //
    } else if (section == 3) {
        return 2; // 用户协议和隐私声明
    } else if (section == 4) {
        return 1; //举报
    } else if (section == 5) {
        return 1; //diagnose
    } else if (section == 6) {
        return 1; //logout
    }
    return 0;
}


- (UIEdgeInsets)hiddenSeparatorLine:(UITableViewCell *)cell {
    return cell.separatorInset = UIEdgeInsetsMake(self.view.frame.size.width, 0, 0, 0);
}

- (void)showSeparatorLine:(UITableViewCell *)cell {
    cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
}

- (void)setLastCellSeperatorToLeft:(UITableViewCell*) cell
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

    if([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]){
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
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
        cell.textLabel.text = LocalizedString(@"PrivacySettings");
        [self hiddenSeparatorLine:cell];
    } else if(indexPath.section == 1) {
        cell.textLabel.text = LocalizedString(@"Theme");
        [self hiddenSeparatorLine:cell];
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self showSeparatorLine:cell];
            cell.textLabel.text = LocalizedString(@"CurrentVersion");
            cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
            cell.accessoryType = UITableViewCellAccessoryNone;
        } if (indexPath.row == 1) {
            cell.textLabel.text = LocalizedString(@"HelpFeedback");
            [self showSeparatorLine:cell];
        } else if (indexPath.row == 2) {
            cell.textLabel.text = LocalizedString(@"AboutWFChat");
            [self hiddenSeparatorLine:cell];
        }
    } else if(indexPath.section == 3) {
        if (indexPath.row == 0) {
            cell.textLabel.text = LocalizedString(@"UserAgreement");
            [self showSeparatorLine:cell];

        } if (indexPath.row == 1) {
            cell.textLabel.text = LocalizedString(@"PrivacyPolicy");
            [self hiddenSeparatorLine:cell];
        }
    } else if(indexPath.section == 4) {
        if (indexPath.row == 0) {
            [self hiddenSeparatorLine:cell];
            cell.textLabel.text = LocalizedString(@"Complain");
        }
    } else if (indexPath.section == 5) {
        [self hiddenSeparatorLine:cell];
        cell.textLabel.text = LocalizedString(@"Diagnose");
    } else if (indexPath.section == 6) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"buttonCell"];
        for (UIView *subView in cell.subviews) {
            [subView removeFromSuperview];
        }
       [self setLastCellSeperatorToLeft:cell];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        [btn setTitle:LocalizedString(@"Logout") forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
        [btn setTitleColor:[UIColor colorWithHexString:@"0xf95569"]
                  forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onLogoutBtn:) forControlEvents:UIControlEventTouchUpInside];
        if (@available(iOS 14, *)) {
            [cell.contentView addSubview:btn];
        } else {
            [cell addSubview:btn];
        }
    }
    
    return cell;
}
 
- (void)onLogoutBtn:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedName"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[AppService sharedAppService] clearAppServiceCookies];
    
    //退出后就不需要推送了，第一个参数为YES
    //如果希望再次登录时能够保留历史记录，第二个参数为NO。如果需要清除掉本地历史记录第二个参数用YES
    [[WFCCNetworkService sharedInstance] disconnect:YES clearSession:NO];
}
@end
