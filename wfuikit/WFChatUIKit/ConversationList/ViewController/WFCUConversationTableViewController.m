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
#import "WFCUPinyinUtility.h"

#import "WFCUContactTableViewCell.h"
#import "QrCodeHelper.h"
#import "WFCUConfigManager.h"
#import "UIImage+ERCategory.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "UIView+Toast.h"
#import "WFCUSeletedUserViewController.h"
#import "WFCUEnum.h"
#import "WFCUImage.h"


@interface WFCUConversationTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCConversationInfo *> *conversations;

@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) NSArray<WFCCConversationSearchInfo *>  *searchConversationList;
@property (nonatomic, strong) NSArray<WFCCUserInfo *>  *searchFriendList;
@property (nonatomic, strong) NSArray<WFCCGroupSearchInfo *>  *searchGroupList;
@property (nonatomic ,assign) BOOL isSearchConversationListExpansion;
@property (nonatomic ,assign) BOOL isSearchFriendListExpansion;
@property (nonatomic ,assign) BOOL isSearchGroupListExpansion;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;

@property (nonatomic, assign) BOOL firstAppear;

@property (nonatomic, strong) UIView *pcSessionView;
@property (nonatomic, strong) UILabel *pcSessionLabel;
@end

@implementation WFCUConversationTableViewController
- (void)initSearchUIAndTableView {
    _searchConversationList = [NSMutableArray array];
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    self.searchController.searchBar.placeholder = WFCString(@"Search");
    
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"expansion"];
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
    
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    if (self.searchController.active) {
        [self.tableView reloadData];
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

- (void)onSecretChatStateChanged:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)onSecretMessageBurned:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    CGFloat searchExtra = 0;
    
    if ([KxMenu isShowing]) {
        [KxMenu dismissMenu];
        return;
    }
    NSArray *menuItems;
    if ([[WFCCIMService sharedWFCIMService] isEnableSecretChat] && [[WFCCIMService sharedWFCIMService] isUserEnableSecretChat]) {
        menuItems = @[
            [KxMenuItem menuItem:WFCString(@"StartChat")
                           image:[WFCUImage imageNamed:@"menu_start_chat"]
                          target:self
                          action:@selector(startChatAction:)],
            [KxMenuItem menuItem:WFCString(@"StartSecretChat")
                           image:[WFCUImage imageNamed:@"menu_start_chat"]
                          target:self
                          action:@selector(startSecretChatAction:)],
            [KxMenuItem menuItem:WFCString(@"AddFriend")
                           image:[WFCUImage imageNamed:@"menu_add_friends"]
                          target:self
                          action:@selector(addFriendsAction:)],
            [KxMenuItem menuItem:WFCString(@"SubscribeChannel")
                           image:[WFCUImage imageNamed:@"menu_listen_channel"]
                          target:self
                          action:@selector(listenChannelAction:)],
            [KxMenuItem menuItem:WFCString(@"ScanQRCode")
                           image:[WFCUImage imageNamed:@"menu_scan_qr"]
                          target:self
                          action:@selector(scanQrCodeAction:)]
        ];
    } else {
        menuItems = @[
            [KxMenuItem menuItem:WFCString(@"StartChat")
                           image:[WFCUImage imageNamed:@"menu_start_chat"]
                          target:self
                          action:@selector(startChatAction:)],
            [KxMenuItem menuItem:WFCString(@"AddFriend")
                           image:[WFCUImage imageNamed:@"menu_add_friends"]
                          target:self
                          action:@selector(addFriendsAction:)],
            [KxMenuItem menuItem:WFCString(@"SubscribeChannel")
                           image:[WFCUImage imageNamed:@"menu_listen_channel"]
                          target:self
                          action:@selector(listenChannelAction:)],
            [KxMenuItem menuItem:WFCString(@"ScanQRCode")
                           image:[WFCUImage imageNamed:@"menu_scan_qr"]
                          target:self
                          action:@selector(scanQrCodeAction:)]
        ];
    }
    
    
    [KxMenu showMenuInView:self.navigationController.view
                  fromRect:CGRectMake(self.view.bounds.size.width - 56, [WFCUUtilities wf_navigationFullHeight] + searchExtra, 48, 5)
                 menuItems:menuItems];
}

