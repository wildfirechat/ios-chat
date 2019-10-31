//
//  ConversationTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationTableViewController.h"
#import "WFCUConversationTableViewCell.h"
#import "WFCUContactListViewController.h"
#import "WFCUCreateGroupViewController.h"
#import "WFCUFriendRequestViewController.h"
#import "WFCUSearchGroupTableViewCell.h"
#import "WFCUConversationSearchTableViewController.h"
#import "WFCUSearchChannelViewController.h"
#import "WFCUCreateChannelViewController.h"

#import "WFCUMessageListViewController.h"
#import <WFChatClient/WFCChatClient.h>

#import "WFCUUtilities.h"
#import "UITabBar+badge.h"
#import "KxMenu.h"
#import "UIImage+ERCategory.h"
#import "MBProgressHUD.h"

#import "WFCUContactTableViewCell.h"
#import "QrCodeHelper.h"
#import "WFCUConfigManager.h"

@interface WFCUConversationTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCConversationInfo *> *conversations;

@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) NSArray<WFCCConversationSearchInfo *>  *searchConversationList;
@property (nonatomic, strong) NSArray<WFCCUserInfo *>  *searchFriendList;
@property (nonatomic, strong) NSArray<WFCCGroupSearchInfo *>  *searchGroupList;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;

@property (nonatomic, assign) BOOL firstAppear;

@property (nonatomic, strong) UIView *pcSessionView;
@end

