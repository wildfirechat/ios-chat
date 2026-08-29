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
#import "WFCUPadUtility.h"
#import "WFCUPadSearchResultViewController.h"


@interface WFCUConversationTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, WFCUPadSearchResultDelegate>
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
@property (nonatomic, strong) UIImageView *pcSessionIconView;

// 搜索历史
@property (nonatomic, strong) UITableView *historyTableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchHistory;
@property (nonatomic, strong) UIView *historyContainer;
@property (nonatomic, assign) BOOL showingHistory;

//iPad 双栏布局下右侧正在展示的会话，用于保持左侧列表的选中态
@property (nonatomic, strong) WFCCConversation *padSelectedConversation;
//它压在哪条栈上。五个 tab 各一条栈，会话可能压在一条已经切走的栈上，只记「有没有」不够
//（android 那边同样单记了一个 selectedConversationTab）。
@property (nonatomic, assign) NSInteger padSelectedTabIndex;
//它在左栏列表里出现过。新建的会话在发出首条消息前本来就不在列表里，
//不先确认「来过」就清栏，会把刚点开的新会话立刻关掉（android: selectedSeenInList）。
@property (nonatomic, assign) BOOL padSelectedSeenInList;

//iPad 双栏布局下承载搜索结果的右栏页面。非 nil 即表示「搜索结果在右栏」这一形态生效中，
//此时左栏那张表始终是会话列表，不再被搜索结果顶掉。
@property (nonatomic, strong) WFCUPadSearchResultViewController *padSearchVC;

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

        // 监听搜索框的焦点变化
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
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
    //双栏下这条搜索框只是一颗按钮：点它不取焦点，只把搜索页压进右栏，
    //输入框长在那张页面上（见 WFCUPadSearchResultViewController）。
    [WFCUPadUtility installSearchTriggerOnSearchBar:_searchController.searchBar
                                             target:self
                                             action:@selector(onPadSearchEntryTapped)];

    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;

    // 初始化搜索历史
    self.searchHistory = [self loadSearchHistory];
}

//是否正在搜索。双栏下搜索框长在右栏那张搜索页上，searchController 根本不会 active；
//单栏（含 iPhone）下 padSearchVC 恒为 nil，取值与 `searchController.active` 逐字节相同。
- (BOOL)isSearching {
    return self.padSearchVC != nil || self.searchController.active;
}

//当前那条搜索框。双栏下在右栏那张搜索页上，单栏（含 iPhone）下是左栏导航条里那条。
- (UISearchBar *)activeSearchBar {
    return self.padSearchVC ? self.padSearchVC.searchBar : self.searchController.searchBar;
}

//当前的搜索关键字
- (NSString *)currentSearchText {
    return [[self activeSearchBar] text];
}

//搜索历史那块浮层挂在谁身上。双栏下挂右栏那条导航栈的 view ——
//挂左栏会被 320 宽的栏切掉，而且它要盖住的是搜索结果，不是会话列表。
- (UIView *)searchHistoryHostView {
    if (self.padSearchVC) {
        return self.padSearchVC.navigationController.view ?: self.padSearchVC.view;
    }
    return self.navigationController.view;
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    if ([self isSearching]) {
        [self reloadSearchResultTableView];
    }
}

- (void)onGroupInfoUpdated:(NSNotification *)notification {
    if ([self isSearching]) {
        [self reloadSearchResultTableView];
    }
}

- (void)onChannelInfoUpdated:(NSNotification *)notification {
    if ([self isSearching]) {
        [self reloadSearchResultTableView];
    } 
}

- (void)onSendingMessageStatusUpdated:(NSNotification *)notification {
    if ([self isSearching]) {
        [self reloadSearchResultTableView];
        //单栏下左栏这张表此刻显示的就是搜索结果，下面那段按会话下标取行会错位；
        //双栏下搜索结果在右栏，左栏仍是会话列表，照常往下更新
        if (!self.padSearchVC) {
            return;
        }
    }
    {
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
    NSString *targetId = notification.object;
    [self.conversations enumerateObjectsUsingBlock:^(WFCCConversationInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.conversation.type == SecretChat_Type && [obj.conversation.target isEqualToString:targetId]) {
            [self.conversations removeObjectAtIndex:idx];
            [self.conversations addObject:[[WFCCIMService sharedWFCIMService] getConversationInfo:obj.conversation]];
            [self sortAndReloadConversationList];
            *stop = YES;
        }
    }];
    [self refreshLeftButton];
}

