//
//  MeTableViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/4.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCMeTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "WFCSettingTableViewController.h"
#import "WFCSecurityTableViewController.h"
#import "WFCMeTableViewHeaderViewCell.h"
#import "UIColor+YH.h"
#import "WFCFavoriteTableViewController.h"


@interface WFCMeTableViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)NSArray *itemDataSource;
@end

#define Notification_Setting_Cell   0
#define Favorite_Settings_Cell      1
#define File_Settings_Cell 2
#define Safe_Setting_Cell 3
#define More_Setting_Cell 4

@implementation WFCMeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableHeaderView = nil;
    [self.tableView reloadData];
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    if ([self.tableView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if (@available(iOS 11.0, *)) {
            self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300)];
    header.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
    self.tableView.tableHeaderView = header;
    self.tableView.contentInset = UIEdgeInsetsMake(-300, 0, 0, 0);
    [self.view addSubview:self.tableView];
    
    __weak typeof(self)ws = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInfoUpdated object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if ([[WFCCNetworkService sharedInstance].userId isEqualToString:note.object]) {
            [ws.tableView reloadData];
        }
    }];
    
    if ([[WFCCIMService sharedWFCIMService] isCommercialServer]) {
        self.itemDataSource = @[
            @{@"title":LocalizedString(@"MessageNotification"), @"image":@"notification_setting", @"type":@(Notification_Setting_Cell)},
            @{@"title":LocalizedString(@"Favorite"), @"image":@"favorite_settings", @"type":@(Favorite_Settings_Cell)},
            @{@"title":LocalizedString(@"File"), @"image":@"file_settings", @"type":@(File_Settings_Cell)},
            @{@"title":LocalizedString(@"AccountSafety"), @"image":@"safe_setting", @"type":@(Safe_Setting_Cell)},
            @{@"title":LocalizedString(@"Settings"), @"image":@"MoreSetting", @"type":@(More_Setting_Cell)}
        ];
    } else {
        self.itemDataSource = @[
            @{@"title":LocalizedString(@"MessageNotification"), @"image":@"notification_setting", @"type":@(Notification_Setting_Cell)},
            @{@"title":LocalizedString(@"Favorite"), @"image":@"favorite_settings", @"type":@(Favorite_Settings_Cell)},
            @{@"title":LocalizedString(@"AccountSafety"), @"image":@"safe_setting", @"type":@(Safe_Setting_Cell)},
            @{@"title":LocalizedString(@"Settings"), @"image":@"MoreSetting", @"type":@(More_Setting_Cell)}
        ];
    }
    self.view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.itemDataSource.count+1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return 9;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 9)];
        view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
        return view;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        WFCMeTableViewHeaderViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"profileCell"];
        if (cell == nil) {
            cell = [[WFCMeTableViewHeaderViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"profileCell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:YES];
        cell.userInfo = me;
        cell.backgroundColor = [WFCUConfigManager globalManager].naviBackgroudColor;
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"styleDefault"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"styleDefault"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
        cell.textLabel.text = self.itemDataSource[indexPath.section - 1][@"title"];
        cell.imageView.image = [UIImage imageNamed:self.itemDataSource[indexPath.section - 1][@"image"]];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 154;
    } else {
        return 50;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WFCUMyProfileTableViewController *vc = [[WFCUMyProfileTableViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        int type = [self.itemDataSource[indexPath.section-1][@"type"] intValue];
        if (type == Notification_Setting_Cell) {
           WFCUMessageNotificationViewController *mnvc = [[WFCUMessageNotificationViewController alloc] init];
           mnvc.hidesBottomBarWhenPushed = YES;
           [self.navigationController pushViewController:mnvc animated:YES];
       } else if (type == Favorite_Settings_Cell) {
           WFCFavoriteTableViewController *mnvc = [[WFCFavoriteTableViewController alloc] init];
           mnvc.hidesBottomBarWhenPushed = YES;
           [self.navigationController pushViewController:mnvc animated:YES];
       } else if(type == File_Settings_Cell) {
           WFCUFilesEntryViewController *fevc = [[WFCUFilesEntryViewController alloc] init];
           fevc.hidesBottomBarWhenPushed = YES;
           [self.navigationController pushViewController:fevc animated:YES];
       } else if(type == Safe_Setting_Cell) {
           WFCSecurityTableViewController * stvc = [[WFCSecurityTableViewController alloc] init];
           stvc.hidesBottomBarWhenPushed = YES;
           [self.navigationController pushViewController:stvc animated:YES];
       } else if(type == More_Setting_Cell) {
           WFCSettingTableViewController *vc = [[WFCSettingTableViewController alloc] init];
                  vc.hidesBottomBarWhenPushed = YES;
                  [self.navigationController pushViewController:vc animated:YES];
       }
    }
}
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
