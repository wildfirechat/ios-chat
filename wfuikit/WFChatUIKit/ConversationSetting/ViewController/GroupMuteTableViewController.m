//
//  GroupMuteTableViewController.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "GroupMuteTableViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUContactListViewController.h"
#import "WFCUGeneralSwitchTableViewCell.h"
#import "WFCUContactListViewController.h"

@interface GroupMuteTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCGroupMember *> *mutedMemberList;
@property(nonatomic, strong)NSMutableArray<WFCCGroupMember *> *allowedMemberList;
@end

@implementation GroupMuteTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = WFCString(@"GroupMuteSetting");
    
    [self loadMemberList];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kGroupMemberUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([ws.groupInfo.target isEqualToString:note.object]) {
            [ws loadMemberList];
            [ws.tableView reloadData];
        }
    }];
}

- (void)loadMemberList {
    NSArray *memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:YES];
    self.mutedMemberList = [[NSMutableArray alloc] init];
    self.allowedMemberList = [[NSMutableArray alloc] init];
    for (WFCCGroupMember *member in memberList) {
        if (member.type == Member_Type_Muted) {
            [self.mutedMemberList addObject:member];
        } else if (member.type == Member_Type_Allowed) {
            [self.allowedMemberList addObject:member];
        }
    }
}
- (void)selectMemberToAdd:(BOOL)isAllow {
    WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = YES;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        if (isAllow) {
            [[WFCCIMService sharedWFCIMService] allowGroupMember:self.groupInfo.target isSet:YES memberIds:contacts notifyLines:@[@(0)] notifyContent:nil success:^{
                [ws loadMemberList];
                [ws.tableView reloadData];
            } error:^(int error_code) {
                
            }];
        } else {
            [[WFCCIMService sharedWFCIMService] muteGroupMember:self.groupInfo.target isSet:YES memberIds:contacts notifyLines:@[@(0)] notifyContent:nil success:^{
                [ws loadMemberList];
                [ws.tableView reloadData];
            } error:^(int error_code) {
                
            }];
        }
        
    };
    NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
    NSArray *memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:NO];
    for (WFCCGroupMember *member in memberList) {
        if ((member.type == Member_Type_Normal || (isAllow && member.type == Member_Type_Muted) || (!isAllow && member.type == Member_Type_Allowed)) && ![member.memberId isEqualToString:self.groupInfo.owner]) {
            [candidateUsers addObject:member.memberId];
        }
    }
    pvc.candidateUsers = candidateUsers;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    __weak typeof(self)ws = self;
    if (indexPath.section == 0) {
        WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) {
            cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
            cell.textLabel.text = WFCString(@"MuteAll");
            cell.onSwitch = ^(BOOL value, int type, void (^onDone)(BOOL success)) {
                [[WFCCIMService sharedWFCIMService] modifyGroupInfo:self.groupInfo.target type:Modify_Group_Mute newValue:value?@"1":@"0" notifyLines:@[@(0)] notifyContent:nil success:^{
                    ws.groupInfo.mute = value;
                    onDone(YES);
                } error:^(int error_code) {
                    onDone(NO);
                }];
            };
        }
        
        cell.on = self.groupInfo.mute;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if(indexPath.section == 1) {
            if (indexPath.row == 0) {
                cell.imageView.image = [UIImage imageNamed:@"plus"];
                cell.textLabel.text = WFCString(@"MuteMember");
            } else {
                WFCCUserInfo *member = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.mutedMemberList objectAtIndex:indexPath.row-1].memberId  refresh:NO];
                [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[member.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
                cell.textLabel.text = member.displayName;
            }
        } else if(indexPath.section == 2) {
            if (indexPath.row == 0) {
                cell.imageView.image = [UIImage imageNamed:@"plus"];
                cell.textLabel.text = WFCString(@"AllowMember");
            } else {
                WFCCUserInfo *member = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.allowedMemberList objectAtIndex:indexPath.row-1].memberId  refresh:NO];
                [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[member.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
                cell.textLabel.text = member.displayName;
            }
        }
        
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || (indexPath.section == 1 && indexPath.row == 0)) {
        return NO;
    }
    return YES;
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:WFCString(@"Unmute") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

        __weak typeof(self)ws = self;
        if (indexPath.section == 1) {
            [[WFCCIMService sharedWFCIMService] muteGroupMember:self.groupInfo.target isSet:NO memberIds:@[[self.mutedMemberList objectAtIndex:indexPath.row-1].memberId] notifyLines:@[@(0)] notifyContent:nil success:^{
                for (WFCCGroupMember *member in ws.mutedMemberList) {
                    if ([member.memberId isEqualToString:[ws.mutedMemberList objectAtIndex:indexPath.row-1].memberId]) {
                        [ws.mutedMemberList removeObject:member];
                        [ws.tableView reloadData];
                        break;
                    }
                }
            } error:^(int error_code) {
                
            }];
        } else if(indexPath.section == 2) {
            [[WFCCIMService sharedWFCIMService] allowGroupMember:self.groupInfo.target isSet:NO memberIds:@[[self.allowedMemberList objectAtIndex:indexPath.row-1].memberId] notifyLines:@[@(0)] notifyContent:nil success:^{
                for (WFCCGroupMember *member in ws.allowedMemberList) {
                    if ([member.memberId isEqualToString:[ws.allowedMemberList objectAtIndex:indexPath.row-1].memberId]) {
                        [ws.allowedMemberList removeObject:member];
                        [ws.tableView reloadData];
                        break;
                    }
                }
            } error:^(int error_code) {
                
            }];
        }
        
    }];
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Cancel") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {

    }];
    editAction.backgroundColor = [UIColor grayColor];
    return @[deleteAction, editAction];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if(section == 1) {
        return self.mutedMemberList.count+1;
    } else if(section == 2) {
        return self.allowedMemberList.count+1;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return WFCString(@"MuteAll");
    } else if(section == 1) {
        return WFCString(@"MutedList");
    } else if(section == 2) {
        return WFCString(@"AllowList");
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
    return 3; //全员禁言，群成员禁言，允许发言成员
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    } else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self selectMemberToAdd:NO];
        } else {
            
        }
    } else if(indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self selectMemberToAdd:YES];
        } else {
            
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

