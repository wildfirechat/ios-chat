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

@interface WFCUConversationSearchTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCMessage* > *messages;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;

// 分类按钮容器
@property (nonatomic, strong) UIView *categoryButtonsView;
// 图片和视频消息数组
@property (nonatomic, strong)NSMutableArray<WFCCMessage *> *imageMsgs;

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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.messages = [[NSMutableArray alloc] init];
    [self initSearchUIAndTableView];
    [self setupCategoryButtonsView];

    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
  return 68;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
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
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUMessageListViewController *mvc = [[WFCUMessageListViewController alloc] init];
    
    mvc.conversation = self.messages[indexPath.row].conversation;
    mvc.highlightMessageId = self.messages[indexPath.row].messageId;
    mvc.highlightText = self.keyword;
    mvc.multiSelecting = self.messageSelecting;
    mvc.selectedMessageIds = self.selectedMessageIds;
    [self.navigationController pushViewController:mvc animated:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
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

- (void)categoryButtonTapped:(UIButton *)sender {
    if (sender.tag == 1) { // 图片与视频按钮
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
@end