- (void)onSecretMessageBurned:(NSNotification *)notification {
    NSString *targetId = notification.object;
    [self.conversations enumerateObjectsUsingBlock:^(WFCCConversationInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.conversation.type == SecretChat_Type && [obj.conversation.target isEqualToString:targetId]) {
            [self.conversations removeObjectAtIndex:idx];
            [self.conversations addObject:[[WFCCIMService sharedWFCIMService] getConversationInfo:obj.conversation]];
            [self sortAndReloadConversationList];
            *stop = YES;
        }
    }];
    [self refreshLeftButton];
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
    CGFloat searchExtra = 0;
    
    if ([KxMenu isShowing]) {
        [KxMenu dismissMenu];
        return;
    }
    NSMutableArray *menuItems = [NSMutableArray array];
    [menuItems addObject:[KxMenuItem menuItem:WFCString(@"StartChat")
                           image:[WFCUImage imageNamed:@"menu_start_chat"]
                          target:self
                          action:@selector(startChatAction:)]];
    if ([[WFCCIMService sharedWFCIMService] isEnableSecretChat] && [[WFCCIMService sharedWFCIMService] isUserEnableSecretChat]) {
        [menuItems addObject:[KxMenuItem menuItem:WFCString(@"StartSecretChat")
                               image:[WFCUImage imageNamed:@"menu_start_chat"]
                              target:self
                              action:@selector(startSecretChatAction:)]];
    }
    [menuItems addObject:[KxMenuItem menuItem:WFCString(@"AddFriend")
                           image:[WFCUImage imageNamed:@"menu_add_friends"]
                          target:self
                          action:@selector(addFriendsAction:)]];
    [menuItems addObject:[KxMenuItem menuItem:WFCString(@"SubscribeChannel")
                           image:[WFCUImage imageNamed:@"menu_listen_channel"]
                          target:self
                          action:@selector(listenChannelAction:)]];
    NSString *dialinRobotId = [WFCUConfigManager globalManager].dialinRobotId;
    if (dialinRobotId.length) {
        [menuItems addObject:[KxMenuItem menuItem:@"落地电话"
                               image:[WFCUImage imageNamed:@"msg_audio_call"]
                              target:self
                              action:@selector(dialinAction:)]];
    }
    [menuItems addObject:[KxMenuItem menuItem:WFCString(@"ScanQRCode")
                           image:[WFCUImage imageNamed:@"menu_scan_qr"]
                          target:self
                          action:@selector(scanQrCodeAction:)]];
    
    
    [KxMenu showMenuInView:self.navigationController.view
                  fromRect:CGRectMake(self.view.bounds.size.width - 56, [WFCUUtilities wf_navigationFullHeight] + searchExtra, 48, 5)
                 menuItems:menuItems];
}

- (void)dialinAction:(id)sender {
    void (^handler)(UIViewController *) = [WFCUConfigManager globalManager].dialinRobotHandler;
    if (handler) {
        handler(self);
    }
}

- (void)startChatAction:(id)sender {
    WFCUSeletedUserViewController *pvc = [[WFCUSeletedUserViewController alloc] init];
    pvc.type = Horizontal;

    //双栏下选人页进右栏，不再全屏模态盖住整个窗口。对应 android 把 CreateConversationActivity
    //登记进 PaneRegistry 的那一条。会话建好之后用 replacePage 顶掉选人页
    //（android `TwoPaneNavigator.replacePage`：「从『发起群聊』的选人页建完群，选人页就该消失」）——
    //从新会话返回时应当回到欢迎页，而不是回到那张已经用完的选人表。
    //页面 key 取类名（android 那边写作 CreateConversationActivity.class.getName()）：
    //连点两次「+ → 发起聊天」不会在右栏叠出两张选人表。
    if ([WFCUPadUtility isSplitLayoutActive]) {
        __weak typeof(self)ws = self;
        pvc.wfcu_padPageKey = NSStringFromClass([WFCUSeletedUserViewController class]);
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            if (contacts.count == 1) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                mvc.conversation = [WFCCConversation conversationWithType:Single_Type target:contacts[0] line:0];
                [WFCUPadUtility replaceDetailViewController:mvc animated:YES];
            } else {
                [ws createGroup:contacts];
            }
        };
        [WFCUPadUtility showDetailViewController:pvc];
        return;
    }

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

    //与 startChatAction: 同一条规则，见那里的注释。密聊建好之后同样顶掉选人页。
    if ([WFCUPadUtility isSplitLayoutActive]) {
        pvc.wfcu_padPageKey = [NSStringFromClass([WFCUSeletedUserViewController class]) stringByAppendingString:@":secret"];
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            if (contacts.count != 1) {
                return;
            }
            [[WFCCIMService sharedWFCIMService] createSecretChat:contacts[0] success:^(NSString *targetId, int line) {
                WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
                mvc.conversation = [WFCCConversation conversationWithType:SecretChat_Type target:targetId line:line];
                [WFCUPadUtility replaceDetailViewController:mvc animated:YES];
            } error:^(int error_code) {
                
            }];
        };
        [WFCUPadUtility showDetailViewController:pvc];
        return;
    }

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
        //双栏下建完的群会话顶掉右栏栈顶那张选人页（android `replacePage`：
        //「从『发起群聊』的选人页建完群，选人页就该消失」），从群会话返回时回到欢迎页。
        //走左栏的导航栈不行：那会被 WFCUPadPrimaryNavigationController 当成「换内容」而清到栈底。
        if ([WFCUPadUtility replaceDetailViewController:mvc animated:YES]) {
            return;
        }
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

