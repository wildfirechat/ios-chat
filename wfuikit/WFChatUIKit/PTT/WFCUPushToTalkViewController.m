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

@interface WFCUPushToTalkViewController () <WFAVCallSessionDelegate,UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *portraitCollectionView;

@property (nonatomic, strong) WFAVCallSession *currentSession;

@property (nonatomic, strong) NSMutableArray<NSString *> *participants;
@property (nonatomic, strong) NSMutableArray<NSString *> *audiences;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) int status; //PTT_STATUS_IDLE idle, PTT_STATUS_CONNTCTING 抢麦中，PTT_STATUS_CONNTCTED 正在发言

@property (nonatomic, strong) UIButton *exitButton;
@property (nonatomic, strong) UIButton *membersButton;

@property (nonatomic, strong) UIButton *talkButton;
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
                               joinConference:invite.callId
                                    audioOnly:YES
                                        pin:invite.pin
                               host:invite.host
                               title:invite.title
                               desc:invite.desc
                               audience:YES
                               advanced:NO
                               muteAudio:NO
                               muteVideo:NO
                               sessionDelegate:self];
        
        
        
        
        [self didChangeState:kWFAVEngineStateIncomming];
    }
    return self;
}

- (instancetype)initWithCallId:(NSString *_Nullable)callId
                     audioOnly:(BOOL)audioOnly
                           pin:(NSString *_Nullable)pin
                          host:(NSString *_Nullable)host
                         title:(NSString *_Nullable)title
                          desc:(NSString *_Nullable)desc
                      audience:(BOOL)audience
                        moCall:(BOOL)moCall {
    self = [super init];
    if (self) {
        if (moCall) {
            self.currentSession = [[WFAVEngineKit sharedEngineKit] startConference:callId audioOnly:audioOnly pin:pin host:host title:title desc:desc audience:audience advanced:NO record:NO sessionDelegate:self];
            
            [self didChangeState:kWFAVEngineStateOutgoing];
        } else {
            self.currentSession = [[WFAVEngineKit sharedEngineKit]
                                   joinConference:callId
                                        audioOnly:audioOnly
                                            pin:pin
                               host:host
                               title:title
                               desc:desc
                               audience:audience
                                   advanced:NO
                                   muteAudio:NO
                                   muteVideo:NO
                               sessionDelegate:self];
            [self didChangeState:kWFAVEngineStateIncomming];
        
        }
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
    
    self.portraitCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, 120 + kStatusBarAndNavigationBarHeight + 20, bounds.size.width - 32, bounds.size.height - 300 - kTabbarSafeBottomMargin) collectionViewLayout:layout2];
    self.portraitCollectionView.dataSource = self;
    self.portraitCollectionView.delegate = self;
    [self.portraitCollectionView registerClass:[WFCUPortraitCollectionViewCell class] forCellWithReuseIdentifier:@"cell2"];
    self.portraitCollectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.portraitCollectionView];
    
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
    [self.membersButton setTitle:[NSString stringWithFormat:@"(%ld)", self.audiences.count + self.participants.count] forState:UIControlStateNormal];
}

- (void)onTalkBtnDown:(id)sender {
    self.status = PTT_STATUS_CONNTCTING;
    [self.currentSession switchAudience:NO];
}

- (void)onTalkBtnUp:(id)sender {
    if(!self.currentSession.audience) {
        [self.currentSession switchAudience:YES];
    }
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
    if(self.status != PTT_STATUS_IDLE) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:YES];
    }
    
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
        [self.view addSubview:_statusLabel];
    }
    return _statusLabel;
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
    self.participants = [[NSMutableArray alloc] init];
    self.audiences = [[NSMutableArray alloc] init];
    
    
    NSArray<WFAVParticipantProfile *> *ps = self.currentSession.participants;
    for (WFAVParticipantProfile *p in ps) {
        if (p.audience) {
            [self.audiences addObject:p.userId];
        } else {
            [self.participants addObject:p.userId];
        }
    }
    if(self.currentSession.isAudience) {
        [self.audiences addObject:[WFCCNetworkService sharedInstance].userId];
    } else {
        [self.participants addObject:[WFCCNetworkService sharedInstance].userId];
    }
    
    if ([self.participants containsObject:self.currentSession.host]) {
        [self.participants removeObject:self.currentSession.host];
        [self.participants addObject:self.currentSession.host];
    }
    
    [self updateRightNaviBar];
    [self.portraitCollectionView reloadData];
}


- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    [self leavelVc];
}

- (void)didChangeInitiator:(NSString * _Nullable)initiator {
    
}

- (void)didChangeMode:(BOOL)isAudioOnly {
    
}

- (void)didChangeState:(WFAVEngineState)state {
    if(state == kWFAVEngineStateConnected) {
        if(!self.currentSession.audience) {
            [self.currentSession switchAudience:YES];
        }
    }
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
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack * _Nonnull)remoteVideoTrack fromUser:(NSString * _Nonnull)userId {
    
}

- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString * _Nonnull)userId {
    
}

- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString * _Nonnull)userId {
    
}

- (void)didChangeType:(BOOL)audience ofUser:(NSString *)userId {
    if([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        self.status = audience ? PTT_STATUS_IDLE : PTT_STATUS_CONNTCTED;
    } else {
        
    }
    
    [self.currentSession enableSpeaker:YES];
    [self rearrangeParticipants];
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.currentSession.audioOnly && (self.currentSession.state == kWFAVEngineStateConnecting || self.currentSession.state == kWFAVEngineStateConnected)) {
        return self.participants.count;
    }
    
    return 0;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *userId = self.participants[indexPath.row];
    
    WFCUPortraitCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell2" forIndexPath:indexPath];
    
    cell.itemSize = PortraitItemSize;
    cell.labelSize = PortraitLabelSize;
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    cell.userInfo = userInfo;
    
    if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        cell.profile = self.currentSession.myProfile;
    } else {
        for (WFAVParticipantProfile *profile in self.currentSession.participants) {
            if ([profile.userId isEqualToString:userId]) {
                cell.profile = profile;
                break;
            }
        }
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