@implementation WFCUConversationTableViewController
- (void)initSearchUIAndTableView {
    _searchConversationList = [NSMutableArray array];

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if (! @available(iOS 13, *)) {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }

    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    self.searchController.searchBar.placeholder = WFCString(@"Search");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
    
    [self updatePcSession];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    } else {
        WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
        NSArray *dataSource = self.conversations;
        for (int i = 0; i < dataSource.count; i++) {
            WFCCConversationInfo *conv = dataSource[i];
            if (conv.conversation.type == Single_Type && [conv.conversation.target isEqualToString:userInfo.userId]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    } else {
        WFCCGroupInfo *groupInfo = notification.userInfo[@"groupInfo"];
        NSArray *dataSource = self.conversations;
        
        
        for (int i = 0; i < dataSource.count; i++) {
            WFCCConversationInfo *conv = dataSource[i];
            if (conv.conversation.type == Group_Type && [conv.conversation.target isEqualToString:groupInfo.target]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    } else {
        WFCCChannelInfo *channelInfo = notification.userInfo[@"groupInfo"];
        NSArray *dataSource = self.conversations;


        for (int i = 0; i < dataSource.count; i++) {
            WFCCConversationInfo *conv = dataSource[i];
            if (conv.conversation.type == Channel_Type && [conv.conversation.target isEqualToString:channelInfo.channelId]) {
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onSendingMessageStatusUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    } else {
        long messageId = [notification.object longValue];
        NSArray *dataSource = self.conversations;
        
        if (messageId == 0) {
            return;
        }
        
        for (int i = 0; i < dataSource.count; i++) {
            WFCCConversationInfo *conv = dataSource[i];
            if (conv.lastMessage && conv.lastMessage.direction == MessageDirection_Send && conv.lastMessage.messageId == messageId) {
                conv.lastMessage = [[WFCCIMService sharedWFCIMService] getMessage:messageId];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    CGFloat searchExtra = 0;
    if (@available(iOS 11.0, *)) {
        if (self.searchController.searchBar.bounds.size.height > 0) {
            searchExtra = 52;
        }
    }
    
    [KxMenu showMenuInView:self.view
                  fromRect:CGRectMake(self.view.bounds.size.width - 56, kStatusBarAndNavigationBarHeight + searchExtra, 48, 5)
                 menuItems:@[
                             [KxMenuItem menuItem:WFCString(@"StartChat")
                                            image:[UIImage imageNamed:@"menu_start_chat"]
                                           target:self
                                           action:@selector(startChatAction:)],
                             [KxMenuItem menuItem:WFCString(@"AddFriend")
                                            image:[UIImage imageNamed:@"menu_add_friends"]
                                           target:self
                                           action:@selector(addFriendsAction:)],
                             [KxMenuItem menuItem:WFCString(@"SubscribeChannel")
                                            image:[UIImage imageNamed:@"menu_listen_channel"]
                                           target:self
                                           action:@selector(listenChannelAction:)],
                             [KxMenuItem menuItem:WFCString(@"ScanQRCode")
                                            image:[UIImage imageNamed:@"menu_scan_qr"]
                                           target:self
                                           action:@selector(scanQrCodeAction:)]
                             ]];
}

- (void)startChatAction:(id)sender {
    WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = YES;
    pvc.showCreateChannel = YES;
  __weak typeof(self)ws = self;
    pvc.createChannel = ^(void) {
        WFCUCreateChannelViewController *vc = [[WFCUCreateChannelViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    };
    
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
      if (contacts.count == 1) {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:contacts[0] line:0];
        mvc.hidesBottomBarWhenPushed = YES;
        [ws.navigationController pushViewController:mvc animated:YES];
      } else {
        WFCUCreateGroupViewController *vc = [[WFCUCreateGroupViewController alloc] init];
        vc.memberIds = [contacts mutableCopy];
        if (![vc.memberIds containsObject:[WFCCNetworkService sharedInstance].userId]) {
          [vc.memberIds insertObject:[WFCCNetworkService sharedInstance].userId atIndex:0];
        }
        vc.hidesBottomBarWhenPushed = YES;
        [ws.navigationController pushViewController:vc animated:YES];
      }
    };
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)addFriendsAction:(id)sender {
    UIViewController *addFriendVC = [[WFCUFriendRequestViewController alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
}

- (void)listenChannelAction:(id)sender {
    UIViewController *searchChannelVC = [[WFCUSearchChannelViewController alloc] init];
    searchChannelVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:searchChannelVC animated:YES];
}

- (void)scanQrCodeAction:(id)sender {
    if (gQrCodeDelegate) {
        [gQrCodeDelegate scanQrCode:self.navigationController];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.conversations = [[NSMutableArray alloc] init];
    
    [self initSearchUIAndTableView];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_plus"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessageStatusUpdated:) name:kSendingMessageStatusUpdated object:nil];
    
    self.firstAppear = YES;
}

- (void)updateConnectionStatus:(ConnectionStatus)status {
  UIView *title;
  if (status != kConnectionStatusConnecting && status != kConnectionStatusReceiving) {
    UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 40, 0, 80, 44)];
      
    switch (status) {
      case kConnectionStatusLogout:
        navLabel.text = WFCString(@"NotLogin");
        break;
      case kConnectionStatusUnconnected:
        navLabel.text = WFCString(@"NotConnect");
        break;
      case kConnectionStatusConnected:
        navLabel.text = WFCString(@"Message");
        break;
        
      default:
        break;
    }
    
    navLabel.textColor = [WFCUConfigManager globalManager].naviTextColor;
    navLabel.font = [UIFont fontWithName:@"Arial-BoldMT" size:18];
      
    navLabel.textAlignment = NSTextAlignmentCenter;
    title = navLabel;
  } else {
      UIView *continer = [[UIView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 60, 0, 120, 44)];
      UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 2, 80, 40)];
      if (status == kConnectionStatusConnecting) {
        navLabel.text = WFCString(@"Connecting");
      } else {
        navLabel.text = WFCString(@"Synching");
      }
      
      navLabel.textColor = [WFCUConfigManager globalManager].naviTextColor;
      navLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
      [continer addSubview:navLabel];
      
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicatorView.center = CGPointMake(20, 21);
    [indicatorView startAnimating];
      indicatorView.color = [WFCUConfigManager globalManager].naviTextColor;
      [continer addSubview:indicatorView];
    title = continer;
  }
  self.navigationItem.titleView = title;
}

- (void)onConnectionStatusChanged:(NSNotification *)notification {
  ConnectionStatus status = [notification.object intValue];
  [self updateConnectionStatus:status];
}

- (void)onReceiveMessages:(NSNotification *)notification {
  NSArray<WFCCMessage *> *messages = notification.object;
  if ([messages count]) {
    [self refreshList];
    [self refreshLeftButton];
  }
}

- (void)onSettingUpdated:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshList];
        [self refreshLeftButton];
        [self updatePcSession];
    });
}

- (void)onRecallMessages:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)onClearAllUnread:(NSNotification *)notification {
    if ([notification.object intValue] == 0) {
        [[WFCCIMService sharedWFCIMService] clearAllUnreadStatus];
        [self refreshList];
        [self refreshLeftButton];
    }
}

- (void)refreshList {
  self.conversations = [[[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]] mutableCopy];
    [self updateBadgeNumber];
  [self.tableView reloadData];
}

- (void)updateBadgeNumber {
    int count = 0;
    for (WFCCConversationInfo *info in self.conversations) {
        if (!info.isSilent) {
            count += info.unreadCount.unread;
        }
    }
    [self.tabBarController.tabBar showBadgeOnItemIndex:0 badgeValue:count];
}

- (void)updatePcSession {
    NSString *pcOnline = [[WFCCIMService sharedWFCIMService] getUserSetting:UserSettingScope_PC_Online key:@""];
    
    if (@available(iOS 11.0, *)) {
        if ([pcOnline isEqualToString:@"1"]) {
            self.tableView.tableHeaderView = self.pcSessionView;
        } else {
            self.tableView.tableHeaderView = nil;
        }
    } else {
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self refreshLeftButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

    if (self.firstAppear) {
        self.firstAppear = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectionStatusChanged:) name:kConnectionStatusChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    }
    
    [self updateConnectionStatus:[WFCCNetworkService sharedInstance].currentConnectionStatus];
    [self refreshList];
    [self refreshLeftButton];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.searchController.isActive) {
        self.tabBarController.tabBar.hidden = YES;
    }
}
- (void)refreshLeftButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
        NSUInteger count = unreadCount.unread;
        
        NSString *title = nil;
        if (count > 0 && count < 1000) {
            title = [NSString stringWithFormat:WFCString(@"BackNumber"), count];
        } else if (count >= 1000) {
            title = WFCString(@"BackMore");
        } else {
            title = WFCString(@"Back");
        }
        
        UIBarButtonItem *item = [[UIBarButtonItem alloc] init];
        item.title = title;
        
        self.navigationItem.backBarButtonItem = item;
    });
}

