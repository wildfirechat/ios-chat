//
//  ConversationSearchTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSearchTableViewController.h"
#import "WFCUContactListViewController.h"
#import "WFCUFriendRequestViewController.h"

#import "WFCUMessageListViewController.h"

#import <SDWebImage/SDWebImage.h>
#import "WFCUUtilities.h"
#import "UITabBar+badge.h"
#import "KxMenu.h"
#import "UIImage+ERCategory.h"
#import "MBProgressHUD.h"

#import "WFCUConversationSearchTableViewCell.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUFilesViewController.h"
#import "WFCULinksViewController.h"
#import "WFCUCalendarSearchViewController.h"

@interface WFCUConversationSearchTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCMessage* > *messages;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;

// 分类按钮容器
@property (nonatomic, strong) UIView *categoryButtonsView;
// 图片和视频消息数组
@property (nonatomic, strong)NSMutableArray<WFCCMessage *> *imageMsgs;

// 搜索历史
@property (nonatomic, strong) UITableView *historyTableView;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchHistory;
@property (nonatomic, strong) UIView *historyContainer;
@property (nonatomic, assign) BOOL showingHistory;

@end

@implementation WFCUConversationSearchTableViewController
- (void)initSearchUIAndTableView {
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

        // 监听搜索框的焦点变化
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    } else {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }

    self.searchController.searchBar.placeholder = WFCString(@"Search");


    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        _searchController.hidesNavigationBarDuringPresentation = YES;
    } else {
        self.tableView.tableHeaderView = _searchController.searchBar;
    }

    self.definesPresentationContext = YES;

    // 初始化搜索历史
    self.searchHistory = [self loadSearchHistory];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messages = [[NSMutableArray alloc] init];
    [self initSearchUIAndTableView];
    [self setupCategoryButtonsView];

    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;

    // 设置 searchController delegate
    self.searchController.delegate = self;

    // 根据是否有关键词决定显示分类按钮
    [self updateCategoryButtonsVisibility];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupCategoryButtonsView {
    CGFloat buttonWidth = (self.view.frame.size.width - 16 * 3) / 2; // 2列，间距16
    CGFloat buttonHeight = 80;
    CGFloat padding = 16;
    CGFloat topMargin = 220; // 向下移动200px

    self.categoryButtonsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
    self.categoryButtonsView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.categoryButtonsView.hidden = YES; // 默认隐藏

    // 分类数据
    NSArray *categories = @[
        @{@"title": WFCString(@"SearchByDate"), @"icon": @"calendar"},
        @{@"title": WFCString(@"SearchMedia"), @"icon": @"photo.on.photo.on"},
        @{@"title": WFCString(@"SearchFile"), @"icon": @"doc.on.doc.on"},
        @{@"title": WFCString(@"SearchLink"), @"icon": @"link"}
    ];

    for (int i = 0; i < categories.count; i++) {
        NSDictionary *category = categories[i];
        int row = i / 2;
        int col = i % 2;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(padding + col * (buttonWidth + padding), topMargin + row * (buttonHeight + padding), buttonWidth, buttonHeight);
        button.titleLabel.font = [UIFont systemFontOfSize:16];
        [button setTitle:category[@"title"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:1.0] forState:UIControlStateNormal]; // 浅蓝色
        button.backgroundColor = [WFCUConfigManager globalManager].backgroudColor; // 与背景一致
        button.tag = i;
        [button addTarget:self action:@selector(categoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        [self.categoryButtonsView addSubview:button];
    }

    self.tableView.backgroundView = self.categoryButtonsView;
}

- (void)updateCategoryButtonsVisibility {
    // 如果没有搜索结果，显示分类按钮
    if (self.messages.count == 0 && !self.keyword) {
        self.categoryButtonsView.hidden = NO;
    } else {
        self.categoryButtonsView.hidden = YES;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.historyTableView) {
        return 1;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.historyTableView) {
        return self.searchHistory.count;
    }
    return self.messages.count;
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

        // 添加删除按钮到contentView
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

    WFCUConversationSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[WFCUConversationSearchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    WFCCMessage *msg = [self.messages objectAtIndex:indexPath.row];
    cell.keyword = self.keyword;
    cell.message = msg;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 历史记录表格使用44的固定高度
    if (tableView == self.historyTableView) {
        return 44;
    }
    return 68;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.historyTableView) {
        return nil;
    }
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    UIImageView *portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 32, 32)];
    portraitView.layer.cornerRadius = 3.f;
    portraitView.layer.masksToBounds = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 0, self.tableView.frame.size.width, 40)];
    
    label.font = [UIFont boldSystemFontOfSize:18];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentLeft;
    header.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    if (self.conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.conversation.target refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
        if(userInfo.displayName.length) {
            label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
        } else {
            label.text = @"用户聊天记录";
        }
    } else if (self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"GroupChatRound"]];
        if(groupInfo.displayName.length) {
            label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", groupInfo.displayName];
        } else {
            label.text = @"群组聊天记录";
        }
    } else if(self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"GroupChatRound"]];
        if(channelInfo.name.length) {
            label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", channelInfo.name];
        } else {
            label.text = @"频道聊天记录";
        }
    } else if(self.conversation.type == SecretChat_Type) {
        NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:self.conversation.target].userId;
        
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
    }
    
    [header addSubview:label];
    [header addSubview:portraitView];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.historyTableView) {
        return 0;
    }
    return 40;
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

    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];

    mvc.conversation = self.messages[indexPath.row].conversation;
    mvc.highlightMessageId = self.messages[indexPath.row].messageId;
    mvc.highlightText = self.keyword;
    mvc.multiSelecting = self.messageSelecting;
    mvc.selectedMessageIds = self.selectedMessageIds;
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 历史记录表格不需要处理
    if (scrollView == self.historyTableView) {
        return;
    }

    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
    _searchController = nil;
}

