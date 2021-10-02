//
//  WFCUPushToTalkViewController.m
//  WFChatUIKit
//
//  Created by dali on 2021/2/18.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUPushToTalkViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUFloatingWindow.h"
#import "WFCUParticipantCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCCConversation.h>
#import "WFCUPortraitCollectionViewCell.h"
#import "WFCUParticipantCollectionViewLayout.h"
#import "WFCUSeletedUserViewController.h"
#import "UIView+Toast.h"
#import "WFCUConferenceInviteViewController.h"
#import "WFCUConferenceMemberManagerViewController.h"
#import "WFCUConferenceManager.h"
#import "WFCUPTTFloatingWindow.h"
#import "WFCUPortraitCollectionViewCell.h"
#import "WFCUPushToTalkMemberListViewController.h"

#define ButtonSize 60
#define BottomPadding 36
#define SmallVideoView 120
#define OperationTitleFont 10
#define OperationButtonSize 50

#define PortraitItemSize 48
#define PortraitLabelSize 16




#define PTT_STATUS_IDLE 0
#define PTT_STATUS_CONNTCTING 1
#define PTT_STATUS_CONNTCTED 2

@interface WFCUPushToTalkViewController () <WFAVCallSessionDelegate>
@property (nonatomic, strong) WFAVCallSession *currentSession;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) int status; //PTT_STATUS_IDLE idle, PTT_STATUS_CONNTCTING 抢麦中，PTT_STATUS_CONNTCTED 正在发言

@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIButton *membersButton;

@property (nonatomic, strong) UIButton *talkButton;

@property (nonatomic, strong) NSString *talkingUserId;

@property(nonatomic, strong)UIImageView *talkingUserImageView;
@property(nonatomic, strong)UILabel *talkingUserLabel;
@end

@implementation WFCUPushToTalkViewController
- (instancetype)initWithSession:(WFAVCallSession *)session {
    self = [super init];
    if (self) {
        self.currentSession = session;
        self.currentSession.delegate = self;
    }
    return self;
}

- (instancetype)initWithInvite:(WFCCPTTInviteMessageContent *)invite {
    self = [super init];
    if (self) {
        self.currentSession = [[WFAVEngineKit sharedEngineKit]
                               joinPttChannel:invite.callId
                                    audioOnly:YES
                                        pin:invite.pin
                           host:invite.host
                           title:invite.title
                           sessionDelegate:self];
        
        [self didChangeState:kWFAVEngineStateIncomming];
    }
    return self;
}

- (instancetype)initWithCallId:(NSString *_Nullable)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nullable)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title {
    self = [super init];
    if (self) {
            self.currentSession = [[WFAVEngineKit sharedEngineKit]
                                   joinPttChannel:callId
                                        audioOnly:audioOnly
                                            pin:pin
                               host:host
                               title:title
                               sessionDelegate:self];
            [self didChangeState:kWFAVEngineStateIncomming];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    WFCUParticipantCollectionViewLayout *layout2 = [[WFCUParticipantCollectionViewLayout alloc] init];
    layout2.itemHeight = PortraitItemSize + PortraitLabelSize;
    layout2.itemWidth = PortraitItemSize;
    layout2.lineSpace = 6;
    layout2.itemSpace = 6;
    CGRect bounds = self.view.bounds;
    
    self.talkingUserId = self.currentSession.pttTalkingMember;
    
    CGFloat talkBtnSize = 80;
    self.talkButton = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width/2 - talkBtnSize/2, bounds.size.height - talkBtnSize/2 - 180 - kTabbarSafeBottomMargin, talkBtnSize, talkBtnSize)];
    [self.talkButton setTitle:@"按下说话" forState:UIControlStateNormal];
    [self.talkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.talkButton addTarget:self action:@selector(onTalkBtnDown:) forControlEvents:UIControlEventTouchDown];
    [self.talkButton addTarget:self action:@selector(onTalkBtnUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.talkButton addTarget:self action:@selector(onTalkBtnUp:) forControlEvents:UIControlEventTouchUpOutside];
    self.talkButton.layer.cornerRadius = talkBtnSize/2;
    self.talkButton.layer.masksToBounds = YES;
    [self.talkButton setBackgroundColor:[UIColor redColor]];
    
    [self.view addSubview:self.talkButton];
    
    self.exitButton.hidden = NO;
    
    [self rearrangeParticipants];
    [self checkAVPermission];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
}

