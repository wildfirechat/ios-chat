//
//  WFCUJoinGroupRequestViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUJoinGroupRequestViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUProfileTableViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUJoinGroupRequestTableViewCell.h"
#import "MBProgressHUD.h"
#import "WFCUAddFriendViewController.h"
#import "UIView+Toast.h"
#import "WFCUConfigManager.h"

@interface WFCUJoinGroupRequestViewController () <UITableViewDataSource, UITableViewDelegate, WFCUJoinGroupRequestTableViewCellDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<WFCCJoinGroupRequest *> *dataList;
@end

@implementation WFCUJoinGroupRequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSearchUIAndData];
  
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onJoinGroupRequestUpdated:) name:kJoinGroupRequestUpdated object:nil];
    
    [[WFCCIMService sharedWFCIMService] clearJoinGroupRequestUnread:self.groupId];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (int i = 0; i < self.dataList.count; ++i) {
        WFCCJoinGroupRequest *request = self.dataList[i];
        for (WFCCUserInfo *userInfo in userInfoList) {
            if([userInfo.userId isEqualToString:request.memberId]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onJoinGroupRequestUpdated:(NSNotification *)notification {
    _dataList = [[[WFCCIMService sharedWFCIMService] getJoinGroupRequests:self.groupId memberId:nil status:-1] mutableCopy];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WFCCIMService sharedWFCIMService] clearJoinGroupRequestUnread:self.groupId];
}

- (void)initSearchUIAndData {
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.navigationItem.title = @"入群申请";
    
    //初始化数据源
    _dataList = [[[WFCCIMService sharedWFCIMService] getJoinGroupRequests:self.groupId memberId:nil status:-1] mutableCopy];
    
    CGFloat screenWidth = self.view.frame.size.width;
    CGFloat screenHeight = self.view.frame.size.height;
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    //设置代理
    _tableView.delegate   = self;
    _tableView.dataSource = self;
    _tableView.allowsSelection = YES;
    _tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self.view addSubview:_tableView];
  
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Clear") style:UIBarButtonItemStyleDone target:self action:@selector(onClearBarBtn:)];
}

- (void)onClearBarBtn:(UIBarButtonItem *)sender {
    [[WFCCIMService sharedWFCIMService] clearJoinGroupRequest:self.groupId memberId:nil inviter:nil];
    _dataList   = [[[WFCCIMService sharedWFCIMService] getJoinGroupRequests:self.groupId memberId:nil status:-1] mutableCopy];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

#pragma mark - UITableViewDataSource

//table 返回的行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
      return [self.dataList count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}
//返回单元格内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *requestFlag = @"request_cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:requestFlag];
  
  if (cell == nil) {
    cell = [[WFCUJoinGroupRequestTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:requestFlag];
  }
  
  
    WFCUJoinGroupRequestTableViewCell *frCell = (WFCUJoinGroupRequestTableViewCell *)cell;
  frCell.delegate = self;
  WFCCJoinGroupRequest *request = self.dataList[indexPath.row];
  frCell.joinGroupRequest = request;
  
  cell.userInteractionEnabled = YES;
  return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
        trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    __block typeof(self) ws = self;
    
    // 第一个“删除”按钮（红色）
    UIContextualAction *delete1 = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                                          title:@"删除"
                                                                        handler:^(UIContextualAction * _Nonnull action,
                                                                                  UIView * _Nonnull sourceView,
                                                                                  void (^ _Nonnull completionHandler)(BOOL)) {
        WFCCJoinGroupRequest *request = ws.dataList[indexPath.row];
        [[WFCCIMService sharedWFCIMService] clearJoinGroupRequest:request.groupId memberId:request.memberId inviter:request.requestUserId];
        [ws.dataList removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        completionHandler(YES);
    }];
    
    // “拒绝”按钮（可选颜色）
    UIContextualAction *reject = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                                         title:@"拒绝"
                                                                       handler:^(UIContextualAction * _Nonnull action,
                                                                                 UIView * _Nonnull sourceView,
                                                                                 void (^ _Nonnull completionHandler)(BOOL)) {
        WFCCJoinGroupRequest *request = ws.dataList[indexPath.row];
        [[WFCCIMService sharedWFCIMService] handleJoinGroupRequest:request.groupId memberId:request.memberId inviter:request.requestUserId status:2 memberExtra:nil notifyLines:nil success:^{
            completionHandler(YES);
        } error:^(int errorCode) {
            completionHandler(NO);
        }];
    }];
    reject.backgroundColor = [UIColor orangeColor];
    
    // 组装
    UISwipeActionsConfiguration *config;
    if(ws.dataList[indexPath.row].status == 0) {
        config = [UISwipeActionsConfiguration configurationWithActions:@[reject, delete1]];
    } else {
        config = [UISwipeActionsConfiguration configurationWithActions:@[delete1]];
    }
    // 禁止“滑到底直接执行第一个按钮”
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}
#pragma mark - FriendRequestTableViewCellDelegate
- (void)onAcceptBtn:(NSString *)targetUserId inviterId:(NSString *)inviterId {
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = WFCString(@"Updating");
    [hud showAnimated:YES];
    
    __weak typeof(self) ws = self;
    [[WFCCIMService sharedWFCIMService] handleJoinGroupRequest:self.groupId memberId:targetUserId inviter:inviterId status:1 memberExtra:nil notifyLines:@[@(0)] success:^{
        hud.hidden = YES;
        [ws.view makeToast:WFCString(@"UpdateDone")
                  duration:2
                  position:CSToastPositionCenter];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [NSThread sleepForTimeInterval:0.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                ws.dataList   = [[WFCCIMService sharedWFCIMService] getJoinGroupRequests:ws.groupId memberId:nil status:-1];
                for (WFCCJoinGroupRequest *request in ws.dataList) {
                    if ([request.memberId isEqualToString:targetUserId]) {
                        request.status = 1;
                        break;
                    }
                }
                [ws.tableView reloadData];
            });
        });
    } error:^(int errorCode) {
        [ws.view makeToast:WFCString(@"UpdateFailure")
                  duration:2
                  position:CSToastPositionCenter];
    }];
}

- (void)onViewUserInfo:(NSString *)userId {
    WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
    vc.userId = userId;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView        = nil;
    _dataList         = nil;
}
@end