#pragma mark - UISearchControllerDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length) {
        [self hideSearchHistory]; // 隐藏历史记录
        // 不在这里保存历史，在点击取消或搜索结果时保存
        self.messages = [[[WFCCIMService sharedWFCIMService] searchMessage:self.conversation keyword:searchString order:YES limit:100 offset:0 withUser:nil] mutableCopy];
        self.keyword = searchString;
    } else {
        [self.messages removeAllObjects];
        self.keyword = nil; // 清空关键词
    }

    //刷新表格
    [self.tableView reloadData];

    // 更新分类按钮显示状态
    [self updateCategoryButtonsVisibility];
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    NSString *searchString = [self.searchController.searchBar text];
    if (searchString.length > 0) {
        // 取消时保存到历史记录
        [self addSearchHistory:searchString];
    }
    [self hideSearchHistory]; // 隐藏历史记录
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    // 搜索控制器显示时，如果有历史记录则显示
    // 注意：这里不显示，因为已经有初始关键词了
}

- (void)categoryButtonTapped:(UIButton *)sender {
    if (sender.tag == 0) { // 日期按钮
        // 打开按日期查找界面
        WFCUCalendarSearchViewController *calendarVC = [[WFCUCalendarSearchViewController alloc] init];
        calendarVC.conversation = self.conversation;
        [self.navigationController pushViewController:calendarVC animated:YES];
    } else if (sender.tag == 1) { // 图片与视频按钮
        // 搜索图片和视频消息
        NSArray *contentTypes = @[@(MESSAGE_CONTENT_TYPE_IMAGE), @(MESSAGE_CONTENT_TYPE_VIDEO)];
        NSArray *messages = [[WFCCIMService sharedWFCIMService] getMessages:self.conversation contentTypes:contentTypes fromTime:0 count:100 withUser:nil];

        if (messages.count == 0) {
            // 没有图片或视频消息
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:WFCString(@"Tip")
                                                                           message:WFCString(@"No media messages")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }

        self.imageMsgs = [messages mutableCopy];

        // 创建图片浏览器
        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
        browser.displayActionButton = YES;
        browser.displayNavArrows = NO;
        browser.displaySelectionButtons = NO;
        browser.alwaysShowControls = NO;
        browser.zoomPhotosToFill = NO;
        browser.enableGrid = YES;
        browser.startOnGrid = YES; // 启动时显示网格模式
        browser.enableSwipeToDismiss = NO;
        browser.autoPlayOnAppear = NO;

        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
        nc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:nc animated:YES completion:nil];
    } else if (sender.tag == 2) { // 文件按钮
        // 打开当前会话的文件列表
        WFCUFilesViewController *filesVC = [[WFCUFilesViewController alloc] init];
        filesVC.conversation = self.conversation;
        [self.navigationController pushViewController:filesVC animated:YES];
    } else if (sender.tag == 3) { // 链接按钮
        // 打开当前会话的链接列表
        WFCULinksViewController *linksVC = [[WFCULinksViewController alloc] init];
        linksVC.conversation = self.conversation;
        [self.navigationController pushViewController:linksVC animated:YES];
    } else {
        // 其他按钮，显示 TODO 提示
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"TODO"
                                                                       message:@"此功能开发中"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:WFCString(@"Ok") style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.imageMsgs.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL URLWithString:imgCnt.remoteUrl]];
        photo.caption = [self formatMessageTime:msg.serverTime];
        return photo;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        MWPhoto *photo = [MWPhoto videoWithURL:[NSURL URLWithString:videoCnt.remoteUrl]];
        photo.caption = [self formatMessageTime:msg.serverTime];
        return photo;
    }
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    WFCCMessage *msg = self.imageMsgs[index];
    UIImage *image = nil;
    BOOL video = NO;

    if([msg.content isKindOfClass:[WFCCImageMessageContent class]]) {
        WFCCImageMessageContent *imgCnt = (WFCCImageMessageContent *)msg.content;
        image = imgCnt.thumbnail;
    } else if([msg.content isKindOfClass:[WFCCVideoMessageContent class]]) {
        WFCCVideoMessageContent *videoCnt = (WFCCVideoMessageContent *)msg.content;
        image = videoCnt.thumbnail;
        video = YES;
    }

    MWPhoto *photo = [MWPhoto photoWithImage:image];
    photo.isVideo = video;
    return photo;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return NO;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
}

// 格式化消息时间
- (NSString *)formatMessageTime:(NSUInteger)timestamp {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    return [formatter stringFromDate:date];
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

    // 创建历史记录容器 - 减少顶部空白
    CGFloat headerHeight = 30; // 标题栏高度
    CGFloat tableY = headerHeight - 2; // 减少间距，让列表更靠近标题
    CGFloat tableHeight = MIN(5 * 44, self.searchHistory.count * 44); // 最多显示5条，少于5条则全部显示

    // 创建一个更大的背景视图来接收点击事件
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
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
    titleLabel.text = @"搜索历史";
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.textColor = [UIColor blackColor];
    [self.historyContainer addSubview:titleLabel];

    // 清空按钮 - 调整位置
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [clearButton setTitle:@"清空" forState:UIControlStateNormal];
    clearButton.titleLabel.font = [UIFont systemFontOfSize:13];
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
        UITextField *textField = self.searchController.searchBar.searchTextField;

        // 将背景视图添加到导航控制器的视图上，确保覆盖整个屏幕
        [self.navigationController.view addSubview:bgView];

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
    // 查找并移除背景视图（通过tag识别）
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

@end
