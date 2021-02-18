//
//  WFCUPushToTalkCreateViewController.m
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUPushToTalkCreateViewController.h"
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUPushToTalkViewController.h"
#import "WFCUGeneralModifyViewController.h"

@interface WFCUPushToTalkCreateViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)NSString *channelTitle;
@property(nonatomic, strong)NSString *channelDesc;

@property(nonatomic, strong)UITableView *tableView;
@end

@implementation WFCUPushToTalkCreateViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    self.channelTitle = [NSString stringWithFormat:@"%@的频道", userInfo.displayName];

    self.title = @"创建对讲频道";
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    CGRect bounds = self.view.bounds;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 100)];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(16, 40, bounds.size.width - 32, 40)];
    [btn setTitle:WFCString(@"创建") forState:UIControlStateNormal];
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
    WFCUPushToTalkViewController *vc = [[WFCUPushToTalkViewController alloc] initWithCallId:nil audioOnly:YES pin:nil host:[WFCCNetworkService sharedInstance].userId title:self.channelTitle desc:self.channelDesc audience:YES moCall:YES];
    [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        UITableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"title"];
        if (!titleCell) {
            titleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"title"];
        }
        titleCell.textLabel.text = @"对讲主题";
        titleCell.detailTextLabel.text = self.channelTitle;
        return titleCell;
    } else if(indexPath.section == 1) {
        UITableViewCell *titleCell = [tableView dequeueReusableCellWithIdentifier:@"title"];
        if (!titleCell) {
            titleCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"title"];
        }
        titleCell.textLabel.text = @"描述";
        titleCell.detailTextLabel.text = self.channelDesc;
        return titleCell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
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
    }
    return 5;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WFCUGeneralModifyViewController *vc = [[WFCUGeneralModifyViewController alloc] init];
    vc.noProgress = YES;
    __weak typeof(self) ws = self;
    
    if (indexPath.section == 0) {
        vc.defaultValue = self.channelTitle;
        vc.titleText = @"对讲主题";
        vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
            if (newValue) {
                ws.channelTitle = newValue;
                [ws.tableView reloadData];
                result(YES);
            }
        };
    } else if(indexPath.section == 1) {
        vc.defaultValue = self.channelDesc;
        vc.titleText = @"描述";
        vc.tryModify = ^(NSString *newValue, void (^result)(BOOL success)) {
            if (newValue) {
                ws.channelDesc = newValue;
                [ws.tableView reloadData];
                result(YES);
            }
        };
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}
@end
