//
//  WFCUFilesViewController.m
//  WFChatUIKit
//
//  Created by dali on 2020/8/2.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUFilesViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUFileRecordTableViewCell.h"
#import "WFCUBrowserViewController.h"
#import "WFCUConfigManager.h"
#import "UIImage+ERCategory.h"

@interface WFCUFilesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UIActivityIndicatorView *activityView;

@property (nonatomic, strong)UISearchController *searchController;
@property(nonatomic, strong)NSMutableArray<WFCCFileRecord *> *searchedRecords;

@property(nonatomic, strong)NSMutableArray<WFCCFileRecord *> *fileRecords;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL searchMore;
@property(nonatomic, assign)BOOL isLoading;
@property(nonatomic, strong)NSString *keyword;
@end

@implementation WFCUFilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }
    
    [self.view addSubview:self.tableView];
    
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = self.view.center;
    [self.view addSubview:self.activityView];
    
    if (self.myFiles) {
        self.title = @"我的文件";
    } else if(self.userFiles) {
        WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:NO];
        if (user.friendAlias.length) {
            self.title = [NSString stringWithFormat:@"%@ 的文件", user.friendAlias];
        } else if (user.displayName.length) {
            self.title = [NSString stringWithFormat:@"%@ 的文件", user.displayName];
        } else {
            self.title = @"文件";
        }
    } else if(self.conversation) {
        self.title = @"会话文件";
    } else {
        self.title = @"所有文件";
    }

    self.hasMore = YES;
    self.fileRecords = [[NSMutableArray alloc] init];
    [self loadMoreData];
}

- (void)loadMoreData {
    if (!self.hasMore) {
        return;
    }
    if(self.isLoading) {
        return;
    }
    
    __weak typeof(self)ws = self;
    long long lastId = 0;
    if (self.fileRecords.count) {
        lastId = self.fileRecords.lastObject.messageUid;
    }
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    self.isLoading = YES;
    
    [self loadData:lastId count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        [ws.fileRecords addObjectsFromArray:files];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
        [ws.activityView stopAnimating];
        ws.isLoading = NO;
        if (files.count < 20) {
            self.hasMore = NO;
        }
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
        [ws.activityView stopAnimating];
        ws.isLoading = NO;
    }];
}

- (void)setIsLoading:(BOOL)isLoading {
    _isLoading = isLoading;
    [self updateTableViewFooter];
}

- (void)setHasMore:(BOOL)hasMore {
    _hasMore = hasMore;
    [self updateTableViewFooter];
}

- (void)updateTableViewFooter {
    if(!_hasMore) {
        UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 21)];
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
        line.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        [footView addSubview:line];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 1, self.view.frame.size.width, 20)];
        label.text = @"已经加载完了";
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [UIColor grayColor];
        [footView addSubview:label];
        self.tableView.tableFooterView = footView;
    } else if(_isLoading) {
        UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [footView addSubview:activityView];
        activityView.center = footView.center;
        self.tableView.tableFooterView = footView;
    } else {
        self.tableView.tableFooterView = nil;
    }
}
- (void)loadData:(long long)startPos count:(int)count success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
           error:(void(^)(int error_code))errorBlock {
    if (self.myFiles) {
        [[WFCCIMService sharedWFCIMService] getMyFiles:startPos count:count success:successBlock error:errorBlock];
    } else if(self.userFiles) {
        [[WFCCIMService sharedWFCIMService] getConversationFiles:nil fromUser:self.userId beforeMessageUid:startPos count:count success:successBlock error:errorBlock];
    } else {
        [[WFCCIMService sharedWFCIMService] getConversationFiles:self.conversation fromUser:nil beforeMessageUid:startPos count:count success:successBlock error:errorBlock];
    }
}


