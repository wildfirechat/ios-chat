//
//  ContactListViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUProfileTableViewController.h"
#import "WFCUContactSelectTableViewCell.h"
#import "WFCUContactTableViewCell.h"
#import "pinyin.h"
#import "WFCUFavGroupTableViewController.h"
#import "WFCUFriendRequestViewController.h"
#import "UITabBar+badge.h"
#import "WFCUNewFriendTableViewCell.h"
#import "WFCUAddFriendViewController.h"
#import "MBProgressHUD.h"
#import "WFCUFavChannelTableViewController.h"
#import "WFCUConfigManager.h"
#import "UIView+Toast.h"
#import "UIImage+ERCategory.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUPinyinUtility.h"
#import "WFCUImage.h"
#import "WFCUOrganizationCache.h"
#import "WFCUOrganization.h"
#import "WFCUOrganizationViewController.h"
#import "WFCUOrgRelationship.h"
#import "WFCUDomainTableViewController.h"

@interface WFCUContactListViewController () <UITableViewDataSource, UISearchControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<WFCCUserInfo *> *dataArray;
@property (nonatomic, strong)NSMutableArray<NSString *> *selectedContacts;

@property (nonatomic, strong) NSMutableArray<WFCCUserInfo *> *searchList;
@property (nonatomic, strong)  UISearchController       *searchController;

@property(nonatomic, strong) NSMutableDictionary *resultDic;

@property(nonatomic, strong) NSDictionary *allFriendSectionDic;
@property(nonatomic, strong) NSArray *allKeys;

@property(nonatomic, assign)BOOL sorting;
@property(nonatomic, assign)BOOL needSort;
@property(nonatomic, strong)UIActivityIndicatorView *activityIndicator;

@property(nonatomic, assign)BOOL meshEnabled;
@end

static NSMutableDictionary *hanziStringDict = nil;
static NSString *wfcstar = @"☆";
static NSString *aiRobot = @"AI";
@implementation WFCUContactListViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CGRect frame = self.view.frame;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.tableView.tableHeaderView = nil;
    self.meshEnabled = [[WFCCIMService sharedWFCIMService] isMeshEnabled];
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Cancel") style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateRightBarBtn];
        }
    } else {
      self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[WFCUImage imageNamed:@"nav_add_friend"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    }
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsUpdated:) name:kFriendListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onRootOrganizationUpdated:) name:kRootOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMyOrganizationUpdated:) name:kMyOrganizationUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrganizationUpdated:) name:kOrganizationUpdated object:nil];
    
    _searchList = [NSMutableArray array];
    
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
    
    [self.searchController.searchBar setPlaceholder:WFCString(@"SearchContact")];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;

    self.tableView.sectionIndexColor = [UIColor colorWithHexString:@"0x4e4e4e"];
    [self.view addSubview:self.tableView];
    
    [self.view bringSubviewToFront:self.activityIndicator];
    
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self.tableView reloadData];
        }
    }
}
    