- (void)startChatAction:(id)sender {
    WFCUSeletedUserViewController *pvc = [[WFCUSeletedUserViewController alloc] init];
    pvc.type = Horizontal;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        [navi dismissViewControllerAnimated:NO completion:nil];
        if (contacts.count == 1) {
            WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
            mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:contacts[0] line:0];
            mvc.hidesBottomBarWhenPushed = YES;
            [ws.navigationController pushViewController:mvc animated:YES];
        } else {
            [self createGroup:contacts];
        }
    };
    
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

- (void)startSecretChatAction:(id)sender {
    WFCUSeletedUserViewController *pvc = [[WFCUSeletedUserViewController alloc] init];
    pvc.type = Horizontal;
    pvc.maxSelectCount = 1;
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        [navi dismissViewControllerAnimated:NO completion:nil];
        if (contacts.count == 1) {
            [[WFCCIMService sharedWFCIMService] createSecretChat:contacts[0] success:^(NSString *targetId, int line) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                mvc.conversation = [WFCCConversation conversationWithType:SecretChat_Type target:targetId line:line];
                mvc.hidesBottomBarWhenPushed = YES;
                [ws.navigationController pushViewController:mvc animated:YES];
            } error:^(int error_code) {
                
            }];
            
        }
    };
    
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}


- (void)createGroup:(NSArray<NSString *> *)contacts {
    __weak typeof(self) ws = self;
    NSMutableArray<NSString *> *memberIds = [[NSMutableArray alloc] init];
    [contacts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![memberIds containsObject:obj]) {
            [memberIds addObject:obj];
        }
    }];
    if (![memberIds containsObject:[WFCCNetworkService sharedInstance].userId]) {
        [memberIds insertObject:[WFCCNetworkService sharedInstance].userId atIndex:0];
    }

    NSString *name;
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[memberIds objectAtIndex:0]  refresh:NO];
    name = userInfo.displayName;
    
    for (int i = 1; i < MIN(8, memberIds.count); i++) {
        userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[memberIds objectAtIndex:i]  refresh:NO];
        if (userInfo.displayName.length > 0) {
            if (name.length + userInfo.displayName.length + 1 > 16) {
                name = [name stringByAppendingString:WFCString(@"Etc")];
                break;
            }
            name = [name stringByAppendingFormat:@",%@", userInfo.displayName];
        }
    }
    if (name.length == 0) {
        name = WFCString(@"GroupChat");
    }
    
    NSString *extraStr = [WFCCUtilities getGroupMemberExtra:GroupMemberSource_Invite sourceTargetId:[WFCCNetworkService sharedInstance].userId];
    [[WFCCIMService sharedWFCIMService] createGroup:nil name:name portrait:nil type:GroupType_Restricted groupExtra:nil members:memberIds memberExtra:extraStr notifyLines:@[@(0)] notifyContent:nil success:^(NSString *groupId) {
        NSLog(@"create group success");
        
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = [[WFCCConversation alloc] init];
        mvc.conversation.type = Group_Type;
        mvc.conversation.target = groupId;
        mvc.conversation.line = 0;
        
        mvc.hidesBottomBarWhenPushed = YES;
        [ws.navigationController pushViewController:mvc animated:YES];
    } error:^(int error_code) {
        NSLog(@"create group failure");
        [ws.view makeToast:WFCString(@"CreateGroupFailure")
                    duration:2
                    position:CSToastPositionCenter];

    }];
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
    self.definesPresentationContext = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[WFCUImage imageNamed:@"bar_plus"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGroupInfoUpdated:) name:kGroupInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onChannelInfoUpdated:) name:kChannelInfoUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSendingMessageStatusUpdated:) name:kSendingMessageStatusUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageUpdated:) name:kMessageUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretChatStateChanged:) name:kSecretChatStateUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSecretMessageBurned:) name:kSecretMessageBurned object:nil];
    
    self.firstAppear = YES;
}

- (void)updateConnectionStatus:(ConnectionStatus)status {
    [self updateTitle];
}

