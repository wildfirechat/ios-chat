//
//  WFCUAddFriendViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUAddFriendViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUProfileTableViewController.h"
#import <SDWebImage/SDWebImage.h>
#import "MBProgressHUD.h"
#import "WFCUConfigManager.h"
#import "UIImage+ERCategory.h"
#import "WFCUImage.h"
#import "WFCUGeneralImageTextTableViewCell.h"
#import "WFCUDomainTableViewController.h"


#define CELL_HEIGHT 56

@interface WFCUAddFriendViewController () <UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)  UITableView              *tableView;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) NSArray            *searchList;
@property (nonatomic, assign) BOOL texting;

@property (nonatomic, strong) UITextView       *noUserView;

@property(nonatomic, assign)BOOL meshEnabled;
@end

@implementation WFCUAddFriendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSearchUIAndData];
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)initSearchUIAndData {
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.navigationItem.title = WFCString(@"AddFriend");
    self.meshEnabled = [[WFCCIMService sharedWFCIMService] isMeshEnabled];

    _searchList = [NSMutableArray array];
        
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    if (@available(iOS 13, *)) {
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.searchBar.searchTextField.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        UIImage* searchBarBg = [UIImage imageWithColor:[UIColor whiteColor] size:CGSizeMake(self.view.frame.size.width - 8 * 2, 36) cornerRadius:4];
        [self.searchController.searchBar setSearchFieldBackgroundImage:searchBarBg forState:UIControlStateNormal];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    
    self.searchController.searchBar.placeholder = WFCString(@"SearchUserHint");
    self.searchController.searchBar.delegate = self;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = false;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    
    self.definesPresentationContext = YES;
    [self.view addSubview:_tableView];
    
    self.noUserView = [[UITextView alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, 400)];
    self.noUserView.textAlignment = NSTextAlignmentCenter;
    self.noUserView.text = @"用户不存在";
    self.noUserView.font = [UIFont systemFontOfSize:18];
    self.noUserView.hidden = YES;
    [self.view addSubview:self.noUserView];
    self.domainId = _domainId;
}

- (void)setDomainId:(NSString *)domainId {
    _domainId = domainId;
    if(self.meshEnabled) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 24)];
        
        if(self.domainId) {
            WFCCDomainInfo *domainInfo = [[WFCCIMService sharedWFCIMService] getDomainInfo:self.domainId refresh:NO];
            label.text = [NSString stringWithFormat:@"在单位 %@ 中搜索用户", domainInfo.name];
        } else {
            label.text = @"在本单位搜索用户";
        }
        label.userInteractionEnabled = YES;
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont systemFontOfSize:14];
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSelectDomain:)];
        [label addGestureRecognizer:gestureRecognizer];
        
        self.tableView.tableHeaderView = label;
    }
}

- (void)onSelectDomain:(id)sender {
    WFCUDomainTableViewController *vc = [[WFCUDomainTableViewController alloc] init];
    vc.onSelect = ^(NSString *domainId) {
        self.domainId = domainId;
    };
    vc.isPresent = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.searchController.active = YES;
    [self.searchController.searchBar becomeFirstResponder];
}

- (void)setTexting:(BOOL)texting {
    _texting = texting;
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self onSearch:searchBar];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.texting = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchControllerDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSLog(@"updateSearchResultsForSearchController");
}

#pragma mark - UITableViewDataSource
//table 返回的行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.noUserView.hidden = YES;
    if (self.searchController.active) {
        if(self.texting) {
            return self.searchController.searchBar.text.length?1:0;
        }
        if(![self.searchList count]) {
            self.noUserView.hidden = NO;
        }
        return [self.searchList count];
    } else {
      return 0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        if(self.texting) {
            [self onSearch:nil];
            return;
        }
        WFCCUserInfo *userInfo = self.searchList[indexPath.row];
        
        WFCUProfileTableViewController *pvc = [[WFCUProfileTableViewController alloc] init];
        pvc.userId = userInfo.userId;
        pvc.sourceType = FriendSource_Search;
        [self.navigationController pushViewController:pvc animated:YES];
    }
}
//返回单元格内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *flag = @"cell";

    WFCUGeneralImageTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:flag];
    if (cell == nil) {
        cell = [[WFCUGeneralImageTextTableViewCell alloc] initWithReuseIdentifier:flag cellHeight:CELL_HEIGHT];
    }
    if(self.texting) {
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:@"搜索："];
        [attStr appendAttributedString:[[NSAttributedString alloc] initWithString:self.searchController.searchBar.text attributes:@{NSForegroundColorAttributeName : [UIColor blueColor]}]];
        cell.titleLable.attributedText = attStr;
        cell.portraitIV.image = [WFCUImage imageNamed:@"search_icon"];
    } else {
        WFCCUserInfo *userInfo = self.searchList[indexPath.row];
        [cell.titleLable setText:userInfo.displayName];
        [cell.portraitIV sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)onSearch:(id)sender {
    __weak typeof(self) ws = self;
    NSString *searchString = [ws.searchController.searchBar text];
    if (searchString.length) {
        [[WFCCIMService sharedWFCIMService] searchUser:searchString
                                                domain:self.domainId
                                            searchType:SearchUserType_Name_Mobile
                                              userType:UserSearchUserType_All
                                                  page:0
                                               success:^(NSArray<WFCCUserInfo *> *machedUsers) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       if([machedUsers count] == 1) {
                                                           ws.texting = YES;
                                                           WFCCUserInfo *userInfo = machedUsers[0];
                                                           WFCUProfileTableViewController *pvc = [[WFCUProfileTableViewController alloc] init];
                                                           pvc.userId = userInfo.userId;
                                                           pvc.sourceType = FriendSource_Search;
                                                           [ws.navigationController pushViewController:pvc animated:YES];
                                                       } else {
                                                           ws.texting = NO;
                                                           ws.searchList = machedUsers;
                                                           [ws.tableView reloadData];
                                                       }
                                                   });
                                               }
                                                 error:^(int errorCode) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         ws.searchList = nil;
                                                         [ws.tableView reloadData];
                                                     });
                                                     NSLog(@"Search failed, errorCode(%d)", errorCode);
                                                 }];
        
    } else {
        ws.searchList = nil;
        [ws.tableView reloadData];
    }
}

- (void)dealloc {
    _tableView        = nil;
    _searchController = nil;
    _searchList       = nil;
}
@end
