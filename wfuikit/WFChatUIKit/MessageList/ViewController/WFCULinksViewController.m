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

// 搜索历史
@property (nonatomic, strong) UITableView *historyTableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchHistory;
@property (nonatomic, strong) UIView *historyContainer;
@property (nonatomic, assign) BOOL showingHistory;

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

    // 初始化搜索历史
    self.searchHistory = [self loadSearchHistory];

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
    // 历史记录表格不触发加载更多
    if (scrollView == self.historyTableView) {
        return;
    }

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
        textLabel.font = [UIFont systemFontOfSize:15];
        textLabel.textColor = [UIColor blackColor];
        textLabel.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textLabel];

        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        // 添加删除按钮
        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [deleteButton setTitle:@"✕" forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        deleteButton.frame = CGRectMake(cell.bounds.size.width - 44, 0, 44, 44);
        deleteButton.tintColor = [UIColor grayColor];
        deleteButton.tag = indexPath.row;
        deleteButton.exclusiveTouch = YES;
        [deleteButton addTarget:self action:@selector(deleteHistoryItem:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:deleteButton];

        return cell;
    }

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
    if (tableView == self.historyTableView) {
        return self.searchHistory.count;
    }
    if (self.searchController.active) {
        return self.searchedMessages.count;
    }
    return self.linkMessages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 历史记录表格使用44的固定高度
    if (tableView == self.historyTableView) {
        return 44;
    }
    return 88;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 处理历史记录点击
    if (tableView == self.historyTableView) {
        NSString *searchText = self.searchHistory[indexPath.row];

        // 设置搜索框文本并触发搜索
        if (@available(iOS 13.0, *)) {
            self.searchController.searchBar.searchTextField.text = searchText;
        } else {
            self.searchController.searchBar.text = searchText;
        }

        [self hideSearchHistory];

        // 触发搜索
        [self updateSearchResultsForSearchController:self.searchController];
        return;
    }

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
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length > 0) {
        // 取消时保存到历史记录
        [self addSearchHistory:searchString];
    }
    [self hideSearchHistory]; // 隐藏历史记录
    self.tabBarController.tabBar.hidden = NO;
    self.extendedLayoutIncludesOpaqueBars = NO;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        [self hideSearchHistory]; // 隐藏历史记录
        // 不在这里保存历史，在点击取消或搜索结果时保存
    }

    self.searchedMessages = [[NSMutableArray alloc] init];
    self.searchMore = YES;
    self.keyword = searchString;
    if (searchString.length) {
        [self searchMoreData];
    }

    [self.tableView reloadData];
}

#pragma mark - Search History

- (void)textFieldDidBeginEditing:(NSNotification *)notification {
    if (@available(iOS 13.0, *)) {
        UITextField *textField = self.searchController.searchBar.searchTextField;
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
    CGFloat searchBarWidth;
    if (@available(iOS 13.0, *)) {
        searchBarWidth = self.searchController.searchBar.searchTextField.bounds.size.width;
    } else {
        searchBarWidth = self.view.bounds.size.width - 16;
    }

    // 创建历史记录容器
    CGFloat headerHeight = 30;
    CGFloat tableY = headerHeight - 2;
    CGFloat tableHeight = MIN(5 * 44, self.searchHistory.count * 44);

    // 创建背景视图
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    bgView.backgroundColor = [UIColor clearColor];
    bgView.tag = 9999;

    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHistoryBackgroundTapped:)];
    tapGesture.cancelsTouchesInView = NO;
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

    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 2, 200, headerHeight)];
    titleLabel.text = @"搜索历史";
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.textColor = [UIColor blackColor];
    [self.historyContainer addSubview:titleLabel];

    // 清空按钮
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTitle:@"清空" forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:13];
    clearButton.frame = CGRectMake(searchBarWidth - 60, 2, 60, headerHeight - 2);
    clearButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 10);
    [clearButton addTarget:self action:@selector(clearSearchHistory) forControlEvents:UIControlEventTouchUpInside];
    [self.historyContainer addSubview:clearButton];

    // 创建历史记录表格
    self.historyTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, tableY, searchBarWidth, tableHeight) style:UITableViewStylePlain];
    self.historyTableView.delegate = self;
    self.historyTableView.dataSource = self;
    self.historyTableView.scrollEnabled = YES;
    self.historyTableView.backgroundColor = [UIColor clearColor];
    self.historyTableView.backgroundView = nil;
    self.historyTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.historyTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"historyCell"];
    [self.historyContainer addSubview:self.historyTableView];

    // 显示
    if (@available(iOS 13.0, *)) {
        UITextField *textField = self.searchController.searchBar.searchTextField;
        [self.navigationController.view addSubview:bgView];

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
    UIView *bgView = [self.navigationController.view viewWithTag:9999];
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
    if (!CGRectContainsPoint(self.historyContainer.bounds, location)) {
        [self hideSearchHistory];
    }
}

- (void)clearSearchHistory {
    [self.searchHistory removeAllObjects];
    [self saveSearchHistory];
    [self hideSearchHistory];
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

    [self.searchHistory removeObject:searchText];
    [self.searchHistory insertObject:searchText atIndex:0];

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

@end