- (void)sortAndReloadConversationList {
    [self.conversations sortUsingComparator:^NSComparisonResult(WFCCConversationInfo*  _Nonnull obj1, WFCCConversationInfo*  _Nonnull obj2) {
        if(obj1.isTop > obj2.isTop) {
            return NSOrderedAscending;
        } else if(obj1.isTop < obj2.isTop) {
            return NSOrderedDescending;
        } else {
            if(obj1.timestamp > obj2.timestamp) {
                return NSOrderedAscending;
            } else if(obj1.timestamp < obj2.timestamp) {
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
    }];
    
    [self.tableView reloadData];
    [self updateBadgeNumber];
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    if ([messages count]) {
        NSMutableSet<WFCCConversation *> *updatedConversations = [[NSMutableSet alloc] init];
        [messages enumerateObjectsUsingBlock:^(WFCCMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(obj.messageId != 0) {
                [updatedConversations addObject:obj.conversation];
            }
        }];
        if(updatedConversations.count) {
            [updatedConversations enumerateObjectsUsingBlock:^(WFCCConversation * _Nonnull converation, BOOL * _Nonnull stop1) {
                [self.conversations enumerateObjectsUsingBlock:^(WFCCConversationInfo * _Nonnull conversationInfo, NSUInteger idx, BOOL * _Nonnull stop2) {
                    if([conversationInfo.conversation isEqual:converation]) {
                        [self.conversations removeObjectAtIndex:idx];
                        *stop2 = YES;
                    }
                }];
                WFCCConversationInfo *conversationInfo = [[WFCCIMService sharedWFCIMService] getConversationInfo:converation];
                [self.conversations addObject:conversationInfo];
            }];
            [self sortAndReloadConversationList];
        }
        
        [self refreshLeftButton];
    }
}

- (void)updateConversationListForMessage:(WFCCMessage *)message {
    __block BOOL updated = NO;
    [self.conversations enumerateObjectsUsingBlock:^(WFCCConversationInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.conversation isEqual:message.conversation]) {
            [self.conversations removeObjectAtIndex:idx];
            WFCCConversationInfo *conversationInfo = [[WFCCIMService sharedWFCIMService] getConversationInfo:message.conversation];
            [self.conversations addObject:conversationInfo];
            updated = YES;
            *stop = YES;
        }
    }];
    if(updated) {
        [self sortAndReloadConversationList];
    }
}

- (void)onMessageUpdated:(NSNotification *)notification {
    long messageId = [notification.object longValue];
    [self updateConversationListForMessage:[[WFCCIMService sharedWFCIMService] getMessage:messageId]];
    [self refreshLeftButton];
}

- (void)onSettingUpdated:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshList];
        [self refreshLeftButton];
        [self updatePcSession];
    });
}

- (void)onJoinGroupRequestUpdated:(NSNotification *)notification {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshList];
        [self refreshLeftButton];
        [self updatePcSession];
    });
}

- (void)onRecallMessages:(NSNotification *)notification {
    long long messageUid = [notification.object longLongValue];
    [self updateConversationListForMessage:[[WFCCIMService sharedWFCIMService] getMessageByUid:messageUid]];
    [self refreshLeftButton];
}

- (void)onDeleteMessages:(NSNotification *)notification {
    long long messageUid = [notification.object longLongValue];
    __block BOOL updated = NO;
    [self.conversations enumerateObjectsUsingBlock:^(WFCCConversationInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.lastMessage.messageUid == messageUid) {
            *stop = YES;
            [self.conversations removeObjectAtIndex:idx];
            [self.conversations addObject:[[WFCCIMService sharedWFCIMService] getConversationInfo:obj.conversation]];
            updated = YES;
            
        }
    }];
    if(updated) {
        [self.tableView reloadData];
        [self updateBadgeNumber];
    }
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
    [self padCheckSelectedConversationAlive];
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onJoinGroupRequestUpdated:) name:kJoinGroupRequestUpdated object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPadDetailChanged:) name:WFCUPadDetailDidChangeNotification object:nil];
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //分栏形态会变（旋转、Stage Manager、Slide Over），同步一下顶上那条搜索框能不能取焦点
    [WFCUPadUtility syncSearchTriggerOnSearchBar:self.searchController.searchBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.searchController.isActive && ![WFCUPadUtility isSplitLayoutActive]) {
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
        
        _pcSessionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [_pcSessionView setBackgroundColor:bgColor];
        self.pcSessionIconView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 24, 24)];
        self.pcSessionIconView.tintColor = [UIColor colorWithHexString:@"0x666666"];
        [_pcSessionView addSubview:self.pcSessionIconView];
        self.pcSessionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 24 + 10, 12, self.view.bounds.size.width - 16 - 24 - 10 - 16, 20)];
        self.pcSessionLabel.font = [UIFont scaledSystemFontOfSize:15];
        self.pcSessionLabel.textColor = [UIColor colorWithHexString:@"0x666666"];
        [_pcSessionView addSubview:self.pcSessionLabel];
        _pcSessionView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapPCBar:)];
        [_pcSessionView addGestureRecognizer:tap];
    }
    NSArray<WFCCPCOnlineInfo *> *infos = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    self.pcSessionLabel.text = nil;
    if (infos.count) {
        if (infos.count == 1) {
            // 单台设备：显示对应平台的图标和名称
            WFCCPCOnlineInfo *info = infos[0];
            self.pcSessionIconView.image = [self pcPlatformIcon:info];
            self.pcSessionLabel.text = [NSString stringWithFormat:@"%@ %@", [self pcPlatformName:info], WFCString(@"LoggedIn")];
            if ([[WFCCIMService sharedWFCIMService] isMuteNotificationWhenPcOnline]) {
                self.pcSessionLabel.text = [self.pcSessionLabel.text stringByAppendingFormat:@"，%@", WFCString(@"MobileNoNotification")];
            }
        } else {
            // 多台设备：统一显示电脑图标，文案为「N个设备已经登录」
            self.pcSessionIconView.image = [self pcPlatformIcon:nil];
            self.pcSessionLabel.text = [NSString stringWithFormat:@"%lu%@", (unsigned long)infos.count, WFCString(@"DevicesLoggedIn")];
        }
    }
    
    return _pcSessionView;
}