- (void)searchMoreData {
    if (!self.searchMore) {
        return;
    }
    
    __weak typeof(self)ws = self;
    long long lastId = 0;
    if (self.searchedRecords.count) {
        lastId = self.searchedRecords.lastObject.messageUid;
    }
    self.activityView.hidden = NO;
    
    [self searchData:lastId count:20 success:^(NSArray<WFCCFileRecord *> *files) {
        [ws.searchedRecords addObjectsFromArray:files];
        [ws.tableView reloadData];
        ws.activityView.hidden = YES;
        if (files.count < 20) {
            self.searchMore = NO;
        }
    } error:^(int error_code) {
        NSLog(@"load fire record error %d", error_code);
        ws.activityView.hidden = YES;
    }];
}

- (void)searchData:(long long)startPos count:(int)count success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
           error:(void(^)(int error_code))errorBlock {
    if (self.myFiles) {
        [[WFCCIMService sharedWFCIMService] searchMyFiles:self.keyword beforeMessageUid:startPos count:count success:successBlock error:errorBlock];
    } else if(self.userFiles) {
        [[WFCCIMService sharedWFCIMService] searchFiles:self.keyword conversation:nil fromUser:self.userId beforeMessageUid:startPos count:count success:successBlock error:errorBlock];
    } else {
        [[WFCCIMService sharedWFCIMService] searchFiles:self.keyword conversation:self.conversation fromUser:nil beforeMessageUid:startPos count:count success:successBlock error:errorBlock];
    }
}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (ceil(targetContentOffset->y)+1 >= ceil(scrollView.contentSize.height - scrollView.bounds.size.height)) {
        if (!self.searchController.active && self.hasMore) {
            [self loadMoreData];
        }
        
        if (self.searchController.active && self.searchMore) {
            [self searchMoreData];
        }
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WFCUFileRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[WFCUFileRecordTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    cell.fileRecord = record;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.searchedRecords.count;
    }
    return self.fileRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    return [WFCUFileRecordTableViewCell sizeOfRecord:record withCellWidth:self.view.bounds.size.width];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    if ([record.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return YES;
    } else if(record.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:record.conversation.target refresh:NO];
        if ([groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            return YES;
        }
        WFCCGroupMember *member = [[WFCCIMService sharedWFCIMService] getGroupMember:record.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
        if (member.type != Member_Type_Manager) {
            return NO;
        }
        
        WFCCGroupMember *senderMember = [[WFCCIMService sharedWFCIMService] getGroupMember:record.conversation.target memberId:record.userId];
        if (senderMember.type != Member_Type_Manager && senderMember.type != Member_Type_Owner) {
            return YES;
        }
    }
    
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        WFCCFileRecord *record;
        if (self.searchController.active) {
            record = self.searchedRecords[indexPath.row];
        } else {
            record = self.fileRecords[indexPath.row];
        }
        
        __weak typeof(self) ws = self;
        [[WFCCIMService sharedWFCIMService] deleteFileRecord:record.messageUid success:^{
            [ws.fileRecords removeObject:record];
            [ws.tableView reloadData];
        } error:^(int error_code) {
            
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCFileRecord *record;
    if (self.searchController.active) {
        record = self.searchedRecords[indexPath.row];
    } else {
        record = self.fileRecords[indexPath.row];
    }
    
    __weak typeof(self)ws = self;
    [[WFCCIMService sharedWFCIMService] getAuthorizedMediaUrl:record.messageUid mediaType:Media_Type_FILE mediaPath:record.url success:^(NSString *authorizedUrl, NSString *backupUrl) {
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = authorizedUrl;
        [ws.navigationController pushViewController:bvc animated:YES];
    } error:^(int error_code) {
        WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
        bvc.url = record.url;
        [ws.navigationController pushViewController:bvc animated:YES];
    }];
}


#pragma mark - UISearchControllerDelegate
- (void)didPresentSearchController:(UISearchController *)searchController {
    self.searchController.view.frame = self.view.bounds;
    self.tabBarController.tabBar.hidden = YES;
    self.extendedLayoutIncludesOpaqueBars = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    self.searchedRecords = [[NSMutableArray alloc] init];
    self.searchMore = YES;
    self.keyword = searchString;
    if (searchString.length) {
        [self searchMoreData];
    }
    
    [self.tableView reloadData];
}

@end
