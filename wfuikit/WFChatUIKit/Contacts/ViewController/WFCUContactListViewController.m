//
//  ContactListViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactListViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
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
@end

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
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.tableView.tableHeaderView = nil;
    if (self.selectContact) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(onLeftBarBtn:)];
        
        if(self.multiSelect) {
            self.selectedContacts = [[NSMutableArray alloc] init];
            [self updateRightBarBtn];
        }
    } else {
      self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_add_friend"] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContactsUpdated:) name:kFriendListUpdated object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onClearAllUnread:) name:@"kTabBarClearBadgeNotification" object:nil];
    
    _searchList = [NSMutableArray array];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    [self.searchController.searchBar setValue:@"取消" forKey:@"_cancelButtonText"];
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    [self.searchController.searchBar setPlaceholder:@"搜索联系人"];

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    self.definesPresentationContext = YES;
    
    self.tableView.sectionIndexColor = [UIColor grayColor];
    [self.view addSubview:self.tableView];
    [self.tableView reloadData];
}

- (void)updateRightBarBtn {
    if(self.selectedContacts.count == 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"确定(%d)", (int)self.selectedContacts.count] style:UIBarButtonItemStyleDone target:self action:@selector(onRightBarBtn:)];
    }
}

- (void)onRightBarBtn:(UIBarButtonItem *)sender {
  if (self.selectContact) {
    if (self.selectedContacts) {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.selectResult(self.selectedContacts);
      });
    }
      [self left:nil];
  } else {
    UIViewController *addFriendVC = [[WFCUAddFriendViewController alloc] init];
    addFriendVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:addFriendVC animated:YES];
  }
}

- (void)onLeftBarBtn:(UIBarButtonItem *)sender {
    [self left:nil];
}

- (void)left:(void (^)(void))completion {
    if (self.isPushed) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.dataArray = [[NSMutableArray alloc] init];
    [self loadContact:YES];
    [self updateBadgeNumber];
}

- (void)loadContact:(BOOL)forceLoadFromRemote {
    [self.dataArray removeAllObjects];
    NSArray *userIdList;
    if (self.candidateUsers.count) {
        userIdList = self.candidateUsers;
    } else {
        userIdList = [[WFCCIMService sharedWFCIMService] getMyFriendList:forceLoadFromRemote];
    }
    self.dataArray = [[WFCCIMService sharedWFCIMService] getUserInfos:userIdList inGroup:nil];
    self.needSort = YES;
}

