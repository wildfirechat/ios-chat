//
//  ManagerTableViewController.m
//  WFChatUIKit
//
//  Created by heavyrain lee on 2019/6/26.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "ManagerTableViewController.h"
#import "SDWebImage.h"
#import "WFCUContactListViewController.h"

@interface ManagerTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<WFCCGroupMember *> *managerList;
@end

@implementation ManagerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"管理员设置";
    
    [self loadManagerList];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}

- (void)loadManagerList {
    NSArray *memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:YES];
    self.managerList = [[NSMutableArray alloc] init];
    for (WFCCGroupMember *member in memberList) {
        if (member.type == Member_Type_Manager) {
            [self.managerList addObject:member];
        }
    }
}
- (void)selectMemberToAdd {
    WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = YES;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        
    };
    NSMutableArray *candidateUsers = [[NSMutableArray alloc] init];
    NSArray *memberList = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.groupInfo.target forceUpdate:NO];
    for (WFCCGroupMember *member in memberList) {
        if (member.type == Member_Type_Normal && ![member.memberId isEqualToString:self.groupInfo.owner]) {
            [candidateUsers addObject:member.memberId];
        }
    }
    pvc.candidateUsers = candidateUsers;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        WFCCUserInfo *owner = [[WFCCIMService sharedWFCIMService] getUserInfo:self.groupInfo.owner refresh:NO];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:owner.portrait]];
        cell.textLabel.text = owner.displayName;
    } else if(indexPath.section == 1) {
        if (indexPath.row == self.managerList.count) {
            cell.imageView.image = [UIImage imageNamed:@"plus"];
            cell.textLabel.text = @"添加管理员";
        } else {
            WFCCUserInfo *manager = [[WFCCIMService sharedWFCIMService] getUserInfo:[self.managerList objectAtIndex:indexPath.row].memberId  refresh:NO];
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:manager.portrait]];
            cell.textLabel.text = manager.displayName;
        }
    }
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if(section == 1) {
        return self.managerList.count+1;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"群主";
    } else if(section == 1) {
        return @"管理员";
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
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    } else if(indexPath.section == 1) {
        if (indexPath.row == self.managerList.count) {
            [self selectMemberToAdd];
        } else {
            
        }
    }
}
@end
