//
//  FavGroupTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUFavChannelTableViewController.h"
#import "WFCUChannelTableViewCell.h"
#import "WFCUMessageListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "UIView+Toast.h"
#import "WFCUCreateChannelViewController.h"
#import "WFCUSearchChannelViewController.h"

@interface WFCUFavChannelTableViewController () <UIActionSheetDelegate>
@property (nonatomic, strong)NSMutableArray<WFCCChannelInfo *> *myChannels;
@property (nonatomic, strong)NSMutableArray<WFCCChannelInfo *> *favChannels;
@end

@implementation WFCUFavChannelTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myChannels = [[NSMutableArray alloc] init];
    self.favChannels = [[NSMutableArray alloc] init];
    self.title = @"我的频道";
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_plus"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
}

- (void)onRightBarBtn:(id)sender {
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:@"添加频道"
                                delegate:self
                       cancelButtonTitle:@"取消"
                  destructiveButtonTitle:@"收听别人的频道"
                       otherButtonTitles:@"新建自己的频道", nil];
    [actionSheet showInView:self.view];
}
- (void)refreshList {
    NSArray *ids = [[WFCCIMService sharedWFCIMService] getMyChannels];
    [self.myChannels removeAllObjects];
    [self.favChannels removeAllObjects];
    
    for (NSString *channelId in ids) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:channelId refresh:NO];
        if (channelInfo) {
            channelInfo.channelId = channelId;
            [self.myChannels addObject:channelInfo];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:channelId];
        }
    }
    
    ids = [[WFCCIMService sharedWFCIMService] getListenedChannels];
    for (NSString *channelId in ids) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:channelId refresh:NO];
        if (channelInfo) {
            channelInfo.channelId = channelId;
            [self.favChannels addObject:channelInfo];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:channelId];
        }
    }
    
    [self.tableView reloadData];
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    WFCCChannelInfo *channelInfo = notification.userInfo[@"channelInfo"];
    for (int i = 0; i < self.myChannels.count; i++) {
        if([self.myChannels[i].channelId isEqualToString:channelInfo.channelId]) {
            self.myChannels[i] = channelInfo;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    for (int i = 0; i < self.favChannels.count; i++) {
        if([self.favChannels[i].channelId isEqualToString:channelInfo.channelId]) {
            self.favChannels[i] = channelInfo;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshList];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.myChannels.count;
    }
    return self.favChannels.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"我的频道";
    } else {
        return @"收听的频道";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUChannelTableViewCell *cell = (WFCUChannelTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupCellId"];
    if (cell == nil) {
        cell = [[WFCUChannelTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCellId"];
    }
    
    if (indexPath.section == 0) {
        cell.channelInfo = self.myChannels[indexPath.row];
    } else {
        cell.channelInfo = self.favChannels[indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCChannelInfo *channelInfo;
    if (indexPath.section == 0) {
        channelInfo = self.myChannels[indexPath.row];
    } else {
        channelInfo = self.favChannels[indexPath.row];
    }
    
    
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    NSString *channelId = channelInfo.channelId;
    mvc.conversation = [WFCCConversation conversationWithType:Channel_Type target:channelId line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}
#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        UIViewController *vc = [[WFCUSearchChannelViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    } else if (buttonIndex == 1) {
        UIViewController *vc = [[WFCUCreateChannelViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
