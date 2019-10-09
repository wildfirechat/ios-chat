//
//  ConversationSearchTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSearchTableViewController.h"
#import "WFCUContactListViewController.h"
#import "WFCUCreateGroupViewController.h"
#import "WFCUFriendRequestViewController.h"

#import "WFCUMessageListViewController.h"

#import "SDWebImage.h"
#import "WFCUUtilities.h"
#import "UITabBar+badge.h"
#import "KxMenu.h"
#import "UIImage+ERCategory.h"
#import "MBProgressHUD.h"

#import "WFCUConversationSearchTableViewCell.h"
#import "WFCUConfigManager.h"


@interface WFCUConversationSearchTableViewController () <UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong)NSMutableArray<WFCCMessage* > *messages;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *searchViewContainer;
@end

@implementation WFCUConversationSearchTableViewController
- (void)initSearchUIAndTableView {
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    if (! @available(iOS 13, *)) {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    self.searchController.searchBar.placeholder = WFCString(@"Search");
    
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    
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

    
    [self.searchController.searchBar setText:self.keyword];
    self.searchController.active = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", userInfo.displayName];
    } else if (self.conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"GroupChatRound"]];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", groupInfo.name];
    } else if(self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        [portraitView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"GroupChatRound"]];
        label.text = [NSString stringWithFormat:@"\"%@\"的聊天记录", channelInfo.name];
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
        self.messages = [[[WFCCIMService sharedWFCIMService] searchMessage:self.conversation keyword:searchString] mutableCopy];
        self.keyword = searchString;
    } else {
        [self.messages removeAllObjects];
    }
    
    //刷新表格
    [self.tableView reloadData];
}
@end
