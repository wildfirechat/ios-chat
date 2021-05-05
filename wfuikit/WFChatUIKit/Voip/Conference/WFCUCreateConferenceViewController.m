//
//  WFCUCreateConferenceViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/6/17.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUCreateConferenceViewController.h"
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConferenceViewController.h"
#import "WFCUGeneralSwitchTableViewCell.h"
#import "WFCUGeneralModifyViewController.h"


@interface WFCUCreateConferenceViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)NSString *conferenceTitle;
@property(nonatomic, assign)BOOL audioOnlySwitch;
@property(nonatomic, assign)BOOL audienceSwitch;
@property(nonatomic, assign)BOOL advanceConference;

@property(nonatomic, assign)long long startTime;
@property(nonatomic, assign)long long duration;

@property(nonatomic, strong)UITableView *tableView;
@end

@implementation WFCUCreateConferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    self.conferenceTitle = [NSString stringWithFormat:@"%@的会议", userInfo.displayName];
    self.audioOnlySwitch = NO;
    self.audienceSwitch = NO;
    self.advanceConference = NO;
    
    self.title = @"发起会议";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    CGRect bounds = self.view.bounds;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 100)];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(16, 40, bounds.size.width - 32, 40)];
    [btn setTitle:WFCString(@"开始会议") forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor blueColor];
    btn.layer.masksToBounds = YES;
    btn.layer.cornerRadius = 5.f;
    [btn addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:btn];
    footerView.userInteractionEnabled = YES;

    
    self.tableView.tableFooterView = footerView;
    [self.view addSubview:self.tableView];

    [self.tableView reloadData];
}

- (void)onStart:(id)sender {
    if (self.startTime == 0) {
        WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:nil audioOnly:self.audioOnlySwitch pin:nil host:[WFCCNetworkService sharedInstance].userId title:self.conferenceTitle desc:nil audience:self.audienceSwitch advanced:self.advanceConference moCall:YES];
        [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
    } else {
        //todo 发送会议邀请
    }
    
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        UITableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"title"];
        if (!titleCell) {
            titleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"title"];
        }
        titleCell.textLabel.text = @"会议主题";
        titleCell.detailTextLabel.text = self.conferenceTitle;
        return titleCell;
    } else if(indexPath.section == 1) {
        UITableViewCell *timeCell = [tableView dequeueReusableCellWithIdentifier:@"time"];
        if (!timeCell) {
            timeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"time"];
            timeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (indexPath.row == 0) {
            timeCell.textLabel.text = @"开始时间";
            if (self.startTime == 0) {
                timeCell.detailTextLabel.text = @"现在";
            } else {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.startTime];
                timeCell.detailTextLabel.text = date.description;
            }
            
        } else {
            timeCell.textLabel.text = @"结束时间";
            if (self.duration == 0) {
                timeCell.detailTextLabel.text = @"无限制";
            } else {
                timeCell.detailTextLabel.text = [NSString stringWithFormat:@"%lld秒", self.duration];
            }
        }
        
        return timeCell;
    } else if(indexPath.section == 2) {
        WFCUGeneralSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"switch"];
        if (cell == nil) {
            cell = [[WFCUGeneralSwitchTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"switch"];
        }
        

        if (indexPath.row == 0) {
            cell.textLabel.text = @"开启视频";
            cell.on = !self.audioOnlySwitch;
        } else if(indexPath.row == 1){
            cell.textLabel.text = @"互动会议";
            cell.on = !self.audienceSwitch;
        } else if(indexPath.row == 2) {
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"超级会议" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
            cell.on = self.advanceConference;
        }
        
        cell.type = (int)indexPath.row;
        cell.onSwitch = ^(BOOL value, int type, void (^onDone)(BOOL success)) {
            
            if (type == 0) {
                self.audioOnlySwitch = !self.audioOnlySwitch;
            } else if(type == 1) {
                self.audienceSwitch = !self.audienceSwitch;
            } else if(type == 2) {
                self.advanceConference = !self.advanceConference;
                
                WFCUGeneralSwitchTableViewCell *audienceSwitch = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
                if(self.advanceConference) {
                    audienceSwitch.on = NO;
                    audienceSwitch.valueSwitch.enabled = NO;
                } else {
                    audienceSwitch.valueSwitch.enabled = YES;
                }
            }
            
            onDone(YES);
        };
        
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) { //title
        return 1;
    } else if(section == 1) { //start time
        return 2;
    } else if(section == 2) { //settings
        return 3;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) { //title
        return 60;
    } else if(indexPath.section == 1) { //start time
        return 45;
    } else if(indexPath.section == 2) { //settings
        return 45;
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) { //title
        return 0;
    } else if(section == 1) { //start time
        return 5;
    } else if(section == 2) { //settings
        return 5;
    } else if(section == 3) { // start button
        return 5;
    }
    return 20;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        WFCUGeneralModifyViewController *vc = [[WFCUGeneralModifyViewController alloc] init];
        vc.defaultValue = self.conferenceTitle;
        vc.titleText = @"会议主题";
        vc.noProgress = YES;
        __weak typeof(self) ws = self;
        vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
            if (newValue) {
                ws.conferenceTitle = newValue;
                [ws.tableView reloadData];
                result(YES);
            }
        };
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    } else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            //todo 选择开始时间
        } else {
            //todo 选择会议时长
        }
    }
}
@end