- (UIView *)pcSessionView {
    if (!_pcSessionView) {
        _pcSessionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        [_pcSessionView setBackgroundColor:[UIColor grayColor]];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 32, 32)];
        iv.image = [UIImage imageNamed:@"pc_session"];
        [_pcSessionView addSubview:iv];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(68, 10, 100, 20)];
        label.text = WFCString(@"PCLogined");
        [_pcSessionView addSubview:label];
    }
    return _pcSessionView;
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    int sec = 0;
    if (self.searchFriendList.count) {
        sec++;
    }
    
    if (self.searchGroupList.count) {
        sec++;
    }
    
    if (self.searchConversationList.count) {
        sec++;
    }
    
    if (sec == 0) {
        sec = 1;
    }
    return sec;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (section == sec-1) {
                return self.searchFriendList.count;
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (section == sec-1) {
                return self.searchGroupList.count;
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == section) {
                return self.searchConversationList.count;
            }
        }
        
        return 0;
    } else {
        return self.conversations.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                if (cell == nil) {
                    cell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                    cell.big = YES;
                }
                cell.userId = self.searchFriendList[indexPath.row].userId;
                return cell;
            }
        }
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUSearchGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                if (cell == nil) {
                    cell = [[WFCUSearchGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                }
                cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                return cell;
            }
        }
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section) {
                WFCUConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"conversationCell"];
                if (cell == nil) {
                    cell = [[WFCUConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"conversationCell"];
                }
                cell.searchInfo = self.searchConversationList[indexPath.row];
                return cell;
            }
        }
        
        return nil;
    } else {
        WFCUConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"conversationCell"];
        if (cell == nil) {
            cell = [[WFCUConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"conversationCell"];
        }
        cell.info = self.conversations[indexPath.row];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 72;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)])
    {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 76, 0, 0)];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)])
    {
        [cell setLayoutMargins:UIEdgeInsetsMake(0, 76, 0, 0)];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (self.searchController.isActive) {
    
    if (self.searchConversationList.count + self.searchGroupList.count + self.searchFriendList.count > 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 20)];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 20)];
        
        label.font = [UIFont systemFontOfSize:13];
        label.textColor = [UIColor grayColor];
        label.textAlignment = NSTextAlignmentLeft;
        label.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (section == sec-1) {
                label.text = WFCString(@"Contact");
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (section == sec-1) {
                label.text = WFCString(@"Group");
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == section) {
                label.text = WFCString(@"Message");
            }
        }
        
      [header addSubview:label];
      return header;
    } else {
      UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 50)];
      return header;
    }
  } else {
    return nil;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        return 20;
    }
    return 0;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (self.searchController.active) {
        return NO;
    }
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) ws = self;
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [[WFCCIMService sharedWFCIMService] removeConversation:ws.conversations[indexPath.row].conversation clearMessage:YES];
        [ws.conversations removeObjectAtIndex:indexPath.row];
        [ws updateBadgeNumber];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    UITableViewRowAction *setTop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Pinned") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:YES success:^{
            [ws refreshList];
        } error:^(int error_code) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:NO];
            hud.label.text = WFCString(@"UpdateFailure");
            hud.mode = MBProgressHUDModeText;
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:NO afterDelay:1.5];
        }];
    }];
    
    UITableViewRowAction *setUntop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Unpinned") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:NO success:^{
            [ws refreshList];
        } error:^(int error_code) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:NO];
            hud.label.text = WFCString(@"UpdateFailure");
            hud.mode = MBProgressHUDModeText;
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:NO afterDelay:1.5];
        }];
        
        [self refreshList];
    }];
    
   
    
    setTop.backgroundColor = [UIColor purpleColor];
    setUntop.backgroundColor = [UIColor orangeColor];
    
    if (self.conversations[indexPath.row].isTop) {
        return @[delete, setUntop ];
    } else {
        return @[delete, setTop];
    }
};

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                WFCCUserInfo *info = self.searchFriendList[indexPath.row];
                mvc.conversation = [[WFCCConversation alloc] init];
                mvc.conversation.type = Single_Type;
                mvc.conversation.target = info.userId;
                mvc.conversation.line = 0;
                
                mvc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:mvc animated:YES];
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                WFCCGroupSearchInfo *info = self.searchGroupList[indexPath.row];
                mvc.conversation = [[WFCCConversation alloc] init];
                mvc.conversation.type = Group_Type;
                mvc.conversation.target = info.groupInfo.target;
                mvc.conversation.line = 0;
                
                mvc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:mvc animated:YES];
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section) {
                WFCCConversationSearchInfo *info = self.searchConversationList[indexPath.row];
                if (info.marchedCount == 1) {
                    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                    
                    mvc.conversation = info.conversation;
                    mvc.highlightMessageId = info.marchedMessage.messageId;
                    mvc.highlightText = info.keyword;
                    mvc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:mvc animated:YES];
                } else {
                    WFCUConversationSearchTableViewController *mvc = [[WFCUConversationSearchTableViewController alloc] init];
                    mvc.conversation = info.conversation;
                    mvc.keyword = info.keyword;
                    mvc.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:mvc animated:YES];
                }
            }
        }
    } else {
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        WFCCConversationInfo *info = self.conversations[indexPath.row];
        mvc.conversation = info.conversation;
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
    _searchConversationList       = nil;
}

#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        self.searchConversationList = [[WFCCIMService sharedWFCIMService] searchConversation:searchString inConversation:@[@(Single_Type), @(Group_Type), @(Channel_Type)] lines:@[@(0)]];
        self.searchFriendList = [[WFCCIMService sharedWFCIMService] searchFriends:searchString];
        self.searchGroupList = [[WFCCIMService sharedWFCIMService] searchGroups:searchString];
    } else {
        self.searchConversationList = nil;
        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }
    
    [self.tableView reloadData];
}
@end