// 平台名称（微信风格）：保留现有映射并补充缺失平台，platform 未上报(UNSET)时按在线类型兜底
- (NSString *)pcPlatformName:(WFCCPCOnlineInfo *)info {
    switch (info.platform) {
        case PlatformType_Windows:
            return @"Windows";
        case PlatformType_OSX:
            return @"Mac";
        case PlatformType_Linux:
            return @"Linux";
        case PlatformType_HarmonyPC:
            return WFCString(@"HarmonyOSPC");
        case PlatformType_WEB:
            return @"Web";
        case PlatformType_WX:
            return WFCString(@"MicroApp");
        case PlatformType_iPad:
            return @"iPad";
        case PlatformType_APad:
        case PlatformType_Android:
            return WFCString(@"AndroidPad");
        case PlatformType_HarmonyPad:
            return WFCString(@"HarmonyOSPad");
        default:
            break;
    }
    if (info.type == Web_Online) {
        return @"Web";
    }
    if (info.type == WX_Online) {
        return WFCString(@"MicroApp");
    }
    if (info.type == Pad_Online) {
        return WFCString(@"PlatformPad");
    }
    return WFCString(@"PlatformComputer");
}

// 平台灰色图标：单台设备按平台显示（电脑/浏览器/手机/平板），多台设备（info 为 nil）统一显示电脑图标
- (UIImage *)pcPlatformIcon:(WFCCPCOnlineInfo *)info {
    NSString *symbol = @"desktopcomputer";
    if (info) {
        switch (info.platform) {
            case PlatformType_Windows:
            case PlatformType_OSX:
            case PlatformType_Linux:
            case PlatformType_HarmonyPC:
                symbol = @"desktopcomputer";
                break;
            case PlatformType_WEB:
                symbol = @"globe";
                break;
            case PlatformType_WX:
                symbol = @"iphone";
                break;
            case PlatformType_iPad:
            case PlatformType_APad:
            case PlatformType_HarmonyPad:
                symbol = @"ipad";
                break;
            default: {
                if (info.type == Web_Online) {
                    symbol = @"globe";
                } else if (info.type == WX_Online) {
                    symbol = @"iphone";
                } else if (info.type == Pad_Online) {
                    symbol = @"ipad";
                }
                break;
            }
        }
    }
    UIImage *image = nil;
    if (@available(iOS 13.0, *)) {
        image = [UIImage systemImageNamed:symbol];
    }
    if (!image) {
        image = [WFCUImage imageNamed:@"pc_session"];
    }
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)onTapPCBar:(id)sender {
    NSArray<WFCCPCOnlineInfo *> *onlines = [[WFCCIMService sharedWFCIMService] getPCOnlineInfos];
    if ([[WFCUConfigManager globalManager].appServiceProvider respondsToSelector:@selector(showPCSessionViewController:pcOnlineInfos:)] && onlines.count) {
        // 传入全部在线设备
        [[WFCUConfigManager globalManager].appServiceProvider showPCSessionViewController:self pcOnlineInfos:onlines];
    }
    
}

- (void)onTabbarItemDoubleClicked {
    //双击tabbar，跳到下一个会话
    if (self.conversations.count == 0) {
        return;
    }

    NSInteger currentRow = 0;
    if (self.tableView.indexPathsForVisibleRows.count > 0) {
        currentRow = self.tableView.indexPathsForVisibleRows.lastObject.row;
    }
    
    for (int i = currentRow; i < self.conversations.count; i++) {
        if(!self.conversations[i].isSilent && self.conversations[i].unreadCount.unread > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i==self.conversations.count-1?i:i+1 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            return;
        }
    }
}

#pragma mark - 搜索结果渲染在哪张表上

//双栏下搜索结果在右栏那张表上，左栏那张表始终是会话列表；单栏下仍是老样子——
//同一张表按 searchController.active 在两种内容之间切。
- (BOOL)isSearchTableView:(UITableView *)tableView {
    if (self.padSearchVC) {
        return tableView == self.padSearchVC.tableView;
    }
    return self.searchController.active;
}

