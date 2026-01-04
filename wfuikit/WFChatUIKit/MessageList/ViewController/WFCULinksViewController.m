//
//  WFCULinksViewController.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/1/4.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCULinksViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCULinkRecordTableViewCell.h"
#import "WFCUBrowserViewController.h"
#import "WFCUConfigManager.h"
#import "UIImage+ERCategory.h"
#import "WFCUUtilities.h"

@interface WFCULinksViewController () <UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)UIActivityIndicatorView *activityView;

@property (nonatomic, strong)UISearchController *searchController;
@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *searchedMessages;

@property(nonatomic, strong)NSMutableArray<WFCCMessage *> *linkMessages;
@property(nonatomic, assign)BOOL hasMore;
@property(nonatomic, assign)BOOL searchMore;
@property(nonatomic, assign)BOOL isLoading;
@property(nonatomic, strong)NSString *keyword;
@end

@implementation WFCULinksViewController

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
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }

    [self.view addSubview:self.tableView];

    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityView.center = self.view.center;
    [self.view addSubview:self.activityView];

    self.title = WFCString(@"Links");

    self.hasMore = YES;
    self.linkMessages = [[NSMutableArray alloc] init];
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
    long long lastTimestamp = 0;
    if (self.linkMessages.count) {
        lastTimestamp = self.linkMessages.lastObject.serverTime;
    }
    self.activityView.hidden = NO;
    [self.activityView startAnimating];
    self.isLoading = YES;

    // 在后台线程获取链接消息
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSNumber *> *contentTypes = @[@(MESSAGE_CONTENT_TYPE_LINK)];
        NSArray<WFCCMessage *> *messages = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation
                                                                          contentTypes:contentTypes
                                                                              fromTime:lastTimestamp
                                                                                count:20
                                                                              withUser:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.linkMessages addObjectsFromArray:messages];
            [ws.tableView reloadData];
            ws.activityView.hidden = YES;
            [ws.activityView stopAnimating];
            ws.isLoading = NO;
            if (messages.count < 20) {
                ws.hasMore = NO;
            }
            [ws updateTableViewFooter];
        });
    });
}

- (void)searchMoreData {
    if (!self.searchMore) {
        return;
    }

    __weak typeof(self)ws = self;
    long long lastTimestamp = 0;
    if (self.searchedMessages.count) {
        lastTimestamp = self.searchedMessages.lastObject.serverTime;
    }
    self.activityView.hidden = NO;
    [self.activityView startAnimating];

    // 在后台线程搜索链接消息
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<NSNumber *> *contentTypes = @[@(MESSAGE_CONTENT_TYPE_LINK)];
        NSArray<WFCCMessage *> *messages = [[WFCCIMService sharedWFCIMService] searchMessage:self.conversation
                                                                                 keyword:self.keyword
                                                                            contentTypes:contentTypes
                                                                                   order:YES
                                                                                   limit:20
                                                                                  offset:0
                                                                                withUser:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [ws.searchedMessages addObjectsFromArray:messages];
            [ws.tableView reloadData];
            ws.activityView.hidden = YES;
            [ws.activityView stopAnimating];
            if (messages.count < 20) {
                ws.searchMore = NO;
            }
            [ws updateTableViewFooter];
        });
    });
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
        label.text = WFCString(@"NoMoreData");
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCULinkRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[WFCULinkRecordTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }

    WFCCMessage *message;
    if (self.searchController.active) {
        message = self.searchedMessages[indexPath.row];
    } else {
        message = self.linkMessages[indexPath.row];
    }

    cell.message = message;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return self.searchedMessages.count;
    }
    return self.linkMessages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCCMessage *message;
    if (self.searchController.active) {
        message = self.searchedMessages[indexPath.row];
    } else {
        message = self.linkMessages[indexPath.row];
    }

    WFCCLinkMessageContent *linkContent = (WFCCLinkMessageContent *)message.content;
    WFCUBrowserViewController *bvc = [[WFCUBrowserViewController alloc] init];
    bvc.url = linkContent.url;
    [self.navigationController pushViewController:bvc animated:YES];
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

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    self.searchedMessages = [[NSMutableArray alloc] init];
    self.searchMore = YES;
    self.keyword = searchString;
    if (searchString.length) {
        [self searchMoreData];
    }

    [self.tableView reloadData];
}

@end
