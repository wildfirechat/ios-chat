//
//  GroupManageTableViewController.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "GroupManageTableViewController.h"
#import "ManagerTableViewController.h"
#import "GroupMuteTableViewController.h"
#import "GroupMemberControlTableViewController.h"
#import "UIView+Toast.h"

@interface GroupManageTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@end

@implementation GroupManageTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"群管理";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupInfo.target isEqualToString:note.object]) {
            ws.groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:ws.groupInfo.target refresh:NO];
            [ws.tableView reloadData];
        }
    }];
    
}
- (BOOL)isGroupOwner {
    return [self.groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId];
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.detailTextLabel.text = nil;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([self isGroupOwner]) {
                cell.textLabel.text = @"管理员";
            } else {
                cell.textLabel.text = @"设置禁言";
            }
            
        } else if(indexPath.row == 1) {
            if ([self isGroupOwner]) {
                cell.textLabel.text = @"设置禁言";
            } else {
                cell.textLabel.text = @"成员权限";
            }
        } else if(indexPath.row == 2) {
            cell.textLabel.text = @"成员权限";
        }
    } else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"加群方式";
            if (self.groupInfo.joinType == 0) {
                cell.detailTextLabel.text = @"不限制加入";
            } else if(self.groupInfo.joinType == 1) {
                cell.detailTextLabel.text = @"群成员可以拉人";
            } else if(self.groupInfo.joinType == 2) {
                cell.detailTextLabel.text = @"只能群管理拉人";
            }
        } else if(indexPath.row == 1) {
            cell.textLabel.text = @"查找方式";
            cell.detailTextLabel.text = @"不允许查找";
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self isGroupOwner]) {
            return 3; //管理员，设置禁言，群成员权限
        }
        return 2;//设置禁言，群成员权限
    } else if(section == 1) {
        return 2;//加群方式，查找权限
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"成员管理";
    } else if(section == 1) {
        return @"加群设置";
    }
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.f;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.f;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2; //成员管理，加群设置
}
- (void)toManagerVC {
    ManagerTableViewController *mtvc = [[ManagerTableViewController alloc] init];
    mtvc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:mtvc animated:YES];
}
- (void)toMuteVC {
    GroupMuteTableViewController *gmtc = [[GroupMuteTableViewController alloc] init];
    gmtc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:gmtc animated:YES];
}
- (void)toMemberControlVC {
    GroupMemberControlTableViewController *gmcvc = [[GroupMemberControlTableViewController alloc] init];
    gmcvc.groupInfo = self.groupInfo;
    [self.navigationController pushViewController:gmcvc animated:YES];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([self isGroupOwner]) {
                [self toManagerVC];
            } else {
                [self toMuteVC];
            }
        } else if(indexPath.row == 1) {
            if ([self isGroupOwner]) {
                [self toMuteVC];
            } else {
                [self toMemberControlVC];
            }
        } else if(indexPath.row == 2) {
            [self toMemberControlVC];
        }
    } else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"加群方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            // Create cancel action.
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
            }];
            [alertController addAction:cancelAction];
            
            UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"不限制加入" style:self.groupInfo.joinType == 0 ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_JoinType newValue:@"0" notifyLines:@[@(0)] notifyContent:nil success:^{
//                    self.groupInfo.joinType = 0;
//                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
                } error:^(int error_code) {
                    [self.view makeToast:@"设置失败"];
                }];
            }];
            [alertController addAction:openAction];
            
            UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"群成员可以拉人" style:self.groupInfo.joinType == 1 ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_JoinType newValue:@"1" notifyLines:@[@(0)] notifyContent:nil success:^{
//                    self.groupInfo.joinType = 1;
//                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
                } error:^(int error_code) {
                    [self.view makeToast:@"设置失败"];
                }];
            }];
            [alertController addAction:verifyAction];
            
            UIAlertAction *normalAction = [UIAlertAction actionWithTitle:@"只能群管理拉人" style:self.groupInfo.joinType == 2 ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_JoinType newValue:@"2" notifyLines:@[@(0)] notifyContent:nil success:^{
//                    self.groupInfo.joinType = 2;
//                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
                } error:^(int error_code) {
                    [self.view makeToast:@"设置失败"];
                }];
            }];
            [alertController addAction:normalAction];
            
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        } else if(indexPath.row == 1) {
            UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"查找方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            // Create cancel action.
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                
            }];
            [alertController addAction:cancelAction];
            
            UIAlertAction *openAction = [UIAlertAction actionWithTitle:@"允许查找" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                
            }];
            [alertController addAction:openAction];
            
            UIAlertAction *verifyAction = [UIAlertAction actionWithTitle:@"不允许查找" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
            }];
            [alertController addAction:verifyAction];
            
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    }
    
}
@end