- (void)updateTitle {
    UIView *title;
    ConnectionStatus status = [WFCCNetworkService sharedInstance].currentConnectionStatus;
    if (status != kConnectionStatusConnecting && status != kConnectionStatusReceiving) {
        UILabel *navLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 40, 0, 80, 44)];
        
        switch (status) {
            case kConnectionStatusLogout:
                navLabel.text = WFCString(@"NotLogin");
                break;
            case kConnectionStatusConnected: {
                int count = 0;
                for (WFCCConversationInfo *info in self.conversations) {
                    if (!info.isSilent) {
                        count += info.unreadCount.unread;
                    }
                }
                if (count) {
                    navLabel.text = [NSString stringWithFormat:WFCString(@"NumberOfMessage"), count];
                } else {
                    navLabel.text = WFCString(@"Message");
                }
            }
                break;
                
            default:
            case kConnectionStatusUnconnected:
                navLabel.text = WFCString(@"NotConnect");
                break;
        }
        
        navLabel.textColor = [WFCUConfigManager globalManager].naviTextColor;
        navLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        
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
    [self updatePcSession];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    if ([messages count]) {
        [self refreshList];
        [self refreshLeftButton];
    }
}

- (void)onMessageUpdated:(NSNotification *)notification {
    [self refreshList];
    [self refreshLeftButton];
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

- (void)onDeleteMessages:(NSNotification *)notification {
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
    self.conversations = [[[WFCCIMService sharedWFCIMService] getConversationInfos:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0), @(5)]] mutableCopy];
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
    [self updateTitle];
}

- (void)updatePcSession {
    NSArray<WFCCPCOnlineInfo *> *onlines = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    
    if (@available(iOS 11.0, *)) {
        if (onlines.count && [WFCCNetworkService sharedInstance].currentConnectionStatus == kConnectionStatusConnected) {
            self.tableView.tableHeaderView = self.pcSessionView;
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"wfc_uikit_had_pc_session"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
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
    
    if ([KxMenu isShowing]) {
        [KxMenu dismissMenu];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.firstAppear) {
        self.firstAppear = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConnectionStatusChanged:) name:kConnectionStatusChanged object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRecallMessages:) name:kRecallMessages object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeleteMessages:) name:kDeleteMessages object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onSettingUpdated:) name:kSettingUpdated object:nil];
    }
    
    [self updateConnectionStatus:[WFCCNetworkService sharedInstance].currentConnectionStatus];
    [self refreshList];
    [self refreshLeftButton];
    [self updatePcSession];
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
        WFCCUnreadCount *unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadCount:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
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
        BOOL darkMode = NO;
        if (@available(iOS 13.0, *)) {
            if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                darkMode = YES;
            }
        }
        UIColor *bgColor;
        if (darkMode) {
            bgColor = [WFCUConfigManager globalManager].backgroudColor;
        } else {
            bgColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        }
        
        _pcSessionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        [_pcSessionView setBackgroundColor:bgColor];
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 4, 32, 32)];
        iv.image = [WFCUImage imageNamed:@"pc_session"];
        [_pcSessionView addSubview:iv];
        self.pcSessionLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 10, self.view.bounds.size.width - 68 - 16, 20)];
        self.pcSessionLabel.font = [UIFont systemFontOfSize:16];
        [_pcSessionView addSubview:self.pcSessionLabel];
        _pcSessionView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapPCBar:)];
        [_pcSessionView addGestureRecognizer:tap];
    }
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    self.pcSessionLabel.text = nil;
    if (infos.count) {
        if (infos[0].platform == PlatformType_Windows) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Windows %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_OSX) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Mac %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_Linux) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Linux %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_HarmonyPC) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"鸿蒙电脑 %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_WEB) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"Web %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_WX) {
            self.pcSessionLabel.text = [NSString stringWithFormat:WFCString(@"%@LoggedIn"), WFCString(@"MicroApp")];
        } else if(infos[0].platform == PlatformType_iPad) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"iPad %@", WFCString(@"LoggedIn")];
        } else if(infos[0].platform == PlatformType_APad) {
            self.pcSessionLabel.text = [NSString stringWithFormat:WFCString(@"%@LoggedIn"), WFCString(@"AndroidPad")];
        } else if(infos[0].platform == PlatformType_HarmonyPad) {
            self.pcSessionLabel.text = [NSString stringWithFormat:@"鸿蒙平板 %@", WFCString(@"LoggedIn")];
        }
        if(self.pcSessionLabel.text.length && [[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
            self.pcSessionLabel.text = [self.pcSessionLabel.text stringByAppendingFormat:@"，%@", WFCString(@"MobileNoNotification")];
        }
    }
    
    return _pcSessionView;
}

