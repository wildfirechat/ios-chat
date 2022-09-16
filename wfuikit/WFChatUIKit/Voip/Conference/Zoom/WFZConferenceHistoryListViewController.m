//
//  WFZConferenceHistoryViewController.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/16.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFZConferenceHistoryListViewController.h"
#import "WFCUConferenceManager.h"
#import "WFCUConferenceHistory.h"
#import "WFZConferenceInfo.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFZConferenceHistoryListViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray<WFCUConferenceHistory *> *conferenceHistorys;
@end

@implementation WFZConferenceHistoryListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.conferenceHistorys = [[WFCUConferenceManager sharedInstance] getConferenceHistoryList];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    if (@available(iOS 15, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.conferenceHistorys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if(!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    WFCUConferenceHistory *history = self.conferenceHistorys[indexPath.row];
    cell.textLabel.text = history.conferenceInfo.conferenceTitle;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:history.timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:history.conferenceInfo.owner refresh:NO];
    int duration = history.duration/1000;
    NSString *time = @"";
    if(duration > 3600) {
        time = [time stringByAppendingFormat:@"%d:", duration/3600];
        duration = duration % 3600;
    }
    if(duration > 60) {
        time = [time stringByAppendingFormat:@"%2d:", duration/60];
        duration = duration % 60;
    }
    
    time = [time stringByAppendingFormat:@"%2d", duration];
    
    if(userInfo.displayName.length) {
        NSString *ownerName = userInfo.displayName;
        if(userInfo.friendAlias.length) {
            ownerName = userInfo.friendAlias;
        }
        cell.detailTextLabel.text = [NSString stringWithFormat:@"时间：%@  发起人：%@  时长：%@", [formatter stringFromDate:date], ownerName, time];
    } else {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"时间：%@  时长：%@", [formatter stringFromDate:date], time];
    }
    
    return cell;
}


@end
