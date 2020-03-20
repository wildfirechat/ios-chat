//
//  DiscoverViewController.m
//  Wildfire Chat
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "DiscoverViewController.h"
#import "ChatroomListViewController.h"
#import <WFChatUIKit/WFChatUIKit.h>
#import <WFChatClient/WFCCIMService.h>
#import "DiscoverMomentsTableViewCell.h"
#import <WFMomentClient/WFMomentClient.h>
#import <WFMomentUIKit/WFMomentUIKit.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"

@interface DiscoverViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, assign)BOOL hasMoments;
@end

@implementation DiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(NSClassFromString(@"SDTimeLineTableViewController")) {
        self.hasMoments = YES;
    } else {
        self.hasMoments = NO;
    }
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
#ifdef WFC_MOMENTS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveComments:) name:kReceiveComments object:nil];
#endif
}

- (void)onReceiveComments:(NSNotification *)notification {
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUnreadStatus];
}

- (void)updateUnreadStatus {
    [self.tableView reloadData];
#ifdef WFC_MOMENTS
    [self.tabBarController.tabBar showBadgeOnItemIndex:2 badgeValue:[[WFMomentService sharedService] getUnreadCount]];
#endif
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 9)];
    view.backgroundColor = [UIColor colorWithHexString:@"0xededed"];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 9;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        if(self.hasMoments) {
            UIViewController *vc = [[NSClassFromString(@"SDTimeLineTableViewController") alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            ChatroomListViewController *vc = [[ChatroomListViewController alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        if (self.hasMoments) {
            ChatroomListViewController *vc = [[ChatroomListViewController alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            WFCUBrowserViewController *vc = [[WFCUBrowserViewController alloc] init];
            vc.hidesBottomBarWhenPushed = YES;
            vc.url = @"http://docs.wildfirechat.cn";
            [self.navigationController pushViewController:vc animated:YES];
        }
        
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        WFCUBrowserViewController *vc = [[WFCUBrowserViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        vc.url = @"http://docs.wildfirechat.cn";
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.hasMoments) {
        return 3;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0 && self.hasMoments) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"momentsCell"];
        if (cell == nil) {
            cell = [[DiscoverMomentsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"momentsCell"];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"defaultCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"defaultCell"];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0) {
        if (self.hasMoments) {
            DiscoverMomentsTableViewCell *momentsCell = (DiscoverMomentsTableViewCell *)cell;
            cell.textLabel.text = LocalizedString(@"Moments");
            cell.imageView.image = [UIImage imageNamed:@"AlbumReflashIcon"];
            
            __weak typeof(self)ws = self;
#ifdef WFC_MOMENTS
            int unread = [[WFMomentService sharedService] getUnreadCount];
            if (unread) {
                momentsCell.bubbleView.hidden = NO;
                [momentsCell.bubbleView setBubbleTipNumber:unread];
            } else {
                momentsCell.bubbleView.hidden = YES;
            }
            NSMutableArray<WFMFeed *> *feeds = [[WFMomentService sharedService] restoreCache:nil];
            if (feeds.count > 0) {
                momentsCell.lastFeed = [feeds objectAtIndex:0];
            } else {
                [[WFMomentService sharedService] getFeeds:0 count:10 fromUser:nil success:^(NSArray<WFMFeed *> * _Nonnull feeds) {
                    if (feeds.count) {
                        [[WFMomentService sharedService] storeCache:feeds forUser:nil];
                        [ws.tableView reloadData];
                    }
                } error:^(int error_code) {
                    
                }];
            }
#endif
        } else {
            cell.textLabel.text = LocalizedString(@"Chatroom");
            cell.imageView.image = [UIImage imageNamed:@"discover_chatroom"];
        }
    } else if(indexPath.section == 1) {
        if (self.hasMoments) {
            cell.textLabel.text = LocalizedString(@"Chatroom");
            cell.imageView.image = [UIImage imageNamed:@"discover_chatroom"];
        } else {
            cell.textLabel.text = LocalizedString(@"DevDocs");
            cell.imageView.image = [UIImage imageNamed:@"dev_docs"];
        }
    } else if(indexPath.section == 2) {
        if (self.hasMoments) {
            cell.textLabel.text = LocalizedString(@"DevDocs");
            cell.imageView.image = [UIImage imageNamed:@"dev_docs"];
        }
    }
    
    return cell;
}

@end
