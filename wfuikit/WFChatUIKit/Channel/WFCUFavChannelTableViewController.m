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

@interface WFCUFavChannelTableViewController ()
@property (nonatomic, strong)NSMutableArray<WFCCChannelInfo *> *favChannels;
@end

@implementation WFCUFavChannelTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.favChannels = [[NSMutableArray alloc] init];
    self.title = WFCString(@"MyChannels");
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_plus"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    [self refreshList];
}

- (void)onRightBarBtn:(id)sender {
    UIViewController *vc = [[WFCUSearchChannelViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)refreshList {
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getRemoteListenedChannels:^(NSArray<NSString *> *ids) {
        [ws.favChannels removeAllObjects];
        for (NSString *channelId in ids) {
            WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:channelId refresh:NO];
            if (channelInfo) {
                channelInfo.channelId = channelId;
                [ws.favChannels addObject:channelInfo];
            }
        }
        [ws.tableView reloadData];
    } error:^(int errorCode) {
        
    }];
    
    
    [self.tableView reloadData];
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    WFCCChannelInfo *channelInfo = notification.userInfo[@"channelInfo"];
    BOOL updated = NO;
    for (int i = 0; i < self.favChannels.count; i++) {
        if([self.favChannels[i].channelId isEqualToString:channelInfo.channelId]) {
            self.favChannels[i] = channelInfo;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
            updated = YES;
        }
    }
    
    if (!updated) {
        [self refreshList];
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
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.favChannels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUChannelTableViewCell *cell = (WFCUChannelTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"groupCellId"];
    if (cell == nil) {
        cell = [[WFCUChannelTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCellId"];
    }
    
    cell.channelInfo = self.favChannels[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCChannelInfo *channelInfo;
    channelInfo = self.favChannels[indexPath.row];
    
    
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    NSString *channelId = channelInfo.channelId;
    mvc.conversation = [WFCCConversation conversationWithType:Channel_Type target:channelId line:0];
    [self.navigationController pushViewController:mvc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