- (void)updateRightBarBtn {
    if(self.selectedContacts.count == 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"Ok") style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        if (self.multiSelect && self.maxSelectCount > 1) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d/%d)", WFCString(@"Ok"),  (int)self.selectedContacts.count, self.maxSelectCount] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%@(%d)", WFCString(@"Ok"),  (int)self.selectedContacts.count] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        }
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
  if (self.selectContact) {
    if (self.selectedContacts) {
        [self left:^{
            self.selectResult(self.selectedContacts);
        }];
    }
  } else {
    UIViewController *addFriendVC = [[WFCUAddFriendViewController alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
  }
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    if (self.cancelSelect) {
        self.cancelSelect();
    }
    [self left:nil];
}

- (void)left:(void (^)(void))completion {
    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
        if(completion) {
            completion();
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dataArray = [[NSMutableArray alloc] init];
    if (self.selectContact) {
        [self loadContact:NO];
    } else {
        [self loadContact:YES];
        [self updateBadgeNumber];
    }
}

- (void)loadContact:(BOOL)forceLoadFromRemote {
    [self.dataArray removeAllObjects];
    NSArray *userIdList;
    if (self.candidateUsers.count) {
        userIdList = self.candidateUsers;
    } else {
        userIdList = [[WFCCIMService sharedWFCIMService] getMyFriendList:forceLoadFromRemote];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"wfc_uikit_had_pc_session"]) {
            if (![userIdList containsObject:[WFCUConfigManager globalManager].fileTransferId]) {
                NSMutableArray *ma = [userIdList mutableCopy];
                [ma addObject:[WFCUConfigManager globalManager].fileTransferId];
                userIdList = [ma copy];
            }
        }
        if([WFCUConfigManager globalManager].aiRobotId.length && ![userIdList containsObject:[WFCUConfigManager globalManager].aiRobotId]) {
            NSMutableArray *ma = [userIdList mutableCopy];
            [ma addObject:[WFCUConfigManager globalManager].aiRobotId];
            userIdList = [ma copy];
        }
    }
    self.dataArray = [[[WFCCIMService sharedWFCIMService] getUserInfos:userIdList inGroup:self.groupId] mutableCopy];
    self.needSort = YES;
}

- (void)setNeedSort:(BOOL)needSort {
    _needSort = needSort;
    if (needSort && !self.sorting) {
        _needSort = NO;
        if (self.searchController.active) {
            [self sortAndRefreshWithList:self.searchList];
        } else {
            [self sortAndRefreshWithList:self.dataArray];
        }
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    BOOL needRefresh = NO;
    NSArray<WFCCUserInfo *> *userInfoList = notification.userInfo[@"userInfoList"];
    for (WFCCUserInfo *userInfo in userInfoList) {
        for (WFCCUserInfo *ui in self.dataArray) {
            if ([ui.userId isEqualToString:userInfo.userId]) {
                needRefresh = YES;
                [ui cloneFrom:userInfo];
            }
        }
    }
    
    if(needRefresh) {
        self.needSort = needRefresh;
    }
}

- (void)onContactsUpdated:(NSNotification *)notification {
    [self loadContact:NO];
}

- (void)onRootOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)onMyOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)onOrganizationUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)sortAndRefreshWithList:(NSArray *)friendList {
    self.sorting = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.resultDic = [WFCUContactListViewController sortedArrayWithPinYinDic:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allFriendSectionDic = self.resultDic[@"infoDic"];
            self.allKeys = self.resultDic[@"allKeys"];
          if (!self.selectContact && !self.searchController.active) {
            UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 48)];
            countLabel.textAlignment = NSTextAlignmentCenter;
            
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 0.5)];
            line.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.8];
            [countLabel addSubview:line];
            
            [countLabel setText:[NSString stringWithFormat:WFCString(@"NumberOfContacts"), (int)self.dataArray.count]];
            countLabel.font = [UIFont systemFontOfSize:14];
            countLabel.textColor = [UIColor grayColor];
            
            self.tableView.tableFooterView = countLabel;
          } else {
            self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
          }
            
            [self.tableView reloadData];
            self.sorting = NO;
            if (self.needSort) {
                self.needSort = self.needSort;
            }
            [self.activityIndicator stopAnimating];
            self.activityIndicator.hidden = YES;
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onFriendRequestUpdated:(id)sender {
    [self updateBadgeNumber];
}

- (void)onClearAllUnread:(NSNotification *)notification {
    if ([notification.object intValue] == 1) {
        [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
        [self updateBadgeNumber];
    }
}

- (void)updateBadgeNumber {
    int count = [[WFCCIMService sharedWFCIMService] getUnreadFriendRequestStatus];
    [self.tabBarController.tabBar showBadgeOnItemIndex:1 badgeValue:count];
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *dataSource;

    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 1;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section]];
        }
        return dataSource.count;
    } else {
        if (section == 0) {
            return 3 + [WFCUOrganizationCache sharedCache].rootOrganizationIds.count + [WFCUOrganizationCache sharedCache].bottomOrganizationIds.count + (self.meshEnabled?1:0);
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section - 1]];
            return dataSource.count;
        }
    }
}

