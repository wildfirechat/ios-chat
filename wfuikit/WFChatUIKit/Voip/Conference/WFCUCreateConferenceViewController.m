//
//  WFCUCreateConferenceViewController.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/6/17.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUCreateConferenceViewController.h"
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUConferenceViewController.h"

@interface WFCUCreateConferenceViewController ()
@property(nonatomic, strong)UITextField *conferenceTitle;
@property(nonatomic, strong)UITextField *conferenceDesc;
@property(nonatomic, strong)UISwitch *audioOnlySwitch;
@property(nonatomic, strong)UISwitch *audienceSwitch;
@property(nonatomic, strong)UIButton *startBtn;
@end

@implementation WFCUCreateConferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[WFCCNetworkService sharedInstance].userId refresh:NO];
    
    
    CGRect bounds = self.view.bounds;
    
    CGFloat padding = 40;
    CGFloat h = kStatusBarAndNavigationBarHeight+padding;
    
    self.conferenceTitle = [[UITextField alloc] initWithFrame:CGRectMake(16, h, bounds.size.width - 32, 32)];
    self.conferenceTitle.placeholder = @"请输入会议标题";
    self.conferenceTitle.text = [NSString stringWithFormat:@"%@的会议", userInfo.displayName];
    [self.view addSubview:self.conferenceTitle];
    
    h+=padding;
    self.conferenceDesc = [[UITextField alloc] initWithFrame:CGRectMake(16, h, bounds.size.width - 32, 32)];
    self.conferenceDesc.placeholder = @"请输入会议描述";
    [self.view addSubview:self.conferenceDesc];
    
    h+=padding;
    UILabel *audioLable = [[UILabel alloc] initWithFrame:CGRectMake(bounds.size.width - 140 - 16, h, 80, 24)];
    audioLable.text = @"开启视频";
    [self.view addSubview:audioLable];
    self.audioOnlySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(bounds.size.width - 60 - 16, h, 60, 24)];
    [self.view addSubview:self.audioOnlySwitch];
    
    h+=padding;
    UILabel *audienceLable = [[UILabel alloc] initWithFrame:CGRectMake(bounds.size.width - 140 - 16, h, 80, 24)];
    audienceLable.text = @"观众模式";
    [self.view addSubview:audienceLable];
    self.audienceSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(bounds.size.width - 60 - 16, h, 60, 24)];
    [self.view addSubview:self.audienceSwitch];
    
    self.startBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 40)];
    self.startBtn.center = self.view.center;
    [self.startBtn setTitle:@"开始" forState:UIControlStateNormal];
    [self.startBtn setBackgroundColor:[UIColor greenColor]];
    [self.startBtn addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.startBtn];
    
}

- (void)onStart:(id)sender {
    WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:nil audioOnly:self.audienceSwitch.on pin:nil host:[WFCCNetworkService sharedInstance].userId title:self.conferenceTitle.text desc:self.conferenceDesc.text audience:self.audienceSwitch.on moCall:YES];
    [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
}
@end