- (void)setTalkingUserId:(NSString *)talkingUserId {
    _talkingUserId = talkingUserId;
    if(talkingUserId) {
        self.talkingUserImageView.hidden = NO;
        self.talkingUserLabel.hidden = NO;
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:talkingUserId refresh:NO];
        [self.talkingUserImageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
        self.talkingUserLabel.text = userInfo.displayName;
    } else {
        self.talkingUserImageView.hidden = YES;
        self.talkingUserImageView.image = nil;
        self.talkingUserLabel.hidden = YES;
        self.talkingUserLabel.text = nil;
    }
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    [self setTalkingUserId:_talkingUserId];
}

- (void)checkAVPermission {
    [self checkRecordPermission:nil];
}

- (void)checkRecordPermission:(void (^)(BOOL granted))complete {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (complete) {
                complete(granted);
            }
        }];
    }
}

- (void)updateRightNaviBar {
    [self.membersButton setTitle:[NSString stringWithFormat:@"(%ld)", self.currentSession.participantIds.count] forState:UIControlStateNormal];
}

- (void)onTalkBtnDown:(id)sender {
    self.status = PTT_STATUS_CONNTCTING;
    __weak typeof(self)ws = self;
    [self.currentSession requestTalk:^{
        ws.status = PTT_STATUS_CONNTCTED;
    } error:^(int error_code) {
        ws.status = PTT_STATUS_IDLE;
    }];
}

- (void)onTalkBtnUp:(id)sender {
    [self.currentSession releaseTalk];
    self.status = PTT_STATUS_IDLE;
}

- (void)onQuit:(id)sender {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action0 = [UIAlertAction actionWithTitle:@"最小化对讲" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [ws minimize];
        [ws leavelVc];
    }];
    [alertController addAction:action0];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"退出对讲" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(ws.currentSession.state != kWFAVEngineStateIdle) {
            [ws.currentSession leaveConference:NO];
        }
    }];
    [alertController addAction:action1];
    
    if([self.currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"结束对讲" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            if(ws.currentSession.state != kWFAVEngineStateIdle) {
                [ws.currentSession leaveConference:YES];
            }
        }];
        [alertController addAction:action2];
    }
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:actionCancel];
    
    [ws presentViewController:alertController animated:YES completion:nil];
}

- (void)leavelVc {
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)minimize {
    [WFCUPTTFloatingWindow startCallFloatingWindow:self.currentSession withTouchedBlock:^(WFAVCallSession *callSession) {
        WFCUPushToTalkViewController *vc = [[WFCUPushToTalkViewController alloc] initWithSession:callSession];
         [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
     }];
    
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)onMembers:(id)sender {
    WFCUPushToTalkMemberListViewController *vc = [[WFCUPushToTalkMemberListViewController alloc] init];
    vc.currentSession = self.currentSession;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

-(void)setStatus:(int)status {
    _status = status;
    CGFloat talkBtnSize = 80;
    if(status == PTT_STATUS_IDLE) {
        self.statusLabel.hidden = YES;
        [self.talkButton setBackgroundColor:[UIColor redColor]];
        [self.talkButton setTitle:@"按下说话" forState:UIControlStateNormal];
    } else if(status == PTT_STATUS_CONNTCTING) {
        self.statusLabel.hidden = NO;
        self.statusLabel.text = @"正在抢麦中...";
        [self.talkButton setBackgroundColor:[UIColor greenColor]];
        [self.talkButton setTitle:@"松开释放" forState:UIControlStateNormal];
        talkBtnSize = 100;
    } else if(status == PTT_STATUS_CONNTCTED) {
        self.statusLabel.hidden = NO;
        self.statusLabel.text = @"当前持有麦";
        [self.talkButton setBackgroundColor:[UIColor greenColor]];
        [self.talkButton setTitle:@"松开释放" forState:UIControlStateNormal];
        talkBtnSize = 120;
    }
    CGRect bounds = self.view.bounds;
    self.talkButton.frame = CGRectMake(bounds.size.width/2 - talkBtnSize/2, bounds.size.height - talkBtnSize/2 - 180 - kTabbarSafeBottomMargin, talkBtnSize, talkBtnSize);
    self.talkButton.layer.cornerRadius = talkBtnSize/2;
}

- (UILabel *)statusLabel {
    if(!_statusLabel) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 120)];
        _statusLabel.center = CGPointMake(self.view.bounds.size.width/2, 120 + kStatusBarAndNavigationBarHeight);
        [_statusLabel setTextColor:[UIColor whiteColor]];
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_statusLabel];
    }
    return _statusLabel;
}
#define TAKLING_IMAGE_VIEW_SIZE 80
#define TAKLING_LABEL_WIDTH 120
#define TAKLING_LABEL_HEIGHT 20
- (UIImageView *)talkingUserImageView {
    if(!_talkingUserImageView) {
        _talkingUserImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, TAKLING_IMAGE_VIEW_SIZE, TAKLING_IMAGE_VIEW_SIZE)];
        CGPoint point = self.view.center;
        point.y -= TAKLING_LABEL_HEIGHT;
        _talkingUserImageView.center = point;
        _talkingUserImageView.layer.cornerRadius = 10.f;
        _talkingUserImageView.layer.masksToBounds = YES;
        [self.view addSubview:_talkingUserImageView];
    }
    return _talkingUserImageView;
}