- (void)reloadSearchResultTableView {
    [(self.padSearchVC ? self.padSearchVC.tableView : self.tableView) reloadData];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.historyTableView) {
        return 1;
    }
    if (![self isSearchTableView:tableView]) {
        //会话列表恒为一个 section。单栏下不搜索时三个搜索结果数组都是空的，
        //走下面那段算出来同样是 1，逐字节等价。
        return 1;
    }
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
    if (tableView == self.historyTableView) {
        return self.searchHistory.count;
    }

    if ([self isSearchTableView:tableView]) {
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
    // 处理历史记录表格
    if (tableView == self.historyTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"historyCell" forIndexPath:indexPath];

        // 清除旧内容
        for (UIView *subview in cell.contentView.subviews) {
            [subview removeFromSuperview];
        }

        // 创建文本标签
        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, cell.bounds.size.width - 60, 44)];
        textLabel.text = self.searchHistory[indexPath.row];
        textLabel.font = [UIFont scaledSystemFontOfSize:15];
        textLabel.textColor = [UIColor blackColor];
        textLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textLabel];

        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        // 添加删除按钮到contentView
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [deleteButton setTitle:@"✕" forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [UIFont scaledBoldSystemFontOfSize:18];
        deleteButton.frame = CGRectMake(cell.bounds.size.width - 44, 0, 44, 44);
        deleteButton.tintColor = [UIColor grayColor];
        deleteButton.tag = indexPath.row; // 使用行号作为tag
        deleteButton.exclusiveTouch = YES; // 确保触摸事件被这个按钮独占
        [deleteButton addTarget:self action:@selector(deleteHistoryItem:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:deleteButton];

        return cell;
    }

    // 原有的搜索结果逻辑
    if ([self isSearchTableView:tableView]) {
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
                        cell.textLabel.text = [NSString stringWithFormat:WFCString(@"ClickToExpandItems"), self.searchFriendList.count - 2];
                        cell.textLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:12];
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
                        cell.textLabel.text = [NSString stringWithFormat:WFCString(@"ClickToExpandItems"), self.searchGroupList.count - 2];
                        cell.textLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:12];
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
                        cell.textLabel.text = [NSString stringWithFormat:WFCString(@"ClickToExpandItems"), self.searchConversationList.count - 2];
                        cell.textLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:12];
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
    // 历史记录表格使用44的固定高度
    if (tableView == self.historyTableView) {
        return 44;
    }

    if ([self isSearchTableView:tableView]) {
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
        // 主会话列表行高轻微跟随字体变化，避免跳动过大
        CGFloat fontScale = [WFCUConfigManager globalManager].fontScale;
        return 72 + (fontScale - 1.0) * 4;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.historyTableView) {
        return nil;
    }
    
    if ([self isSearchTableView:tableView]) {
        
        if (self.searchConversationList.count + self.searchGroupList.count + self.searchFriendList.count > 0) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
            header.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.tableView.frame.size.width, 32)];
            
            label.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:13];
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
    if (tableView == self.historyTableView) {
        return 0;
    }
    if ([self isSearchTableView:tableView]) {
        return 32;
    }
    return 0;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.historyTableView) {
        return NO;
    }
    // Return NO if you do not want the specified item to be editable.
    if ([self isSearchTableView:tableView]) {
        return NO;
    }
    return YES;
}