- (void)setNeedSort:(BOOL)needSort {
    _needSort = needSort;
    if (needSort && !self.sorting) {
        _needSort = NO;
        [self sortAndRefreshWithList:self.dataArray];
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
    BOOL needRefresh = NO;
    for (WFCCUserInfo *ui in self.dataArray) {
        if ([ui.userId isEqualToString:userInfo.userId]) {
            needRefresh = YES;
            [ui cloneFrom:userInfo];
            break;
        }
    }
    if(needRefresh) {
        self.needSort = needRefresh;
    }
}
- (void)onContactsUpdated:(NSNotification *)notification {
    [self loadContact:NO];
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
            
            [countLabel setText:[NSString stringWithFormat:@"%d位联系人", (int)self.dataArray.count]];
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
        if (self.showCreateChannel && !self.searchController.active) {
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
            return 3;
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[section - 1]];
            return dataSource.count;
        }
    }
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
#define REUSEIDENTIFY @"resueCell"
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if (self.showCreateChannel && !self.searchController.active) {
            if (indexPath.section == 0) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"new_channel"];
                cell.textLabel.text = @"新建频道";
                return cell;
            }
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section-1]];
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section]];
        }
        
    } else {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                WFCUNewFriendTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"newFriendCell"];
                if (contactCell == nil) {
                    contactCell = [[WFCUNewFriendTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"newFriendCell"];
                }
                contactCell.nameLabel.text = @"新朋友";
                contactCell.portraitView.image = [UIImage imageNamed:@"friend_request_icon"];
                [contactCell refresh];
                return contactCell;
            } else if(indexPath.row == 1) {
                WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
                if (contactCell == nil) {
                    contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
                }
                
                contactCell.nameLabel.text = @"群组";
                contactCell.portraitView.image = [UIImage imageNamed:@"contact_group_icon"];
                
                return contactCell;
            } else {
                WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
                if (contactCell == nil) {
                    contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
                }
                
                contactCell.nameLabel.text = @"频道";
                contactCell.portraitView.image = [UIImage imageNamed:@"contact_channel_icon"];
                
                return contactCell;
            }
        } else {
            dataSource = self.allFriendSectionDic[self.allKeys[indexPath.section - 1]];
        }
    }

    
    if (self.selectContact) {
#define SELECT_REUSEIDENTIFY @"resueSelectCell"
        WFCUContactSelectTableViewCell *selectCell = [tableView dequeueReusableCellWithIdentifier:SELECT_REUSEIDENTIFY];
        if (selectCell == nil) {
            selectCell = [[WFCUContactSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SELECT_REUSEIDENTIFY];
            selectCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        WFCCUserInfo *userInfo = dataSource[indexPath.row];
        selectCell.friendUid = userInfo.userId;
        selectCell.multiSelect = self.multiSelect;
        
        if (self.multiSelect) {
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
        }
        cell = selectCell;
    } else {
#define REUSEIDENTIFY @"resueCell"
        
        if (indexPath.section == 0 && !self.searchController.active) {
            if (indexPath.row == 0) {
                WFCUNewFriendTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"newFriendCell"];
                if (contactCell == nil) {
                    contactCell = [[WFCUNewFriendTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"newFriendCell"];
                }
                [contactCell refresh];
              contactCell.nameLabel.text = @"新朋友";
              contactCell.portraitView.image = [UIImage imageNamed:@"friend_request_icon"];
                cell = contactCell;
            } else {
                WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
                if (contactCell == nil) {
                    contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
                }
              contactCell.nameLabel.text = @"群组";
              contactCell.portraitView.image = [UIImage imageNamed:@"contact_group_icon"];
                cell = contactCell;
            }
        } else {
            WFCUContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:REUSEIDENTIFY];
            if (contactCell == nil) {
                contactCell = [[WFCUContactTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSEIDENTIFY];
            }
            
            WFCCUserInfo *userInfo = dataSource[indexPath.row];
            contactCell.userId = userInfo.userId;
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
            if (self.showCreateChannel && !self.searchController.active) {
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
        if (self.showCreateChannel && !self.searchController.active) {
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
    if (section == 0) {
        return 0;
    }
    return 21;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (self.selectContact || self.searchController.active) {
        if (self.showCreateChannel && !self.searchController.active) {
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 21)];
    label.font = [UIFont systemFontOfSize:13];
    label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentLeft;
    label.text = [NSString stringWithFormat:@"  %@", title];
    label.backgroundColor = [UIColor colorWithRed:239/255.f green:239/255.f blue:239/255.f alpha:1.0f];
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *dataSource;
    if (self.searchController.active || self.selectContact) {
        if (self.showCreateChannel && !self.searchController.active) {
            if (indexPath.section == 0) {
                [self left:^{
                    if (self.createChannel) {
                        self.createChannel();
                    }
                }];
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
            } else {
                WFCUFavChannelTableViewController *channelVC = [[WFCUFavChannelTableViewController alloc] init];;
                channelVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:channelVC animated:YES];
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
                ((WFCUContactSelectTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).checked = NO;
            } else {
                [self.selectedContacts addObject:userInfo.userId];
                ((WFCUContactSelectTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).checked = YES;
            }
            [self updateRightBarBtn];
        } else {
            self.selectResult([NSArray arrayWithObjects:userInfo.userId, nil]);
            [self left:nil];
        }
    } else {
        WFCUProfileTableViewController *vc = [[WFCUProfileTableViewController alloc] init];
        WFCCUserInfo *friend = dataSource[indexPath.row];
        vc.userInfo = friend;
        if (vc.userInfo == nil) {
            return;
        }
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
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self loadContact:NO];
    [self.tableView reloadData];
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (self.searchList!= nil) {
        [self.searchList removeAllObjects];
        for (WFCCUserInfo *friend in self.dataArray) {
            if ([friend.displayName containsString:searchString]) {
                [self.searchList addObject:friend];
            }
        }
    }
    self.needSort = YES;
}

+ (NSMutableDictionary *)sortedArrayWithPinYinDic:(NSArray *)userList {
    if (!userList)
        return nil;
    NSArray *_keys = @[
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
    
    for (NSString *key in _keys) {
        
        if ([_tempOtherArr count]) {
            isReturn = YES;
        }
        NSMutableArray *tempArr = [NSMutableArray new];
        for (id user in userList) {
            NSString *firstLetter;

            WFCCUserInfo *userInfo = (WFCCUserInfo*)user;
            NSString *userName = userInfo.displayName;
            if (userInfo.friendAlias.length) {
                userName = userInfo.friendAlias;
            }
            if (userName.length == 0) {
                userInfo.displayName = [NSString stringWithFormat:@"<%@>", userInfo.userId];
                userName = userInfo.displayName;
            }
            
            firstLetter = [self getFirstUpperLetter:userName];
            
        
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
    NSString *pinYinResult = [NSString string];
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
    return pinYinResult;
}

+ (BOOL)isChinese:(NSString *)text
{
    NSString *match = @"(^[\u4e00-\u9fa5]+$)";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF matches %@", match];
    return [predicate evaluateWithObject:text];
}

@end