- (void)onTapPCBar:(id)sender {
    NSArray<WFCCPCOnlineInfo *> *onlines = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if ([[WFCUConfigManager globalManager].appServiceProvider respondsToSelector:@selector(showPCSessionViewController:pcClient:)] && onlines.count) {
        [[WFCUConfigManager globalManager].appServiceProvider showPCSessionViewController:self pcClient:[onlines objectAtIndex:0]];
    }
    
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
                if (self.isSearchFriendListExpansion) {
                    return self.searchFriendList.count;
                } else {
                    if (self.searchFriendList.count > 2) {
                        return 3;
                    } else {
                        return self.searchFriendList.count;
                    }
                }
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (section == sec-1) {
                if (self.isSearchGroupListExpansion) {
                    return self.searchGroupList.count;
                } else {
                    if (self.searchGroupList.count > 2) {
                        return 3;
                    } else {
                        return self.searchGroupList.count;
                    }
                }
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == section) {
                
                if (self.isSearchConversationListExpansion) {
                    return self.searchConversationList.count;
                } else {
                    if (self.searchConversationList.count > 2) {
                        return 3;
                    } else {
                        return self.searchConversationList.count;
                    }
                }
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
                if (self.isSearchFriendListExpansion) {
                    WFCUContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                    if (cell == nil) {
                        cell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                    }
                    cell.big = NO;
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    [cell setUserId:self.searchFriendList[indexPath.row].userId groupId:nil];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchFriendList.count - 2];
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        WFCUContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell"];
                        if (cell == nil) {
                            cell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendCell"];
                        }
                        cell.big = NO;
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                            
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }
                        [cell setUserId:self.searchFriendList[indexPath.row].userId groupId:nil];
                        return cell;
                    }
                }
                
            }
        }
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                
                if (self.isSearchGroupListExpansion) {
                    WFCUSearchGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                    if (cell == nil) {
                        cell = [[WFCUSearchGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                    }
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    
                    cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchGroupList.count - 2];
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        WFCUSearchGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupCell"];
                        if (cell == nil) {
                            cell = [[WFCUSearchGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupCell"];
                        }
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                            
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }
                        cell.groupSearchInfo = self.searchGroupList[indexPath.row];
                        return cell;
                    }
                }
                
            }
        }
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section) {
                if (self.isSearchConversationListExpansion) {
                    WFCUConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchConversationCell"];
                    if (cell == nil) {
                        cell = [[WFCUConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchConversationCell"];
                    }
                    cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                    cell.big = NO;
                    
                    cell.searchInfo = self.searchConversationList[indexPath.row];
                    return cell;
                } else {
                    if (indexPath.row == 2) {
                        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"expansion" forIndexPath:indexPath];
                        cell.textLabel.textColor = [UIColor colorWithHexString:@"5b6e8e"];
                        cell.textLabel.text = [NSString stringWithFormat:@"点击展开剩余%lu项", self.searchConversationList.count - 2];
                        cell.textLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:12];
                        return cell;
                    } else {
                        WFCUConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchConversationCell"];
                        if (cell == nil) {
                            cell = [[WFCUConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"searchConversationCell"];
                        }
                        if (indexPath.row == 1) {
                            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
                            
                        } else {
                            cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                            
                        }                           cell.big = NO;
                        
                        cell.searchInfo = self.searchConversationList[indexPath.row];
                        return cell;
                    }
                }
                
            }
        }
        
        return nil;
    } else {
        WFCUConversationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"conversationCell"];
        if (cell == nil) {
            cell = [[WFCUConversationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"conversationCell"];
        }
        cell.big = YES;
        cell.separatorInset = UIEdgeInsetsMake(0, 76, 0, 0);
        cell.info = self.conversations[indexPath.row];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                if (self.isSearchFriendListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        
        if (self.searchGroupList.count) {
            sec++;
            if (indexPath.section  == sec-1) {
                if (self.isSearchGroupListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        
        if (self.searchConversationList.count) {
            sec++;
            if (sec-1 == indexPath.section ) {
                
                if (self.isSearchConversationListExpansion) {
                    return 60;
                } else {
                    if (indexPath.row == 2) {
                        return 40;
                    } else {
                        return 60;
                    }
                }
            }
        }
        return 60;
    } else {
        return 72;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.searchController.isActive) {
        
        if (self.searchConversationList.count + self.searchGroupList.count + self.searchFriendList.count > 0) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
            header.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
            
            label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
            label.textColor = [UIColor colorWithHexString:@"0x828282"];
            label.textAlignment = NSTextAlignmentLeft;
            
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
        return 32;
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
    UITableViewRowAction *markAsUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"MarkAsUnread") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] markAsUnRead:ws.conversations[indexPath.row].conversation syncToOtherClient:YES];
        [ws refreshList];
    }];
    
    UITableViewRowAction *clearUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"MarkAsRead") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [ws refreshList];
    }];
    
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Delete") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [[WFCCIMService sharedWFCIMService] removeConversation:ws.conversations[indexPath.row].conversation clearMessage:YES];
        [ws.conversations removeObjectAtIndex:indexPath.row];
        [ws updateBadgeNumber];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    UITableViewRowAction *setTop = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"Pinned") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:1 success:^{
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
        [[WFCCIMService sharedWFCIMService] setConversation:ws.conversations[indexPath.row].conversation top:0 success:^{
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
    clearUnread.backgroundColor = [UIColor blueColor];
    markAsUnread.backgroundColor = [UIColor blueColor];
    
    if(self.conversations[indexPath.row].unreadCount.unread) {
        if (self.conversations[indexPath.row].isTop) {
            return @[delete, setUntop, clearUnread];
        } else {
            return @[delete, setTop, clearUnread];
        }
    } else {
        NSArray<WFCCMessage *> *readedMsgs = [[WFCCIMService sharedWFCIMService] getMessages:self.conversations[indexPath.row].conversation messageStatus:@[@(Message_Status_Readed), @(Message_Status_Played)] from:0 count:1 withUser:nil];
        if(readedMsgs.count) {
            if (self.conversations[indexPath.row].isTop) {
                return @[delete, setUntop, markAsUnread];
            } else {
                return @[delete, setTop, markAsUnread];
            }
        } else {
            if (self.conversations[indexPath.row].isTop) {
                return @[delete, setUntop];
            } else {
                return @[delete, setTop];
            }
        }
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
                if (!self.isSearchFriendListExpansion && indexPath.row == 2) {
                    self.isSearchFriendListExpansion = YES;
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
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
        }
        
        if (self.searchGroupList.count) {
            sec++;

            if (indexPath.section == sec-1) {
                if (!self.isSearchGroupListExpansion && indexPath.row == 2) {
                    self.isSearchGroupListExpansion = YES;
                      NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                      [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
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
        }
        
        if (self.searchConversationList.count) {
            sec++;


            if (sec-1 == indexPath.section) {
                if (!self.isSearchConversationListExpansion && indexPath.row == 2) {
                    self.isSearchConversationListExpansion = YES;
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
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
    self.searchController.view.frame = self.view.bounds;
    self.isSearchFriendListExpansion = NO;
    self.isSearchConversationListExpansion = NO;
    self.isSearchGroupListExpansion = NO;
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (NSArray<WFCCUserInfo *> *)searchFriends:(NSString *)searchString {
    NSMutableArray<WFCCUserInfo *> *result = [[NSMutableArray alloc] init];
    if(searchString.length) {
        WFCUPinyinUtility *pu = [[WFCUPinyinUtility alloc] init];
        NSArray<WFCCUserInfo *> *dataArray = [[WFCCIMService sharedWFCIMService] getUserInfos:[[WFCCIMService sharedWFCIMService] getMyFriendList:NO] inGroup:nil];
        BOOL isChinese = [pu isChinese:searchString];
        for (WFCCUserInfo *friend in dataArray) {
            if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.friendAlias.lowercaseString containsString:searchString.lowercaseString]) {
                [result addObject:friend];
            } else if(!isChinese) {
                if([pu isMatch:friend.displayName ofPinYin:searchString] || [pu isMatch:friend.friendAlias ofPinYin:searchString]) {
                    [result addObject:friend];
                }
            }
        }
    }
    return result;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        self.searchConversationList = [[WFCCIMService sharedWFCIMService] searchConversation:searchString inConversation:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
        self.searchFriendList = [self searchFriends:searchString];
        self.searchGroupList = [[WFCCIMService sharedWFCIMService] searchGroups:searchString];
    } else {
        self.searchConversationList = nil;
        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }
    
    [self.tableView reloadData];
}
@end
