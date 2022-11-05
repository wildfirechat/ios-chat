//
//  WFCUGroupTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUGroupTableViewController.h"
#import "WFCUGroupTableViewCell.h"
#import "WFCUMessageListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUGroupMemberTableViewController.h"
#import "WFCUInviteGroupMemberViewController.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"

@implementation WFCUGroupTableViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.titleString;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    [self.tableView reloadData];
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCGroupInfo *> *groupInfoList = notification.userInfo[@"groupInfoList"];
    for (int i = 0; i < self.groupIds.count; ++i) {
        for (WFCCGroupInfo *groupInfo in groupInfoList) {
            if([self.groupIds[i] isEqualToString:groupInfo.target]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                break;
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupIds.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUGroupTableViewCell *cell = (WFCUGroupTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupCellId"];
    if (cell == nil) {
        cell = [[WFCUGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCellId"];
    }
    WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.groupIds[indexPath.row] refresh:NO];
    if(!groupInfo) {
        groupInfo = [[WFCCGroupInfo alloc] init];
        groupInfo.target = self.groupIds[indexPath.row];
    }
    
    cell.groupInfo = groupInfo;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    NSString *groupId = self.groupIds[indexPath.row];
    mvc.conversation = [WFCCConversation conversationWithType:Group_Type target:groupId line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