- (void)reloadConversationAtIndex:(NSUInteger)index {
    WFCCConversation *conversation = self.conversations[index].conversation;
    [self.conversations removeObjectAtIndex:index];
    [self.conversations addObject:[[WFCCIMService sharedWFCIMService] getConversationInfo:conversation]];
    [self sortAndReloadConversationList];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) ws = self;
    UITableViewRowAction *markAsUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"MarkAsUnread") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] markAsUnRead:ws.conversations[indexPath.row].conversation syncToOtherClient:YES];
        [ws reloadConversationAtIndex:indexPath.row];
    }];
    
    UITableViewRowAction *clearUnread = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:WFCString(@"MarkAsRead") handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        [[WFCCIMService sharedWFCIMService] clearUnreadStatus:ws.conversations[indexPath.row].conversation];
        [ws reloadConversationAtIndex:indexPath.row];
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
            [ws reloadConversationAtIndex:indexPath.row];
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
            [ws reloadConversationAtIndex:indexPath.row];
        } error:^(int error_code) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:ws.view animated:NO];
            hud.label.text = WFCString(@"UpdateFailure");
            hud.mode = MBProgressHUDModeText;
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:NO afterDelay:1.5];
        }];
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
    // 历史记录表格不需要处理
    if (scrollView == self.historyTableView) {
        return;
    }

    if (self.padSearchVC) {
        //双栏下搜索框在右栏那张页面上，只有拖它自己那张结果表才收键盘
        if (scrollView == self.padSearchVC.tableView) {
            [self.padSearchVC.searchBar resignFirstResponder];
        }
        return;
    }
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 处理历史记录点击
    if (tableView == self.historyTableView) {
        NSString *searchText = self.searchHistory[indexPath.row];

        // 设置搜索框文本并触发搜索
        if (self.padSearchVC) {
            self.padSearchVC.searchBar.text = searchText;
        } else if (@available(iOS 13.0, *)) {
            self.searchController.searchBar.searchTextField.text = searchText;
        } else {
            self.searchController.searchBar.text = searchText;
        }

        [self hideSearchHistory];

        // 触发搜索
        [self performSearchWithText:searchText];
        return;
    }

    // 原有的逻辑
    if ([self isSearchTableView:tableView]) {
        // 点击搜索结果时保存搜索历史
        NSString *searchString = [self currentSearchText];
        if (searchString.length > 0) {
            [self addSearchHistory:searchString];
        }

        int sec = 0;
        if (self.searchFriendList.count) {
            sec++;
            if (indexPath.section == sec-1) {
                if (!self.isSearchFriendListExpansion && indexPath.row == 2) {
                    self.isSearchFriendListExpansion = YES;
                    NSIndexSet *set = [NSIndexSet indexSetWithIndex:indexPath.section];
                    [tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
                } else {
                    WFCCUserInfo *info = self.searchFriendList[indexPath.row];
                    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
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
                      [tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
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
                    [tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
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
        WFCCConversationInfo *info = self.conversations[indexPath.row];
        if ([WFCUPadUtility isSplitLayoutActive]) {
            //右侧已经是这个会话了就不重建，否则会丢失滚动位置和草稿输入状态
            if ([self isPadSelectedConversation:info.conversation]) {
                return;
            }
            self.padSelectedConversation = info.conversation;
        } else {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
        mvc.conversation = info.conversation;
        mvc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:mvc animated:YES];
    }
}

#pragma mark - iPad 双栏选中态

static BOOL WFCUIsSameConversation(WFCCConversation *a, WFCCConversation *b) {
    if (!a || !b) {
        return NO;
    }
    return a.type == b.type && a.line == b.line && [a.target isEqualToString:b.target];
}

- (BOOL)isPadSelectedConversation:(WFCCConversation *)conversation {
    //R7：高亮只跟消息 tab 走 —— 当前 tab 不是消息时，右栏挂的是别的 tab 那条栈，
    //跟这张列表没有关系，左栏就没有可高亮的行。
    //切 tab 会走 syncDetailStackForCurrentTab 发一次通知，高亮跟着重算，回到消息 tab 时会亮回来。
    if (self.tabBarController && self.tabBarController.selectedViewController != self.navigationController) {
        return NO;
    }
    return WFCUIsSameConversation(self.padSelectedConversation, conversation);
}

//R7：右栏打开的会话从列表里消失了（删除会话、退群）→ 把它所在的那一栏退回欢迎页。
//对应 android `TwoPaneNavigator.onConversationListChanged`，连守卫一起照搬：
//必须先确认它「在列表里出现过」——新建的会话在发出第一条消息之前本来就不在列表里，
//不守这一下，刚点开的新会话会被立刻关掉。
- (void)padCheckSelectedConversationAlive {
    if (!self.padSelectedConversation || ![WFCUPadUtility isSplitLayoutActive]) {
        return;
    }
    for (WFCCConversationInfo *info in self.conversations) {
        if (WFCUIsSameConversation(info.conversation, self.padSelectedConversation)) {
            self.padSelectedSeenInList = YES;
            return;
        }
    }
    if (!self.padSelectedSeenInList) {
        return;
    }
    NSInteger tab = self.padSelectedTabIndex;
    self.padSelectedSeenInList = NO;
    self.padSelectedConversation = nil;
    self.padSelectedTabIndex = NSNotFound;
    [WFCUPadUtility resetDetailStackForTabAtIndex:tab];
}

- (void)onPadDetailChanged:(NSNotification *)notification {
    UIViewController *detail = notification.object;
    if (self.padSearchVC && detail != self.padSearchVC) {
        //右栏换成了搜索结果以外的东西——用户点开了某条命中，或者退回了欢迎页。搜索到此为止。
        //放在这里而不是 didSelectRow: 里，是因为三类命中（好友/群/会话）各有各的分支，
        //还夹着「展开更多」这种不算打开页面的点击。
        [self padSearchDidEnd];
    }
    WFCCConversation *conversation = nil;
    if ([detail isKindOfClass:[WFCUMessageListViewController class]]) {
        conversation = ((WFCUMessageListViewController *)detail).conversation;
    }
    if (!WFCUIsSameConversation(conversation, self.padSelectedConversation)) {
        self.padSelectedConversation = conversation;
        //换了一个会话就重新等它在列表里出现一次（android rememberSelectedConversation
        //里那句 selectedSeenInList = false）。同一个会话的重复通知（往下钻、返回）不重置，
        //否则中间来一次刷新就会误判成「没来过」。
        self.padSelectedSeenInList = NO;
        self.padSelectedTabIndex = conversation ? self.tabBarController.selectedIndex : NSNotFound;
    }
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView != self.tableView || [self isSearchTableView:tableView]) {
        return;
    }
    if (![WFCUPadUtility isSplitLayoutActive] || indexPath.row >= self.conversations.count) {
        return;
    }
    WFCCConversationInfo *info = self.conversations[indexPath.row];
    if ([self isPadSelectedConversation:info.conversation]) {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
    _searchConversationList       = nil;
}

#pragma mark - Search History

- (void)textFieldDidBeginEditing:(NSNotification *)notification {
    if (@available(iOS 13, *)) {
        UITextField *textField = [self activeSearchBar].searchTextField;
        if (notification.object == textField && self.searchHistory.count > 0) {
            [self showSearchHistory];
        }
    }
}

- (void)showSearchHistory {
    if (self.showingHistory || self.searchHistory.count == 0) {
        return;
    }

    self.showingHistory = YES;

    // 获取文本框的宽度
    UIView *hostView = [self searchHistoryHostView];
    CGFloat searchBarWidth;
    if (@available(iOS 13.0, *)) {
        searchBarWidth = [self activeSearchBar].searchTextField.bounds.size.width;
    } else {
        searchBarWidth = self.view.bounds.size.width - 16;
    }

    // 创建历史记录容器 - 减少顶部空白
    CGFloat headerHeight = 30; // 标题栏高度
    CGFloat tableY = headerHeight - 2; // 减少间距，让列表更靠近标题
    CGFloat tableHeight = MIN(5 * 44, self.searchHistory.count * 44); // 最多显示5条，少于5条则全部显示

    // 创建一个更大的背景视图来接收点击事件
    UIView *bgView = [[UIView alloc] initWithFrame:hostView.bounds];
    bgView.backgroundColor = [UIColor clearColor];
    bgView.tag = 9999;

    // 添加点击手势到背景视图
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHistoryBackgroundTapped:)];
    tapGesture.cancelsTouchesInView = NO; // 不拦截子视图的触摸事件
    [bgView addGestureRecognizer:tapGesture];

    self.historyContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, searchBarWidth, tableY + tableHeight)];
    self.historyContainer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.98];
    self.historyContainer.layer.cornerRadius = 12;
    self.historyContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.historyContainer.layer.shadowOpacity = 0.2;
    self.historyContainer.layer.shadowOffset = CGSizeMake(0, -2);
    self.historyContainer.layer.shadowRadius = 8;
    self.historyContainer.clipsToBounds = NO;

    [bgView addSubview:self.historyContainer];

    // 标题 - 减少上边距
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 2, 200, headerHeight)];
    titleLabel.text = WFCString(@"SearchHistory");
    titleLabel.font = [UIFont scaledBoldSystemFontOfSize:14];
    titleLabel.textColor = [UIColor blackColor];
    [self.historyContainer addSubview:titleLabel];

    // 清空按钮 - 调整位置
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTitle:WFCString(@"Clear") forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont scaledSystemFontOfSize:13];
    clearButton.frame = CGRectMake(searchBarWidth - 60, 2, 60, headerHeight - 2);
    clearButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    [clearButton addTarget:self action:@selector(clearSearchHistory) forControlEvents:UIControlEventTouchUpInside];
    [self.historyContainer addSubview:clearButton];

    // 创建历史记录表格 - 允许滚动
    self.historyTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, tableY, searchBarWidth, tableHeight) style:UITableViewStylePlain];
    self.historyTableView.delegate = self;
    self.historyTableView.dataSource = self;
    self.historyTableView.scrollEnabled = YES; // 允许滚动
    self.historyTableView.backgroundColor = [UIColor clearColor];
    self.historyTableView.backgroundView = nil;
    self.historyTableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 去掉分隔线让界面更紧凑
    [self.historyTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"historyCell"];
    [self.historyContainer addSubview:self.historyTableView];

    // 显示在搜索框下方
    if (@available(iOS 13.0, *)) {
        UITextField *textField = [self activeSearchBar].searchTextField;

        // 将背景视图添加到导航控制器的视图上，确保覆盖整个屏幕
        [hostView addSubview:bgView];

        // 设置位置
        CGRect textFieldFrame = [textField convertRect:textField.bounds toView:bgView];
        self.historyContainer.center = CGPointMake(textFieldFrame.origin.x + textFieldFrame.size.width / 2, textFieldFrame.origin.y + textFieldFrame.size.height + (tableY + tableHeight) / 2);
        self.historyContainer.alpha = 0;
        self.historyContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.2 animations:^{
            self.historyContainer.alpha = 1;
            self.historyContainer.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)hideSearchHistory {
    // 查找并移除背景视图（双栏下它挂在右栏那条导航栈上，按 tag 到左栏去找是找不到的）
    UIView *bgView = self.historyContainer.superview ?: [self.navigationController.view viewWithTag:9999];
    if (bgView) {
        [UIView animateWithDuration:0.2 animations:^{
            self.historyContainer.alpha = 0;
            self.historyContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [bgView removeFromSuperview];
            self.historyContainer = nil;
            self.historyTableView = nil;
            self.showingHistory = NO;
        }];
    }
}

- (void)dismissHistoryBackgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.historyContainer];

    // 检查点击是否在历史记录容器之外
    if (!CGRectContainsPoint(self.historyContainer.bounds, location)) {
        [self hideSearchHistory];
    }
}

