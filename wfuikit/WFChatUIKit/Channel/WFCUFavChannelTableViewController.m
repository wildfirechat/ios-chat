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
@property (nonatomic, strong)NSMutableArray<WFCCChannelInfo *> *myChannels;
@property (nonatomic, strong)NSMutableArray<WFCCChannelInfo *> *favChannels;
@end

@implementation WFCUFavChannelTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myChannels = [[NSMutableArray alloc] init];
    self.favChannels = [[NSMutableArray alloc] init];
    self.title = WFCString(@"MyChannels");
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_plus"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
}

- (void)onRightBarBtn:(id)sender {
    __weak typeof(self)ws = self;
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:WFCString(@"AddChannel") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:WFCString(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *actionSubscribe = [UIAlertAction actionWithTitle:WFCString(@"SubscribeChannel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIViewController *vc = [[WFCUSearchChannelViewController alloc] init];
        [ws.navigationController pushViewController:vc animated:YES];
    }];
    
    UIAlertAction *actionCreate = [UIAlertAction actionWithTitle:WFCString(@"CreateChannel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIViewController *vc = [[WFCUCreateChannelViewController alloc] init];
        [ws.navigationController pushViewController:vc animated:YES];
    }];
    
    //把action添加到actionSheet里
    [actionSheet addAction:actionSubscribe];
    [actionSheet addAction:actionCreate];
    [actionSheet addAction:actionCancel];
    
    //相当于之前的[actionSheet show];
    [self presentViewController:actionSheet animated:YES completion:nil];
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

            __weak typeof(self)ws = self;
            [[NSNotificationCenter defaultCenter] addObserverForName:kChannelInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [ws onChannelInfoUpdated:note];
            }];
        }
    }
    
    ids = [[WFCCIMService sharedWFCIMService] getListenedChannels];
    for (NSString *channelId in ids) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:channelId refresh:NO];
        if (channelInfo) {
            channelInfo.channelId = channelId;
            [self.favChannels addObject:channelInfo];
            __weak typeof(self)ws = self;
            [[NSNotificationCenter defaultCenter] addObserverForName:kChannelInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                [ws onChannelInfoUpdated:note];
            }];
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
        return WFCString(@"MyChannels");
    } else {
        return WFCString(@"SubscribedChannels");
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