#define REUSEIDENTIFY @"resueCell"
- (WFCUContactTableViewCell *)dequeueOrAllocContactCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
#define FAVGROUP_REUSEIDENTIFY @"favGroupCell"
- (WFCUContactTableViewCell *)dequeueOrAllocFavGroupCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:FAVGROUP_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FAVGROUP_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
#define CHANNEL_REUSEIDENTIFY @"channelCell"
- (WFCUContactTableViewCell *)dequeueOrAllocChannelCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:CHANNEL_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CHANNEL_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
#define NEWFRIEND_REUSEIDENTIFY @"newFriendCell"
- (WFCUNewFriendTableViewCell *)dequeueOrAllocNewFriendCell:(UITableView *)tableView {
    WFCUNewFriendTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:NEWFRIEND_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUNewFriendTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NEWFRIEND_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
#define SELECT_REUSEIDENTIFY @"resueSelectCell"
- (WFCUContactSelectTableViewCell *)dequeueOrAllocSelectContactCell:(UITableView *)tableView {
    WFCUContactSelectTableViewCell *selectCell = [tableView dequeueReusableCellWithIdentifier:SELECT_REUSEIDENTIFY];
    if (selectCell == nil) {
        selectCell = [[WFCUContactSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SELECT_REUSEIDENTIFY];
        selectCell.selectionStyle = UITableViewCellSelectionStyleNone;
        selectCell.separatorInset = UIEdgeInsetsMake(0, 102, 0, 0);
    }
    return selectCell;
}
#define ORGANIZATION_REUSEIDENTIFY @"organizationCell"
- (WFCUContactTableViewCell *)dequeueOrAllocOrganizationCell:(UITableView *)tableView {
    WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:ORGANIZATION_REUSEIDENTIFY];
    if (contactCell == nil) {
        contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ORGANIZATION_REUSEIDENTIFY];
        contactCell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    }
    return contactCell;
}
// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"new_channel"];
                if (self.showCreateChannel) {
                    cell.textLabel.text = WFCString(@"CreateChannel");
                } else {
                    cell.textLabel.text = WFCString(@"MentionAll");
                }
                cell.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
                return cell;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                WFCUNewFriendTableViewCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
                
                contactCell.nameLabel.text = WFCString(@"NewFriend");
                contactCell.portraitView.image = [WFCUImage imageNamed:@"friend_request_icon"];
                [contactCell refresh];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
                
                contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                return contactCell;
            } else if(indexPath.row == 1) {
                WFCUContactTableViewCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
                contactCell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
                contactCell.nameLabel.text = WFCString(@"Group");
                contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_group_icon"];
                contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                contactCell.onlineView.hidden = YES;
                return contactCell;
            } else if(indexPath.row == 2) {
                WFCUContactTableViewCell *contactCell = [self dequeueOrAllocChannelCell:tableView];
                
                contactCell.nameLabel.text = WFCString(@"Channel");
                contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_channel_icon"];
                contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                contactCell.onlineView.hidden = YES;
                return contactCell;
            } else if(indexPath.row == 3 && self.meshEnabled) {
                WFCUContactTableViewCell *contactCell = [self dequeueOrAllocChannelCell:tableView];
                
                contactCell.nameLabel.text = WFCString(@"Mesh");
                contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_mesh_icon"];
                contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                contactCell.onlineView.hidden = YES;
                return contactCell;
            } else {
                int index = indexPath.row - 3 - (self.meshEnabled?1:0);
                WFCUContactTableViewCell *contactCell = [self dequeueOrAllocOrganizationCell:tableView];
                if(index < [WFCUOrganizationCache sharedCache].rootOrganizationIds.count) {
                    int orgId = [[WFCUOrganizationCache sharedCache].rootOrganizationIds[index] intValue];
                    WFCUOrganization *organization = [[WFCUOrganizationCache sharedCache] getOrganization:orgId refresh:NO];
                    contactCell.nameLabel.text = organization.name;
                    contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_organization_icon"];
                    contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                    contactCell.onlineView.hidden = YES;
                    return contactCell;
                } else {
                    index -= [WFCUOrganizationCache sharedCache].rootOrganizationIds.count;
                    int orgId = [[WFCUOrganizationCache sharedCache].bottomOrganizationIds[index] intValue];
                    WFCUOrganization *organization = [[WFCUOrganizationCache sharedCache] getOrganization:orgId refresh:NO];
                    contactCell.nameLabel.text = organization.name;
                    contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_expended_icon"];
                    contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
                    contactCell.onlineView.hidden = YES;
                    return contactCell;
                }
            }
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }

    
    if (self.selectContact) {
        if (self.multiSelect && !self.withoutCheckBox) {
            WFCUContactSelectTableViewCell *selectCell = [self dequeueOrAllocSelectContactCell:tableView];
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            selectCell.friendUid = userInfo.userId;
            selectCell.multiSelect = self.multiSelect;
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                selectCell.checked = YES;
            } else {
                selectCell.checked = NO;
            }
            if ([self.disableUsers containsObject:userInfo.userId]) {
                selectCell.disabled = YES;
              if(self.disableUsersSelected) {
                selectCell.checked = YES;
              } else {
                selectCell.checked = NO;
              }
            } else {
                selectCell.disabled = NO;
            }
            
            cell = selectCell;
        } else {
            WFCUContactTableViewCell *selectCell = [self dequeueOrAllocContactCell:tableView];
            
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            [selectCell setUserId:userInfo.userId groupId:self.groupId];
            
            selectCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
            cell = selectCell;
        }
    } else {
        if (indexPath.section == 0 && !self.searchController.active) {
            if (indexPath.row == 0) {
              WFCUNewFriendTableViewCell *contactCell = [self dequeueOrAllocNewFriendCell:tableView];
              [contactCell refresh];

              contactCell.nameLabel.text = WFCString(@"NewFriend");
              contactCell.portraitView.image = [WFCUImage imageNamed:@"friend_request_icon"];
              contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
              cell = contactCell;
            } else {
              WFCUContactTableViewCell *contactCell = [self dequeueOrAllocFavGroupCell:tableView];
              contactCell.nameLabel.text = WFCString(@"Group");
              contactCell.portraitView.image = [WFCUImage imageNamed:@"contact_group_icon"];
              contactCell.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
              cell = contactCell;
            }
        } else {
            WFCUContactTableViewCell *contactCell = [self dequeueOrAllocContactCell:tableView];
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            [contactCell setUserId:userInfo.userId groupId:self.groupId];
            cell = contactCell;
        }
    }
    if (cell == nil) {
        NSLog(@"error");
    }
    
    return cell;
}

