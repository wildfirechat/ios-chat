//
//  WFCUAddFriendViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/7.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUSearchChannelViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUChannelProfileViewController.h"
#import "SDWebImage.h"
#import "MBProgressHUD.h"
#import "WFCUConfigManager.h"

@interface WFCUSearchChannelViewController () <UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate>
@property (nonatomic, strong)  UITableView              *tableView;
@property (nonatomic, strong)  UISearchController       *searchController;
@property (nonatomic, strong) NSArray            *searchList;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation WFCUSearchChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initSearchUIAndData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[WFCCIMService sharedWFCIMService] clearUnreadFriendRequestStatus];
}

- (void)initSearchUIAndData {
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.navigationItem.title = WFCString(@"SubscribeChannel");

    _searchList = [NSMutableArray array];
        
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    if (@available(iOS 9.1, *)) {
        self.searchController.obscuresBackgroundDuringPresentation = NO;
    }
    
    if (! @available(iOS 13, *)) {
        [self.searchController.searchBar setValue:WFCString(@"Cancel") forKey:@"_cancelButtonText"];
    }
    self.searchController.searchBar.placeholder = WFCString(@"SearchChannels");
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = YES;
}

#pragma mark - UITableViewDataSource

//table 返回的行数
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchController.active) {
        return [self.searchList count];
    } else {
      return 0;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.searchController.active) {
        WFCCChannelInfo *channelInfo = self.searchList[indexPath.row];
        
        WFCUChannelProfileViewController *pvc = [[WFCUChannelProfileViewController alloc] init];
        pvc.channelInfo = channelInfo;
        [self.navigationController pushViewController:pvc animated:YES];
    }
}
//返回单元格内容
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *flag = @"cell";

    if (self.searchController.active) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:flag];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:flag];
        }
        WFCCChannelInfo *channelInfo = self.searchList[indexPath.row];
        [cell.textLabel setText:channelInfo.name];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
      
      cell.userInteractionEnabled = YES;
      return cell;
    }
    else//如果没有搜索
    {
      return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.searchController.active) {
        [self.searchController.searchBar resignFirstResponder];
    }
}
#pragma mark - UISearchControllerDelegate
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.timer.valid) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(onSearch:) userInfo:nil repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)onSearch:(id)sender {
    __weak typeof(self) ws = self;
    NSString *searchString = [ws.searchController.searchBar text];
    if (searchString.length) {
        [[WFCCIMService sharedWFCIMService] searchChannel:searchString
                                               success:^(NSArray<WFCCChannelInfo *> *machedChannels) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       ws.searchList = machedChannels;
                                                       [ws.tableView reloadData];
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