- (void)clearSearchHistory {
    [self.searchHistory removeAllObjects];
    [self saveSearchHistory];
    [self hideSearchHistory]; // 直接隐藏整个容器
}

- (NSMutableArray *)loadSearchHistory {
    NSArray *history = [[NSUserDefaults standardUserDefaults] arrayForKey:@"WFCUSearchHistory"];
    return [history mutableCopy] ?: [NSMutableArray array];
}

- (void)saveSearchHistory {
    [[NSUserDefaults standardUserDefaults] setObject:self.searchHistory forKey:@"WFCUSearchHistory"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)addSearchHistory:(NSString *)searchText {
    if (!searchText || searchText.length == 0) {
        return;
    }

    // 移除重复项
    [self.searchHistory removeObject:searchText];

    // 添加到开头
    [self.searchHistory insertObject:searchText atIndex:0];

    // 只保留最近10个
    if (self.searchHistory.count > 10) {
        [self.searchHistory removeObjectsInRange:NSMakeRange(10, self.searchHistory.count - 10)];
    }

    [self saveSearchHistory];
}

- (void)removeSearchHistoryAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.searchHistory.count) {
        [self.searchHistory removeObjectAtIndex:index];
        [self saveSearchHistory];
        [self.historyTableView reloadData];

        if (self.searchHistory.count == 0) {
            [self hideSearchHistory];
        }
    }
}