-(NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (@available(iOS 11.0, *)) {
        if (self.selectContact) {
            if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
                NSMutableArray *indexs = [self.allKeys mutableCopy];
                [indexs insertObject:@"" atIndex:0];
                return indexs;
            }
            return self.allKeys;
        }
        if (self.searchController.active) {
            return self.allKeys;
        }
        NSMutableArray *indexs = [self.allKeys mutableCopy];
        [indexs insertObject:@"" atIndex:0];
        return indexs;
    } else {
        return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            return self.allKeys.count + 1;
        }
        return self.allKeys.count;
    }
    if (self.searchController.active) {
        return self.allKeys.count;
    }
    return 1 + self.allKeys.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return 0;
            }
        }
    } else {
        if(section == 0)
            return 0;
    }
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (self.selectContact || self.searchController.active) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (section == 0) {
                return nil;
            }
            title = self.allKeys[section-1];
        } else {
            title = self.allKeys[section];
        }
    } else {
        if (section == 0) {
            return nil;
        } else {
            title = self.allKeys[section - 1];
        }
    }
    if (title == nil || title.length == 0) {
        return nil;
    }

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];
    label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
    label.textAlignment = NSTextAlignmentLeft;
    if ([title isEqualToString:wfcstar]) {
        title = WFCString(@"StarFriends");
    }
    if([title isEqualToString:aiRobot]) {
        title = @"人工智能助手";
    }
    label.text = [NSString stringWithFormat:@"%@", title];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        [self.view addSubview:_activityIndicator];
        [_activityIndicator startAnimating];
        [self.view bringSubviewToFront:_activityIndicator];
    }
    return _activityIndicator;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  if (self.selectContact) {
    return index;
  }
  if (self.searchController.active) {
    return index;
  }
  return index;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if ((self.showCreateChannel || self.showMentionAll) && !self.searchController.active) {
            if (indexPath.section == 0) {
                if (self.showCreateChannel) {
                    [self left:^{
                        if (self.createChannel) {
                            self.createChannel();
                        }
                    }];
                } else {
                    [self left:^{
                        if (self.mentionAll) {
                            self.mentionAll();
                        }
                    }];
                }
                
                return;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
        
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                UIViewController *addFriendVC = [[WFCUFriendRequestViewController alloc] init];
                addFriendVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:addFriendVC animated:YES];
            } else if(indexPath.row == 1) {
                WFCUFavGroupTableViewController *groupVC = [[WFCUFavGroupTableViewController alloc] init];;
                groupVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:groupVC animated:YES];
            } else if(indexPath.row == 2) {
                WFCUFavChannelTableViewController *channelVC = [[WFCUFavChannelTableViewController alloc] init];;
                channelVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:channelVC animated:YES];
            } else if(indexPath.row == 3 && self.meshEnabled) {
                WFCUDomainTableViewController *channelVC = [[WFCUDomainTableViewController alloc] init];;
                channelVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:channelVC animated:YES];
            } else {
                int index = indexPath.row - 3 - (self.meshEnabled?1:0);
                if(index < [WFCUOrganizationCache sharedCache].rootOrganizationIds.count) {
                    int orgId = [[WFCUOrganizationCache sharedCache].rootOrganizationIds[index] intValue];
                    WFCUOrganizationViewController *orgVC = [[WFCUOrganizationViewController alloc] init];
                    orgVC.organizationIds = @[@(orgId)];
                    orgVC.hidesBottomBarWhenPushed = YES;
                    orgVC.isPushed = YES;
                    [self.navigationController pushViewController:orgVC animated:YES];
                } else {
                    index -= [WFCUOrganizationCache sharedCache].rootOrganizationIds.count;
                    int orgId = [[WFCUOrganizationCache sharedCache].bottomOrganizationIds[index] intValue];
                    NSArray<WFCUOrgRelationship *> *rs = [[WFCUOrganizationCache sharedCache] getRelationship:[WFCCNetworkService sharedInstance].userId refresh:NO];
                    __block NSInteger index = orgId;
                    NSMutableArray *ids = [[NSMutableArray alloc] init];
                    while (index) {
                        [ids insertObject:@(index) atIndex:0];
                        __block BOOL has = NO;
                        [rs enumerateObjectsUsingBlock:^(WFCUOrgRelationship * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if(obj.organizationId == index) {
                                index = obj.parentOrganizationId;
                                *stop = YES;
                                has = YES;
                            }
                        }];
                        if(!has) {
                            break;
                        }
                    }
                    WFCUOrganizationViewController *orgVC = [[WFCUOrganizationViewController alloc] init];
                    orgVC.organizationIds = ids;
                    orgVC.hidesBottomBarWhenPushed = YES;
                    orgVC.isPushed = YES;
                    [self.navigationController pushViewController:orgVC animated:YES];
                }
            }
            return;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }
    
    if (self.selectContact) {
        WFCCUserInfo *userInfo = dataSource[indexPath.row];
        if (self.multiSelect) {
            if ([self.disableUsers containsObject:userInfo.userId]) {
                return;
            }
            
            if ([self.selectedContacts containsObject:userInfo.userId]) {
                [self.selectedContacts removeObject:userInfo.userId];
                [tableView reloadData];
            } else {
                if (self.maxSelectCount > 0 && self.selectedContacts.count >= self.maxSelectCount) {
                    [self.view makeToast:WFCString(@"MaxCount")];
                    return;
                }
                
                [self.selectedContacts addObject:userInfo.userId];
                [tableView reloadData];
            }
            [self updateRightBarBtn];
        } else {
            self.selectResult([NSArray arrayWithObjects:userInfo.userId, nil]);
            [self left:nil];
        }
    } else {
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        WFCCUserInfo *friend = dataSource[indexPath.row];
        vc.userId = friend.userId;

        vc.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    self.needSort = YES;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        NSString *searchString = [self.searchController.searchBar text];
        if (self.searchList!= nil) {
            [self.searchList removeAllObjects];
            if(searchString.length) {
                WFCUPinyinUtility *pu = [[WFCUPinyinUtility alloc] init];
                BOOL isChinese = [pu isChinese:searchString];
                for (WFCCUserInfo *friend in self.dataArray) {
                    if ([friend.displayName.lowercaseString containsString:searchString.lowercaseString] || [friend.friendAlias.lowercaseString containsString:searchString.lowercaseString]) {
                        [self.searchList addObject:friend];
                    } else if(!isChinese) {
                        if([pu isMatch:friend.displayName ofPinYin:searchString] || [pu isMatch:friend.friendAlias ofPinYin:searchString]) {
                            [self.searchList addObject:friend];
                        }
                    }
                }
            }
        }
        self.needSort = YES;
    }
}