- (UILabel *)talkingUserLabel {
    if(!_talkingUserLabel) {
        CGRect bound = self.view.bounds;
        _talkingUserLabel = [[UILabel alloc] initWithFrame:CGRectMake((bound.size.width - TAKLING_LABEL_WIDTH)/2, bound.size.height/2 + TAKLING_IMAGE_VIEW_SIZE/2 - TAKLING_LABEL_HEIGHT + 12, TAKLING_LABEL_WIDTH, TAKLING_LABEL_HEIGHT)];
        _talkingUserLabel.textAlignment = NSTextAlignmentCenter;
        _talkingUserLabel.textColor = [UIColor whiteColor];
        [self.view addSubview:_talkingUserLabel];
    }
    return _talkingUserLabel;
}

- (UIButton *)exitButton {
    if (!_exitButton) {
        _exitButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 26+kStatusBarAndNavigationBarHeight-64, 30, 30)];
        
        [_exitButton setImage:[UIImage imageNamed:@"ptt_exit"] forState:UIControlStateNormal];
        _exitButton.backgroundColor = [UIColor clearColor];
        [_exitButton addTarget:self action:@selector(onQuit:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_exitButton];
    }
    return _exitButton;
}

- (UIButton *)membersButton {
    if (!_membersButton) {
        _membersButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 16 - 30 - 20, 26+kStatusBarAndNavigationBarHeight-64, 30+20, 30)];
        [_membersButton setImage:[UIImage imageNamed:@"ptt_members"] forState:UIControlStateNormal];
        _membersButton.backgroundColor = [UIColor clearColor];
        [_membersButton addTarget:self action:@selector(onMembers:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:_membersButton];
    }
    return _membersButton;
}
/*
 session的participantIds是除了自己外的所有成员。这里把自己也加入列表，然后把发起者放到最后面。
 */
- (void)rearrangeParticipants {
    [self updateRightNaviBar];
}


- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    [self leavelVc];
}

- (void)didChangeInitiator:(NSString * _Nullable)initiator {
    
}

- (void)didChangeMode:(BOOL)isAudioOnly {
    
}

- (void)didChangeState:(WFAVEngineState)state {

}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack * _Nonnull)localVideoTrack {
    
}

- (void)didError:(NSError * _Nonnull)error {
    
}

- (void)didGetStats:(NSArray * _Nonnull)stats {
    
}

- (void)didParticipantConnected:(NSString * _Nonnull)userId {
    
}

- (void)didParticipantJoined:(NSString * _Nonnull)userId {
    [self rearrangeParticipants];
}

- (void)didParticipantLeft:(NSString * _Nonnull)userId withReason:(WFAVCallEndReason)reason {
    [self rearrangeParticipants];
    if([self.talkingUserId isEqualToString:userId]) {
        self.talkingUserId = nil;
    }
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack * _Nonnull)remoteVideoTrack fromUser:(NSString * _Nonnull)userId {
    
}

- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString * _Nonnull)userId {
    
}

- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString * _Nonnull)userId {
    
}

- (void)didChangeType:(BOOL)audience ofUser:(NSString *)userId {
    
}

- (void)didPttTalking:(NSString *)userId {
    self.talkingUserId = userId;
}

- (void)didPttIdle {
    self.talkingUserId = nil;
}
@end