- (void)deleteHistoryItem:(UIButton *)sender {
    NSInteger index = sender.tag;
    [self removeSearchHistoryAtIndex:index];
}

#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.searchController.view.frame = self.view.bounds;
    self.isSearchFriendListExpansion = NO;
    self.isSearchConversationListExpansion = NO;
    self.isSearchGroupListExpansion = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tabBarController.tabBar.hidden = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length > 0) {
        // 取消时保存到历史记录
        [self addSearchHistory:searchString];
    }
    [self hideSearchHistory]; // 隐藏历史记录
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

#pragma mark - 双栏下的搜索：整页开在右栏，输入框长在那张页面上

//点了左栏顶上那条搜索框。对应 android 主界面 toolbar 上那颗 `R.id.search`
//（`showSearchPortal()` 起 SearchPortalActivity，它登记在 `PaneRegistry` 里，所以落进右栏）、
//以及 flutter `_onTapSearchButton` -> `openSearch`。两端的搜索入口本来就是一颗按钮。
//左栏这条框不取焦点（输入框已由 `installSearchTriggerOnSearchBar:` 关掉），
//焦点归右栏那张搜索页自己的输入框（它在 viewDidAppear 里自己抢）。
//每点一次都是一张新页面 —— android：「都不去重：每次进来都该是一张空搜索框」。
- (void)onPadSearchEntryTapped {
    if (![WFCUPadUtility isSplitLayoutActive]) {
        return;
    }
    WFCUPadSearchResultViewController *searchVC = [[WFCUPadSearchResultViewController alloc] init];
    searchVC.tableView.delegate = self;
    searchVC.tableView.dataSource = self;
    searchVC.searchDelegate = self;
    //与 didPresentSearchController: 里那三行同义：每次进搜索都从「未展开」开始
    self.isSearchFriendListExpansion = NO;
    self.isSearchConversationListExpansion = NO;
    self.isSearchGroupListExpansion = NO;
    self.searchConversationList = nil;
    self.searchFriendList = nil;
    self.searchGroupList = nil;
    //先设再送：showDetailViewController: 会同步发出右栏变更通知，
    //通知回来时 padSearchVC 得已经对上号，否则这一页会被当成「别人」而立刻收工。
    self.padSearchVC = searchVC;
    [WFCUPadUtility showDetailViewController:searchVC];
    [self.tableView reloadData];
}

//右栏不再是那张搜索页了（点开了某条命中、或者退回欢迎页），搜索到此为止。
- (void)padSearchDidEnd {
    NSString *searchString = self.padSearchVC.searchBar.text;
    if (searchString.length > 0) {
        //与 willDismissSearchController: 一样，收工时把关键字记进历史
        [self addSearchHistory:searchString];
    }
    [self hideSearchHistory];
    self.padSearchVC = nil;
    self.searchConversationList = nil;
    self.searchFriendList = nil;
    self.searchGroupList = nil;
}

#pragma mark - WFCUPadSearchResultDelegate

- (void)padSearchResultController:(WFCUPadSearchResultViewController *)controller textDidChange:(NSString *)text {
    [self performSearchWithText:text];
}

- (void)padSearchResultControllerDidCancel:(WFCUPadSearchResultViewController *)controller {
    //「取消」就是关掉这张搜索页（android `onCancelClick` -> `finishPage`）。
    //右栏退回欢迎页，padSearchVC 由随之而来的右栏变更通知清掉。
    [WFCUPadUtility resetDetailViewController];
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
    [self performSearchWithText:[self.searchController.searchBar text]];
}

//按关键字取数。单栏下关键字来自左栏那条搜索框，双栏下来自右栏搜索页上那条。
- (void)performSearchWithText:(NSString *)searchString {
    if (searchString.length) {
        [self hideSearchHistory]; // 隐藏历史记录
        // 不在这里保存历史，在点击取消或搜索结果时保存
        self.searchConversationList = [[WFCCIMService sharedWFCIMService] searchConversation:searchString inConversation:@[@(Single_Type), @(Group_Type), @(Channel_Type), @(SecretChat_Type)] lines:@[@(0)]];
        self.searchFriendList = [self searchFriends:searchString];
        self.searchGroupList = [[WFCCIMService sharedWFCIMService] searchGroups:searchString];
    } else {
        self.searchConversationList = nil;
        self.searchFriendList = nil;
        self.searchGroupList = nil;
    }

    [self reloadSearchResultTableView];
}
@end