+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList)
        return nil;
    NSArray *_keys = @[
                       wfcstar,
                       aiRobot,
                       @"A",
                       @"B",
                       @"C",
                       @"D",
                       @"E",
                       @"F",
                       @"G",
                       @"H",
                       @"I",
                       @"J",
                       @"K",
                       @"L",
                       @"M",
                       @"N",
                       @"O",
                       @"P",
                       @"Q",
                       @"R",
                       @"S",
                       @"T",
                       @"U",
                       @"V",
                       @"W",
                       @"X",
                       @"Y",
                       @"Z",
                       @"#"
                       ];
    
    NSMutableDictionary *infoDic = [NSMutableDictionary new];
    NSMutableArray *_tempOtherArr = [NSMutableArray new];
    BOOL isReturn = NO;
    NSMutableDictionary *firstLetterDict = [[NSMutableDictionary alloc] init];
    
    NSArray<NSString *> *favUsers = [[WFCCIMService sharedWFCIMService] getFavUsers];
    
    NSMutableArray *favArrays = [[NSMutableArray alloc] init];
    for (NSString *favUser in favUsers) {
        for (WFCCUserInfo *userInfo in userList) {
            if ([userInfo.userId isEqualToString:favUser]) {
                [favArrays addObject:userInfo];
                break;
            }
        }
    }
    
    if (favArrays.count) {
        [infoDic setObject:favArrays forKey:wfcstar];
    }
    
    for (WFCCUserInfo *userInfo in userList) {
        if ([userInfo.userId isEqualToString:[WFCUConfigManager globalManager].aiRobotId]) {
            [infoDic setObject:[@[userInfo] mutableCopy] forKey:aiRobot];
            break;
        }
    }
    
    for (NSString *key in _keys) {
        if ([key isEqualToString:wfcstar]) {
            continue;
        }
        if ([key isEqualToString:aiRobot]) {
            continue;
        }
        
        if ([_tempOtherArr count]) {
            isReturn = YES;
        }
        NSMutableArray *tempArr = [NSMutableArray new];
        for (id user in userList) {
            NSString *firstLetter;

            WFCCUserInfo *userInfo = (WFCCUserInfo*)user;
            if([userInfo.userId isEqualToString:[WFCUConfigManager globalManager].aiRobotId]) {
                continue;
            }
            
            NSString *userName = userInfo.displayName;
            if (userInfo.groupAlias.length) {
                userName = userInfo.groupAlias;
            }
            if (userInfo.friendAlias.length) {
                userName = userInfo.friendAlias;
            }
            if (userName.length == 0) {
                userInfo.displayName = [NSString stringWithFormat:@"<%@>", userInfo.userId];
                userName = userInfo.displayName;
            }
            
            firstLetter = [firstLetterDict objectForKey:userName];
            if (!firstLetter) {
                firstLetter = [self getFirstUpperLetter:userName];
                [firstLetterDict setObject:firstLetter forKey:userName];
            }
            
            
            if ([firstLetter isEqualToString:key]) {
                [tempArr addObject:user];
            }
            
            if (isReturn)
                continue;
            char c = [firstLetter characterAtIndex:0];
            if (isalpha(c) == 0) {
                [_tempOtherArr addObject:user];
            }
        }
        if (![tempArr count])
            continue;
        [infoDic setObject:tempArr forKey:key];
    }
    if ([_tempOtherArr count])
        [infoDic setObject:_tempOtherArr forKey:@"#"];
    
    NSArray *keys = [[infoDic allKeys]
                     sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                         
                         return [obj1 compare:obj2 options:NSNumericSearch];
                     }];
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithArray:keys];
    if ([allKeys containsObject:@"#"]) {
        [allKeys removeObject:@"#"];
        [allKeys insertObject:@"#" atIndex:allKeys.count];
    }
    if ([allKeys containsObject:aiRobot]) {
        [allKeys removeObject:aiRobot];
        [allKeys insertObject:aiRobot atIndex:0];
    }
    if ([allKeys containsObject:wfcstar]) {
        [allKeys removeObject:wfcstar];
        [allKeys insertObject:wfcstar atIndex:0];
    }
    NSMutableDictionary *resultDic = [NSMutableDictionary new];
    [resultDic setObject:infoDic forKey:@"infoDic"];
    [resultDic setObject:allKeys forKey:@"allKeys"];
    [infoDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray *_tempOtherArr = (NSMutableArray *)obj;
        [_tempOtherArr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            WFCCUserInfo *user1 = (WFCCUserInfo *)obj1;
            WFCCUserInfo *user2 = (WFCCUserInfo *)obj2;
            NSString *user1Pinyin = [WFCUContactListViewController hanZiToPinYinWithString:user1.displayName];
            NSString *user2Pinyin = [WFCUContactListViewController hanZiToPinYinWithString:user2.displayName];
            return [user1Pinyin compare:user2Pinyin];
        }];
    }];
    return resultDic;
}

