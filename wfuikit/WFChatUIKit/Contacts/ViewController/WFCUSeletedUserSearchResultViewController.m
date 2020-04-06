//
//  WFCUSeletedUserSearchResultViewController.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/4.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUSeletedUserSearchResultViewController.h"
#import "WFCUSelectedUserTableViewCell.h"
#import "WFCUUserSectionKeySupport.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUConfigManager.h"
@interface WFCUSeletedUserSearchResultViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong)UISearchBar *searchBar;
@property (nonatomic, strong)NSMutableArray *results;
@end

@implementation WFCUSeletedUserSearchResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.results = [NSMutableArray new];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width - 16 * 2,44)];
    self.searchBar.backgroundColor = [UIColor clearColor];
    self.searchBar.placeholder = @"搜索";
    
    if (self.needSection) {
        self.view.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
         self.tableView.backgroundColor =  [WFCUConfigManager globalManager].naviBackgroudColor;
    } else {
        self.view.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        self.tableView.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
    }

    for (UIView *sView in self.searchBar.subviews[0].subviews) {
        if([sView isKindOfClass:NSClassFromString(@"UISearchBarBackground")]){
            [sView removeFromSuperview];
        }
    }
    self.searchBar.delegate = self;
    [self.searchBar becomeFirstResponder];
    self.searchBar.showsCancelButton = YES;
    self.navigationItem.titleView = self.searchBar;
    [self.view addSubview:self.tableView];
}



- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
        NSMutableArray <WFCUSelectedUserInfo *>*searchList = [NSMutableArray new];
        for (WFCUSelectedUserInfo *friend in self.dataSource) {
            if ([friend.displayName.lowercaseString containsString:searchBar.text.lowercaseString] || [friend.friendAlias.lowercaseString containsString:searchBar.text.lowercaseString]) {
                [searchList addObject:friend];
            }
        }
        self.results = searchList;
        [self sortAndRefreshWithList:searchList];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.navigationController dismissViewControllerAnimated:NO completion:nil];
}


- (void)sortAndRefreshWithList:(NSArray *)friendList {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableDictionary *resultDic = [WFCUUserSectionKeySupport userSectionKeys:friendList];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sectionDictionary = resultDic[@"infoDic"];
            self.sectionKeys = resultDic[@"allKeys"];
            [self.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.needSection) {
        return self.sectionKeys.count;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.needSection) {
        NSString *key = self.sectionKeys[section];
        NSArray *users = self.sectionDictionary[key];
        return users.count;
    } else {
        return self.results.count;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUSelectedUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectedUserT"];
    
    if (self.needSection) {
        NSString *key = self.sectionKeys[indexPath.section];
        NSArray *users = self.sectionDictionary[key];
        cell.selectedUserInfo = users[indexPath.row];
    } else {

        cell.selectedUserInfo = self.results[indexPath.row];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self.needSection) {
        cell.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    } else {
        cell.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
        cell.backgroundColor = [UIColor colorWithHexString:@"0x1f2026"];
        cell.nameLabel.textColor = [UIColor whiteColor];
    }
  

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 51;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.needSection) {
        if (section == 0) {
            return 0;
        }
        return 30;
        
    } else {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.needSection) {
        NSString *title = self.sectionKeys[section];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
        view.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width, 30)];
        label.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:13];
        label.textColor = [UIColor colorWithHexString:@"0x828282"];
        label.textAlignment = NSTextAlignmentLeft;
        label.text = [NSString stringWithFormat:@"%@", title];
        [view addSubview:label];
        return view;
        
    } else {
        return nil;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
       if (!self.needSection) {
           WFCUSelectedUserInfo *user = nil;
           user = self.results[indexPath.row];
           self.selectedUser(user);
        }  else {
           NSString *key = self.sectionKeys[indexPath.section];
            NSArray *users = self.sectionDictionary[key];
             WFCUSelectedUserInfo *user = users[indexPath.row];
            self.selectedUser(user);
       }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [_tableView registerClass:[WFCUSelectedUserTableViewCell class] forCellReuseIdentifier:@"selectedUserT"];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}


@end