+ (NSString *)getFirstUpperLetter:(NSString *)hanzi {
    NSString *pinyin = [self hanZiToPinYinWithString:hanzi];
    NSString *firstUpperLetter = [[pinyin substringToIndex:1] uppercaseString];
    if ([firstUpperLetter compare:@"A"] != NSOrderedAscending &&
        [firstUpperLetter compare:@"Z"] != NSOrderedDescending) {
        return firstUpperLetter;
    } else {
        return @"#";
    }
}

+ (NSString *)hanZiToPinYinWithString:(NSString *)hanZi {
    if (!hanZi) {
        return nil;
    }
    if (!hanziStringDict) {
        hanziStringDict = [[NSMutableDictionary alloc] init];
    }
    
    NSString *pinYinResult = [hanziStringDict objectForKey:hanZi];
    if (pinYinResult) {
        return pinYinResult;
    }
    pinYinResult = [NSString string];
    for (int j = 0; j < hanZi.length; j++) {
        NSString *singlePinyinLetter = nil;
        if ([self isChinese:[hanZi substringWithRange:NSMakeRange(j, 1)]]) {
            singlePinyinLetter = [[NSString
                                   stringWithFormat:@"%c", pinyinFirstLetter([hanZi characterAtIndex:j])]
                                  uppercaseString];
        }else{
            singlePinyinLetter = [hanZi substringWithRange:NSMakeRange(j, 1)];
        }
        
        pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
    }
    [hanziStringDict setObject:pinYinResult forKey:hanZi];
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
