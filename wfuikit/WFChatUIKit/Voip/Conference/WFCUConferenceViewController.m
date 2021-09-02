//
//  ViewController.m
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import "WFCUConferenceViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#if WFCU_SUPPORT_VOIP
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUFloatingWindow.h"
#import "WFCUParticipantCollectionViewCell.h"
#endif
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCCConversation.h>
#import "WFCUPortraitCollectionViewCell.h"
#import "WFCUParticipantCollectionViewLayout.h"
#import "WFCUSeletedUserViewController.h"
#import "UIView+Toast.h"
#import "WFCUConferenceInviteViewController.h"
#import "WFCUConferenceMemberManagerViewController.h"
#import "WFCUConferenceManager.h"


#define BOTTOM_BAR_HEIGHT  54
@interface WFCUConferenceViewController () <UITextFieldDelegate
#if WFCU_SUPPORT_VOIP
    ,WFAVCallSessionDelegate
#endif
    ,UICollectionViewDataSource
    ,UICollectionViewDelegate
    ,WFCUConferenceManagerDelegate
>
#if WFCU_SUPPORT_VOIP
@property (nonatomic, strong) UIView *bigVideoView;
@property (nonatomic, strong) UIImageView *bigVideoPortraitView;
@property (nonatomic, strong) UICollectionView *smallCollectionView;

@property (nonatomic, strong) UICollectionView *portraitCollectionView;
@property (nonatomic, strong) UIButton *hangupButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *speakerButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *scalingButton;
@property (nonatomic, strong) UIButton *minimizeButton;
@property (nonatomic, strong) UIButton *managerButton;
@property (nonatomic, strong) UIButton *screenSharingButton;

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *connectTimeLabel;

@property (nonatomic, strong) WFAVCallSession *currentSession;

@property (nonatomic, assign) WFAVVideoScalingType smallScalingType;
@property (nonatomic, assign) WFAVVideoScalingType bigScalingType;

@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGRect panStartVideoFrame;
@property (nonatomic, strong) NSTimer *connectedTimer;

@property (nonatomic, strong) NSMutableArray<NSString *> *participants;
@property (nonatomic, strong) NSMutableArray<NSString *> *audiences;

//视频时，大屏用户正在说话
@property (nonatomic, strong)UIImageView *speakingView;

@property (nonatomic, strong)NSString *focusUser;

@property(nonatomic, strong)UIView *bottomBarView;

@property(nonatomic, strong)NSTimer *hidePanelTimer;
#endif
@end

#define ButtonSize 60
#define BottomPadding 36
#define SmallVideoView 120
#define OperationTitleFont 10
#define OperationButtonSize 50

#define PortraitItemSize 48
#define PortraitLabelSize 16

@implementation WFCUConferenceViewController
#if !WFCU_SUPPORT_VOIP
- (instancetype)initWithSession:(WFAVCallSession *)session {
    self = [super init];
    return self;
}

- (instancetype)initWithTargets:(NSArray<NSString *> *)targetIds conversation:(WFCCConversation *)conversation audioOnly:(BOOL)audioOnly {
    self = [super init];
    return self;
}
#else
- (instancetype)initWithSession:(WFAVCallSession *)session {
    self = [super init];
    if (self) {
        self.currentSession = session;
        self.currentSession.delegate = self;
        [self rearrangeParticipants];
    }
    return self;
}

- (instancetype)initWithInvite:(WFCCConferenceInviteMessageContent *)invite {
    self = [super init];
    if (self) {
        self.currentSession = [[WFAVEngineKit sharedEngineKit]
                               joinConference:invite.callId
                                    audioOnly:invite.audioOnly
                                        pin:invite.pin
                               host:invite.host
                               title:invite.title
                               desc:invite.desc
                               audience:invite.audience
                               advanced:invite.advanced
                               muteAudio:NO
                               muteVideo:NO
                               sessionDelegate:self];
        
        
        
        
        [self didChangeState:kWFAVEngineStateIncomming];
        [self rearrangeParticipants];
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
                      advanced:(BOOL)advanced
                        moCall:(BOOL)moCall {
    self = [super init];
    if (self) {
        if (moCall) {
            self.currentSession = [[WFAVEngineKit sharedEngineKit] startConference:callId audioOnly:audioOnly pin:pin host:host title:title desc:desc audience:audience advanced:advanced record:NO sessionDelegate:self];
            
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
                                   advanced:advanced
                                   muteAudio:NO
                                   muteVideo:NO
                               sessionDelegate:self];
            [self didChangeState:kWFAVEngineStateIncomming];
        
        }
        
        
        
        [self rearrangeParticipants];
    }
    return self;
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
    
    if (self.focusUser && [self.participants containsObject:self.focusUser]) {
        if ([self.participants containsObject:self.currentSession.host]) {
            [self.participants removeObject:self.currentSession.host];
            [self.participants insertObject:self.currentSession.host atIndex:0];
        }

        [self setFocusUser:_focusUser];
    } else {
        if ([self.participants containsObject:self.currentSession.host]) {
            [self.participants removeObject:self.currentSession.host];
            [self.participants addObject:self.currentSession.host];
        }
    }
    [self.managerButton setTitle:[NSString stringWithFormat:@"管理(%ld)", self.participants.count + self.audiences.count] forState:UIControlStateNormal];
    [self.managerButton setTitleEdgeInsets:UIEdgeInsetsMake((self.managerButton.imageView.frame.size.height+24)/2 ,-self.managerButton.imageView.frame.size.width, 0.0,0.0)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWidth = (self.view.frame.size.width + layout.minimumLineSpacing)/3 - layout.minimumLineSpacing;
    
    self.smallScalingType = kWFAVVideoScalingTypeAspectFit;
    self.bigScalingType = kWFAVVideoScalingTypeAspectFit;
    self.bigVideoView = [[UIView alloc] initWithFrame:self.view.bounds];
    UITapGestureRecognizer *tapBigVideo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickedBigVideoView:)];
    [self.bigVideoView addGestureRecognizer:tapBigVideo];
    self.bigVideoPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, itemWidth, itemWidth)];
    self.bigVideoPortraitView.center = self.bigVideoView.center;
    [self.bigVideoView addSubview:self.bigVideoPortraitView];
    [self.view addSubview:self.bigVideoView];
    
    
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    int lines = (int)([self.currentSession participantIds].count + 2) /3;
    self.smallCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, kStatusBarAndNavigationBarHeight, self.view.frame.size.width, (itemWidth + layout.minimumLineSpacing)*lines-layout.minimumLineSpacing) collectionViewLayout:layout];
    
    self.smallCollectionView.dataSource = self;
    self.smallCollectionView.delegate = self;
    [self.smallCollectionView registerClass:[WFCUParticipantCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    self.smallCollectionView.backgroundColor = [UIColor clearColor];
    
    [self.smallCollectionView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoPan:)]];
    if (self.currentSession.audioOnly) {
        self.smallCollectionView.hidden = YES;
    }
    [self.view addSubview:self.smallCollectionView];
    
    
    WFCUParticipantCollectionViewLayout *layout2 = [[WFCUParticipantCollectionViewLayout alloc] init];
    layout2.itemHeight = PortraitItemSize + PortraitLabelSize;
    layout2.itemWidth = PortraitItemSize;
    layout2.lineSpace = 6;
    layout2.itemSpace = 6;

    self.portraitCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(16, self.view.frame.size.height - BottomPadding - ButtonSize - (PortraitItemSize + PortraitLabelSize)*3 - PortraitLabelSize, self.view.frame.size.width - 32, (PortraitItemSize + PortraitLabelSize)*3 + PortraitLabelSize) collectionViewLayout:layout2];
    self.portraitCollectionView.dataSource = self;
    self.portraitCollectionView.delegate = self;
    [self.portraitCollectionView registerClass:[WFCUPortraitCollectionViewCell class] forCellWithReuseIdentifier:@"cell2"];
    self.portraitCollectionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.portraitCollectionView];
    
    
    [self checkAVPermission];
    
    if(self.currentSession.state == kWFAVEngineStateOutgoing && !self.currentSession.isAudioOnly) {
        [[WFAVEngineKit sharedEngineKit] startPreview];
    }
    
    WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.initiator inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    self.portraitView = [[UIImageView alloc] init];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[user.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    self.portraitView.layer.masksToBounds = YES;
    self.portraitView.layer.cornerRadius = 8.f;
    [self.view addSubview:self.portraitView];
    
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.font = [UIFont systemFontOfSize:26];
    self.userNameLabel.text = user.displayName;
    self.userNameLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.userNameLabel];
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = [UIFont systemFontOfSize:16];
    self.stateLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.stateLabel];
    
    self.connectTimeLabel = [[UILabel alloc] init];
    self.connectTimeLabel.font = [UIFont systemFontOfSize:16];
    self.connectTimeLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.connectTimeLabel];
    
    
    
    [self updateTopViewFrame];
    self.bottomBarView.hidden = NO;
    
    
    [self didChangeState:self.currentSession.state];//update ui
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [self onDeviceOrientationDidChange];
    
    [WFCUConferenceManager sharedInstance].delegate = self;
    [self startHidePanelTimer];
}

- (UIButton *)minimizeButton {
    if (!_minimizeButton) {
        _minimizeButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 26+kStatusBarAndNavigationBarHeight-64, 30, 30)];
        
        [_minimizeButton setImage:[UIImage imageNamed:@"minimize"] forState:UIControlStateNormal];
        [_minimizeButton setImage:[UIImage imageNamed:@"minimize_hover"] forState:UIControlStateHighlighted];
        [_minimizeButton setImage:[UIImage imageNamed:@"minimize_hover"] forState:UIControlStateSelected];
        
        _minimizeButton.backgroundColor = [UIColor clearColor];
        [_minimizeButton addTarget:self action:@selector(minimizeButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _minimizeButton.hidden = YES;
        [self.view addSubview:_minimizeButton];
    }
    return _minimizeButton;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 16 - 30, 26+kStatusBarAndNavigationBarHeight-64, 30, 30)];
        [_switchCameraButton setImage:[UIImage imageNamed:@"switchcamera"] forState:UIControlStateNormal];
        [_switchCameraButton setImage:[UIImage imageNamed:@"switchcamera_hover"] forState:UIControlStateHighlighted];
        [_switchCameraButton setImage:[UIImage imageNamed:@"switchcamera_hover"] forState:UIControlStateSelected];
        _switchCameraButton.backgroundColor = [UIColor clearColor];
        [_switchCameraButton addTarget:self action:@selector(switchCameraButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _switchCameraButton.hidden = YES;
        [self.view addSubview:_switchCameraButton];
    }
    return _switchCameraButton;
}

- (UIButton *)scalingButton {
    if (!_scalingButton) {
        _scalingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_scalingButton setTitle:WFCString(@"Scale") forState:UIControlStateNormal];
        _scalingButton.backgroundColor = [UIColor greenColor];
        [_scalingButton addTarget:self action:@selector(scalingButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _scalingButton.hidden = YES;
        [self.view addSubview:_scalingButton];
    }
    return _scalingButton;
}

- (UIImageView *)speakingView {
    if (!_speakingView) {
        _speakingView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.bigVideoView.bounds.size.height - 20, 20, 20)];

        _speakingView.layer.masksToBounds = YES;
        _speakingView.layer.cornerRadius = 2.f;
        _speakingView.image = [UIImage imageNamed:@"speaking"];
        _speakingView.hidden = YES;
        [self.bigVideoView addSubview:_speakingView];
    }
    return _speakingView;
}

- (UIButton *)createBarButtom:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName select:(SEL)selector frame:(CGRect)frame {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    btn.clipsToBounds = YES;
    [btn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btn.titleLabel.font = [UIFont systemFontOfSize:12];
    [btn setTitleEdgeInsets:UIEdgeInsetsMake((btn.imageView.frame.size.height+24)/2 ,-btn.imageView.frame.size.width, 0.0,0.0)];
    [btn setImageEdgeInsets:UIEdgeInsetsMake((-btn.titleLabel.frame.size.height-24)/2, 0.0,0.0, -btn.titleLabel.bounds.size.width)];
    [btn setTitleColor:[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1] forState:UIControlStateNormal];
    [btn addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [btn setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateHighlighted];
    [btn setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    return btn;
}

- (UIView *)bottomBarView {
    if(!_bottomBarView) {
        _bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - kTabbarSafeBottomMargin-BOTTOM_BAR_HEIGHT, self.view.bounds.size.width, BOTTOM_BAR_HEIGHT+kTabbarSafeBottomMargin)];
        _bottomBarView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        CGFloat btnWidth = self.view.bounds.size.width/(self.currentSession.isAudioOnly ? 4 : 5);
        
        int index = 1;
        self.audioButton = [self createBarButtom:@"静音" imageName:@"conference_audio" selectedImageName:@"conference_audio" select:@selector(audioButtonDidTap:) frame:CGRectMake(0, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.audioButton];
        
        self.videoButton = [self createBarButtom:@"视频" imageName:@"conference_video" selectedImageName:@"conference_video" select:@selector(videoButtonDidTap:) frame:CGRectMake(btnWidth, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.videoButton];
        
        self.speakerButton = [self createBarButtom:@"扬声器" imageName:@"conference_speaker" selectedImageName:@"conference_speaker" select:@selector(speakerButtonDidTap:) frame:CGRectMake(btnWidth, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.speakerButton];
        
        if(self.currentSession.state == kWFAVEngineStateConnected) {
            if(self.currentSession.audioOnly) {
                self.videoButton.hidden = YES;
                self.speakerButton.hidden = NO;
            } else {
                self.videoButton.hidden = NO;
                self.speakerButton.hidden = YES;
            }
        } else {
            self.videoButton.hidden = YES;
            self.speakerButton.hidden = YES;
        }
        
        index++;
        if(!self.currentSession.isAudioOnly) {
            self.screenSharingButton = [self createBarButtom:@"屏幕共享" imageName:@"conference_screen_sharing" selectedImageName:@"conference_screen_sharing_hover" select:@selector(screenSharingButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
            
            if(self.currentSession.state == kWFAVEngineStateConnected)
                self.screenSharingButton.hidden = NO;
            else
                self.screenSharingButton.hidden = YES;
            [self updateScreenSharingButton];
            [_bottomBarView addSubview:self.screenSharingButton];
        }
        
        
        self.managerButton = [self createBarButtom:[NSString stringWithFormat:@"管理(%ld)", self.participants.count + self.audiences.count] imageName:@"conference_members" selectedImageName:@"conference_members" select:@selector(managerButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.managerButton];
        
        self.hangupButton = [self createBarButtom:@"结束" imageName:@"conference_end_call" selectedImageName:@"conference_end_call" select:@selector(hanupButtonDidTap:) frame:CGRectMake(btnWidth*index++, 0, btnWidth, BOTTOM_BAR_HEIGHT)];
        [_bottomBarView addSubview:self.hangupButton];
        
        [self.view addSubview:_bottomBarView];
    }
    return _bottomBarView;
}

- (void)startConnectedTimer {
    [self stopConnectedTimer];
    self.connectedTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(updateConnectedTimeLabel)
                                                      userInfo:nil
                                                       repeats:YES];
    [self.connectedTimer fire];
}

- (void)stopConnectedTimer {
    if (self.connectedTimer) {
        [self.connectedTimer invalidate];
        self.connectedTimer = nil;
    }
}

- (void)setFocusUser:(NSString *)userId {
    _focusUser = userId;
    if (userId) {
        [self.participants removeObject:userId];
        [self.participants addObject:userId];
    }
}

- (void)updateConnectedTimeLabel {
    long sec = [[NSDate date] timeIntervalSince1970] - self.currentSession.connectedTime / 1000;
    if (sec < 60 * 60) {
        self.connectTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", sec / 60, sec % 60];
    } else {
        self.connectTimeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", sec / 60 / 60, (sec / 60) % 60, sec % 60];
    }
}

- (void)hanupButtonDidTap:(UIButton *)button {
    if([self.currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"如果您想让与会人员继续开会，请选择退出会议" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"退出会议" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if(ws.currentSession.state != kWFAVEngineStateIdle) {
                [ws.currentSession leaveConference:NO];
            }
        }];
        [alertController addAction:action1];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"结束会议" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            if(ws.currentSession.state != kWFAVEngineStateIdle) {
                [ws.currentSession leaveConference:YES];
            }
        }];
        [alertController addAction:action2];
        
        [ws presentViewController:alertController animated:YES completion:nil];
    } else {
        [self.currentSession leaveConference:NO];
    }
}

- (void)managerButtonDidTap:(UIButton *)button {
    WFCUConferenceMemberManagerViewController *vc = [[WFCUConferenceMemberManagerViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)screenSharingButtonDidTap:(UIButton *)button {
    [self.currentSession setInAppScreenSharing:!self.currentSession.isInAppScreenSharing];
    [self updateScreenSharingButton];
    if(self.currentSession.isInAppScreenSharing) {
        [self minimizeButtonDidTap:nil];
    }
}

- (void)updateScreenSharingButton {
    self.screenSharingButton.selected = self.currentSession.isInAppScreenSharing;
}

- (void)minimizeButtonDidTap:(UIButton *)button {
    __block NSString *focusUser = [self.participants lastObject];
    [WFCUFloatingWindow startCallFloatingWindow:self.currentSession focusUser:focusUser withTouchedBlock:^(WFAVCallSession *callSession) {
        WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithSession:callSession];
        [vc setFocusUser:focusUser];
        [vc reloadVideoUI];
         [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
     }];
    
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)switchCameraButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession switchCamera];
    }
}

- (void)audioButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession muteAudio:!self.currentSession.audioMuted];
        [self updateAudioButton];
    }
}

- (void)updateAudioButton {
    if (self.currentSession.audioMuted) {
        [self.audioButton setImage:[UIImage imageNamed:@"conference_audio_mute"] forState:UIControlStateNormal];
    } else {
        [self.audioButton setImage:[UIImage imageNamed:@"conference_audio"] forState:UIControlStateNormal];
    }
    
    self.audioButton.enabled = !self.currentSession.audience;
}
- (void)speakerButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession enableSpeaker:!self.currentSession.isSpeaker];
        [self updateSpeakerButton];
    }
}

- (void)updateSpeakerButton {
    if([self.currentSession isHeadsetPluggedIn] || [self.currentSession isBluetoothSpeaker]) {
        self.speakerButton.enabled = NO;
    } else {
        self.speakerButton.enabled = YES;
    }
    
    if (!self.currentSession.isSpeaker) {
        [self.speakerButton setImage:[UIImage imageNamed:@"conference_speaker_disable"] forState:UIControlStateNormal];
    } else {
        [self.speakerButton setImage:[UIImage imageNamed:@"conference_speaker"] forState:UIControlStateNormal];
    }
}

- (void)updateVideoButton {
    if (self.currentSession.videoMuted) {
        [self.videoButton setImage:[UIImage imageNamed:@"conference_video_mute"] forState:UIControlStateNormal];
    } else {
        [self.videoButton setImage:[UIImage imageNamed:@"conference_video"] forState:UIControlStateNormal];
    }
    self.videoButton.enabled = !self.currentSession.audience;
}

//1.决定当前界面是否开启自动转屏，如果返回NO，后面两个方法也不会被调用，只是会支持默认的方向
- (BOOL)shouldAutorotate {
      return YES;
}

//2.返回支持的旋转方向
//iPad设备上，默认返回值UIInterfaceOrientationMaskAllButUpSideDwon
//iPad设备上，默认返回值是UIInterfaceOrientationMaskAll
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
     return UIDeviceOrientationLandscapeLeft | UIDeviceOrientationLandscapeRight | UIDeviceOrientationPortrait;
}

//3.返回进入界面默认显示方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
     return UIInterfaceOrientationPortrait;
}

- (BOOL)onDeviceOrientationDidChange{
    //获取当前设备Device
    UIDevice *device = [UIDevice currentDevice] ;
    NSString *lastUser;
    switch (device.orientation) {
        case UIDeviceOrientationFaceUp:
//            NSLog(@"屏幕幕朝上平躺");
            break;

        case UIDeviceOrientationFaceDown:
            //NSLog(@"屏幕朝下平躺");
            break;

        case UIDeviceOrientationUnknown:
            //系统当前无法识别设备朝向，可能是倾斜
            //NSLog(@"未知方向");
            break;

        case UIDeviceOrientationLandscapeLeft:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.bigVideoView.frame = self.view.bounds;
            lastUser = [self.participants lastObject];
            if ([lastUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            } else {
                [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.bigScalingType forUser:lastUser];
            }
            break;

        case UIDeviceOrientationLandscapeRight:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.bigVideoView.frame = self.view.bounds;
            lastUser = [self.participants lastObject];
            if ([lastUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            } else {
                [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.bigScalingType forUser:lastUser];
            }
            break;

        case UIDeviceOrientationPortrait:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(0);
            self.bigVideoView.frame = self.view.bounds;
            lastUser = [self.participants lastObject];
            if ([lastUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            } else {
                [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.bigScalingType forUser:lastUser];
            }
            break;

        case UIDeviceOrientationPortraitUpsideDown:
//            NSLog(@"屏幕直立，上下顛倒");
            break;

        default:
//            NSLog(@"無法识别");
            break;
    }
    
    if (!self.smallCollectionView.hidden) {
        [self.smallCollectionView reloadData];
    }
    return YES;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_currentSession.state == kWFAVEngineStateConnected) {
        [self updateConnectedTimeLabel];
        [self startConnectedTimer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopConnectedTimer];
}

- (void)setPanStartPoint:(CGPoint)panStartPoint {
    _panStartPoint = panStartPoint;
    _panStartVideoFrame = self.smallCollectionView.frame;
}

- (void)moveToPanPoint:(CGPoint)panPoint {
    CGRect frame = self.panStartVideoFrame;
    CGSize moveSize = CGSizeMake(panPoint.x - self.panStartPoint.x, panPoint.y - self.panStartPoint.y);
    
    frame.origin.x += moveSize.width;
    frame.origin.y += moveSize.height;
    self.smallCollectionView.frame = frame;
}

- (void)onSmallVideoPan:(UIPanGestureRecognizer *)recognize {
    switch (recognize.state) {
        case UIGestureRecognizerStateBegan:
            self.panStartPoint = [recognize translationInView:self.view];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint currentPoint = [recognize translationInView:self.view];
            [self moveToPanPoint:currentPoint];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGPoint endPoint = [recognize translationInView:self.view];
            [self moveToPanPoint:endPoint];
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        default:
            break;
        }
}

- (void)videoButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession muteVideo:!self.currentSession.isVideoMuted];
        [self updateVideoButton];
    }
}

- (void)scalingButtonDidTap:(UIButton *)button {
//    if (self.currentSession.state != kWFAVEngineStateIdle) {
//        if (self.scalingType < kWFAVVideoScalingTypeAspectBalanced) {
//            self.scalingType++;
//        } else {
//            self.scalingType = kWFAVVideoScalingTypeAspectFit;
//        }
//
////        [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
////        [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType forUser:self.currentSession.participants[0]];
//    }
}


- (void)updateTopViewFrame {
        CGFloat containerWidth = self.view.bounds.size.width;
        
        self.portraitView.frame = CGRectMake((containerWidth-64)/2, kStatusBarAndNavigationBarHeight, 64, 64);;
        
        self.userNameLabel.frame = CGRectMake((containerWidth - 240)/2, kStatusBarAndNavigationBarHeight + 64 + 8, 240, 26);
        self.userNameLabel.textAlignment = NSTextAlignmentCenter;
        
        self.connectTimeLabel.frame = CGRectMake((containerWidth - 240)/2, self.smallCollectionView.frame.origin.y + self.smallCollectionView.frame.size.height + 8, 240, 16);
        self.connectTimeLabel.textAlignment = NSTextAlignmentCenter;
    
        self.stateLabel.frame = CGRectMake((containerWidth - 240)/2, self.smallCollectionView.frame.origin.y + self.smallCollectionView.frame.size.height + 30, 240, 16);
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)onClickedBigVideoView:(id)sender {
    if (self.currentSession.state != kWFAVEngineStateConnected) {
        return;
    }
    
    if (self.currentSession.audioOnly) {
        return;
    }
    
    if (self.bottomBarView.hidden) {
        [self showPanel];
    } else {
        [self hidePanel];
    }
}

- (void)showPanel {
    self.bottomBarView.hidden = NO;
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height - kTabbarSafeBottomMargin-BOTTOM_BAR_HEIGHT, self.view.bounds.size.width, BOTTOM_BAR_HEIGHT+kTabbarSafeBottomMargin);
    }];
    
    if (self.currentSession.audioOnly) {
        self.videoButton.hidden = YES;
    } else {
        self.videoButton.hidden = NO;
    }
    self.switchCameraButton.hidden = NO;
    self.smallCollectionView.hidden = NO;
    self.minimizeButton.hidden = NO;
    self.connectTimeLabel.hidden = NO;
    [self startHidePanelTimer];
}

- (void)hidePanel {
    [UIView animateWithDuration:0.5 animations:^{
        self.bottomBarView.frame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0);
    } completion:^(BOOL finished) {
        self.bottomBarView.hidden = YES;
    }];
    self.switchCameraButton.hidden = YES;
    self.minimizeButton.hidden = YES;
    self.connectTimeLabel.hidden = YES;
}

- (void)startHidePanelTimer {
    if(self.currentSession.isAudioOnly) {
        return;
    }
    
    [self.hidePanelTimer invalidate];
    __weak typeof(self)ws = self;
    if (@available(iOS 10.0, *)) {
        self.hidePanelTimer = [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
            [ws hidePanel];
        }];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark - WFAVEngineDelegate
- (void)didChangeState:(WFAVEngineState)state {
    if (!self.viewLoaded) {
        return;
    }
    switch (state) {
        case kWFAVEngineStateIdle:
            self.hangupButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            [self stopConnectedTimer];
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            self.stateLabel.text = WFCString(@"CallEnded");
            self.smallCollectionView.hidden = YES;
            self.portraitCollectionView.hidden = YES;
            self.bigVideoView.hidden = YES;
            self.minimizeButton.hidden = YES;
            self.speakerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            self.managerButton.hidden = YES;
            self.bottomBarView.hidden = YES;
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateOutgoing:
            self.connectTimeLabel.hidden = YES;
            self.hangupButton.hidden = NO;
            self.switchCameraButton.hidden = YES;
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = YES;
                [self updateSpeakerButton];
                self.audioButton.hidden = YES;
            } else {
                self.speakerButton.hidden = YES;
                self.audioButton.hidden = YES;
            }
            self.managerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            self.stateLabel.text = WFCString(@"WaitingAccept");
            self.smallCollectionView.hidden = YES;
            self.portraitCollectionView.hidden = NO;
            [self.portraitCollectionView reloadData];
            
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            [self updateTopViewFrame];
            
            break;
        case kWFAVEngineStateConnecting:
            self.hangupButton.hidden = NO;
            self.speakerButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            self.managerButton.hidden = YES;
            self.screenSharingButton.hidden = YES;
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            if (self.currentSession.audioOnly) {
                self.smallCollectionView.hidden = YES;
                self.portraitCollectionView.hidden = NO;
                [self.portraitCollectionView reloadData];
                
                self.portraitCollectionView.center = self.view.center;
            } else {
                self.smallCollectionView.hidden = NO;
                [self.smallCollectionView reloadData];
                self.portraitCollectionView.hidden = YES;
            }
            
            
            self.stateLabel.text = WFCString(@"CallConnecting");
            self.portraitView.hidden = YES;
            self.userNameLabel.hidden = YES;
            break;
        case kWFAVEngineStateConnected:
            self.hangupButton.hidden = NO;
            self.connectTimeLabel.hidden = NO;
            self.stateLabel.hidden = YES;
            self.managerButton.hidden = NO;
            self.screenSharingButton.hidden = NO;
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = NO;
                [self updateSpeakerButton];
                self.audioButton.hidden = NO;
                self.switchCameraButton.hidden = YES;
                self.videoButton.hidden = YES;
            } else {
                self.speakerButton.hidden = YES;
                self.audioButton.hidden = NO;
                self.switchCameraButton.hidden = NO;
                self.videoButton.hidden = NO;
            }
            [self updateAudioButton];
            [self updateVideoButton];
            
            self.scalingButton.hidden = YES;
            self.minimizeButton.hidden = NO;
            
            if (self.currentSession.isAudioOnly) {
                [self.currentSession setupLocalVideoView:nil scalingType:self.bigScalingType];
                self.smallCollectionView.hidden = YES;
                self.bigVideoView.hidden = YES;
                
                self.portraitCollectionView.hidden = NO;
                [self.portraitCollectionView reloadData];
            } else {
                NSString *lastUser = [self.participants lastObject];
                if ([lastUser isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                    [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
                } else {
                    [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.bigScalingType forUser:lastUser];
                }
                
                self.smallCollectionView.hidden = NO;
                [self.smallCollectionView reloadData];
                self.bigVideoView.hidden = NO;
                
                self.portraitCollectionView.hidden = YES;
            }
            
            self.userNameLabel.hidden = YES;
            self.portraitView.hidden = YES;
            [self updateConnectedTimeLabel];
            [self startConnectedTimer];
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateIncomming:
            self.connectTimeLabel.hidden = YES;
            self.hangupButton.hidden = NO;
            self.switchCameraButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
            self.stateLabel.text = WFCString(@"InvitingYou");
            self.smallCollectionView.hidden = YES;
            self.portraitCollectionView.hidden = NO;
            [self.portraitCollectionView reloadData];
            break;
        default:
            break;
    }
}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack fromUser:(NSString *)userId {
}

- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString *)userId {
    if ([self.participants.lastObject isEqualToString:userId]) {
        for (int i = 0; i < self.participants.count-1; i++) {
            NSString *pid = [self.participants objectAtIndex:i];
            if ([pid isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                if (!self.currentSession.myProfile.videoMuted) {
                    [self switchVideoView:i];
                    return;
                }
                continue;
            }
            for (WFAVParticipantProfile *p in self.currentSession.participants) {
                if ([p.userId isEqualToString:pid]) {
                    if (!p.videoMuted && p.state == kWFAVEngineStateConnected) {
                        [self switchVideoView:i];
                        return;
                    }
                    break;
                }
            }
        }
        [self reloadVideoUI];
    } else {
        [self reloadVideoUI];
    }
}
- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString *)userId {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wfavVolumeUpdated" object:userId userInfo:@{@"volume":@(volume)}];
    if (!self.currentSession.audioOnly && [userId isEqualToString:self.participants.lastObject]) {
        if (volume > 1000) {
            [self.bigVideoView bringSubviewToFront:self.speakingView];
            self.speakingView.hidden = NO;
        } else {
            self.speakingView.hidden = YES;
        }
    }
}
- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceEnded" object:nil];
    [self.view makeToast:@"会议已结束" duration:1 position:CSToastPositionCenter];
    if(reason == kWFAVCallEndReasonRoomNotExist) {
        [self restartConference];
    } else if(reason == kWFAVCallEndReasonRoomParticipantsFull) {
        [self rejoinConferenceAsAudience];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
        });
    }
}

- (void)didParticipantJoined:(NSString *)userId {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    
    if ([self.participants containsObject:userId] || [userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return;
    }
    [self rearrangeParticipants];
    [self reloadVideoUI];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    [self.view makeToast:[NSString stringWithFormat:@"%@ 加入了会议", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName] duration:1 position:CSToastPositionCenter];
}

- (void)didParticipantConnected:(NSString *)userId {
    [self reloadVideoUI];
}

- (void)didParticipantLeft:(NSString *)userId withReason:(WFAVCallEndReason)reason {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    
    [self rearrangeParticipants];
    [self reloadVideoUI];
    
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    NSString *reasonStr;
    if (reason == kWFAVCallEndReasonTimeout) {
        reasonStr = @"未接听";
    } else if(reason == kWFAVCallEndReasonBusy) {
        reasonStr = @"网络忙";
    } else if(reason == kWFAVCallEndReasonRemoteHangup) {
        reasonStr = @"离开会议";
    } else {
        reasonStr = @"离开会议"; //"网络错误";
    }
    
    [self.view makeToast:[NSString stringWithFormat:@"%@ %@", userInfo.displayName, reasonStr] duration:1 position:CSToastPositionCenter];
}

- (void)didChangeMode:(BOOL)isAudioOnly {
    [self didChangeState:self.currentSession.state];
}

- (void)didError:(NSError *)error {
    if([error.domain isEqualToString:@"room_participants_full"]) {
        [self.view makeToast:@"发言人数已满，无法切换到发言人!" duration:1 position:CSToastPositionCenter];
    }
}

- (void)didGetStats:(NSArray *)stats {
    
}

- (void)didChangeType:(BOOL)audience ofUser:(NSString *)userId {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMemberChanged" object:nil];
    [self rearrangeParticipants];
    [self reloadVideoUI];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    if(audience) {
        [self.view makeToast:[NSString stringWithFormat:@"%@ 结束了互动", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName] duration:1 position:CSToastPositionCenter];
    } else {
        [self.view makeToast:[NSString stringWithFormat:@"%@ 加入了互动", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName] duration:1 position:CSToastPositionCenter];
    }
    
    if([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        [self updateAudioButton];
        [self updateVideoButton];
    }
}

- (void)didChangeAudioRoute {
    [self updateSpeakerButton];
}

- (void)didChangeInitiator:(NSString * _Nullable)initiator { 
    NSLog(@"did change initiator");
}

- (void)didMuteStateChanged:(NSArray<NSString *> *_Nonnull)userIds {
    [self reloadVideoUI];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kConferenceMutedStateChanged" object:nil];
}

- (void)checkAVPermission {
    [self checkCapturePermission:nil];
    [self checkRecordPermission:nil];
}

- (void)checkCapturePermission:(void (^)(BOOL granted))complete {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted) {
        if (complete) {
            complete(NO);
        }
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice
         requestAccessForMediaType:AVMediaTypeVideo
         completionHandler:^(BOOL granted) {
             if (complete) {
                 complete(granted);
             }
         }];
    } else {
        if (complete) {
            complete(YES);
        }
    }
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

- (void)rejoinConferenceAsAudience {
    __weak typeof(self)ws = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"会议发言人数已满，是否以观众身份入会？" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [[WFAVEngineKit sharedEngineKit] dismissViewController:ws];
    }];
    [alertController addAction:action1];
    
    BOOL audioOnly = self.currentSession.isAudioOnly;
    NSString *title = self.currentSession.title;
    NSString *desc = self.currentSession.desc;
    NSString *conferenceId = self.currentSession.callId;
    NSString *pin = self.currentSession.pin;
    NSString *host = self.currentSession.host;
    BOOL advanced = self.currentSession.isAdvanced;
    
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[WFAVEngineKit sharedEngineKit] dismissViewController:ws];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:conferenceId audioOnly:audioOnly pin:pin host:host title:title desc:desc audience:YES advanced:advanced moCall:NO];
            [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
        });
    }];
    [alertController addAction:action2];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)restartConference {
    if([self.currentSession.host isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"会议未开始或者已经结束，请点击启动来开始会议" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [[WFAVEngineKit sharedEngineKit] dismissViewController:ws];
        }];
        [alertController addAction:action1];
        
        BOOL audioOnly = self.currentSession.isAudioOnly;
        BOOL defaultAudience = self.currentSession.defaultAudience;
        NSString *title = self.currentSession.title;
        NSString *desc = self.currentSession.desc;
        NSString *conferenceId = self.currentSession.callId;
        NSString *pin = self.currentSession.pin;
        BOOL advanced = self.currentSession.isAdvanced;
        
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"启动" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[WFAVEngineKit sharedEngineKit] dismissViewController:ws];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                WFCUConferenceViewController *vc = [[WFCUConferenceViewController alloc] initWithCallId:conferenceId audioOnly:audioOnly pin:pin host:[WFCCNetworkService sharedInstance].userId title:title desc:desc audience:defaultAudience advanced:advanced moCall:YES];
                [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
            });
        }];
        [alertController addAction:action2];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws presentViewController:alertController animated:YES completion:nil];
        });
    } else {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.host refresh:NO];
        
        __weak typeof(self)ws = self;
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"会议未开始或者已经结束，请联系 %@ 启动会议", userInfo.friendAlias.length ? userInfo.friendAlias : userInfo.displayName] preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [[WFAVEngineKit sharedEngineKit] dismissViewController:ws];
        }];
        [alertController addAction:action1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ws presentViewController:alertController animated:YES completion:nil];
        });
    }
}
- (void)reloadVideoUI {
    if (!self.currentSession.audioOnly) {
        if (self.currentSession.state == kWFAVEngineStateConnecting || self.currentSession.state == kWFAVEngineStateConnected) {
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            CGFloat itemWidth = (self.view.frame.size.width + layout.minimumLineSpacing)/3 - layout.minimumLineSpacing;
            
            int lines = (int)([self.currentSession participantIds].count + 2) /3;
            
            self.smallCollectionView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, self.view.frame.size.width, (itemWidth + layout.minimumLineSpacing)*lines - layout.minimumLineSpacing);
            
            _speakingView.hidden = YES;
            NSString *userId = [self.participants lastObject];
            if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                if (self.currentSession.myProfile.videoMuted) {
                    [self.currentSession setupLocalVideoView:nil scalingType:self.bigScalingType];
                    self.stateLabel.text = WFCString(@"VideoClosed");
                    self.stateLabel.hidden = NO;
                } else {
                    [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.bigScalingType];
                    self.stateLabel.text = nil;
                    self.stateLabel.hidden = YES;
                }
            } else {
                for (WFAVParticipantProfile *profile in self.currentSession.participants) {
                    if ([profile.userId isEqualToString:userId]) {
                        if (profile.videoMuted) {
                            [self.currentSession setupRemoteVideoView:nil scalingType:self.bigScalingType forUser:userId];
                            self.stateLabel.text = WFCString(@"VideoClosed");
                            self.stateLabel.hidden = NO;
                        } else {
                            [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.bigScalingType forUser:userId];
                            self.stateLabel.text = nil;
                            self.stateLabel.hidden = YES;
                        }
                        break;
                    }
                }
            }
            WFCCUserInfo *focusUser = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
            [self.bigVideoPortraitView sd_setImageWithURL:[NSURL URLWithString:focusUser.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
            [self.smallCollectionView reloadData];
        } else {
            [self.portraitCollectionView reloadData];
        }
    } else {
        [self.portraitCollectionView reloadData];
    }
}

- (BOOL)switchVideoView:(NSUInteger)index {
    NSString *userId = self.participants[index];
    
    BOOL canSwitch = NO;
    for (WFAVParticipantProfile *profile in self.currentSession.participants) {
        if ([profile.userId isEqualToString:userId]) {
            if (profile.state == kWFAVEngineStateConnected) {
                canSwitch = YES;
            }
            break;
        }
    }
    
    if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        if (self.currentSession.state == kWFAVEngineStateConnected) {
            canSwitch = YES;
        }
    }
    
    if (canSwitch) {
        NSString *lastId = [self.participants lastObject];
        [self.participants removeLastObject];
        [self.participants insertObject:lastId atIndex:index];
        [self.participants removeObject:userId];
        [self.participants addObject:userId];
    }
    [self reloadVideoUI];
    
    return canSwitch;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.portraitCollectionView) {
        if (self.currentSession.audioOnly && (self.currentSession.state == kWFAVEngineStateConnecting || self.currentSession.state == kWFAVEngineStateConnected)) {
            return self.participants.count;
        }
    }
    return self.participants.count - 1;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *userId = self.participants[indexPath.row];
    if (collectionView == self.smallCollectionView) {
        WFCUParticipantCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
        
        
        UIDevice *device = [UIDevice currentDevice] ;
        if (device.orientation == UIDeviceOrientationLandscapeLeft) {
            cell.transform = CGAffineTransformMakeRotation(M_PI_2);
        } else if (device.orientation == UIDeviceOrientationLandscapeRight) {
            cell.transform = CGAffineTransformMakeRotation(-M_PI_2);
        } else {
            cell.transform = CGAffineTransformMakeRotation(0);
        }
        
        
        if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            WFAVParticipantProfile *profile = self.currentSession.myProfile;
            [cell setUserInfo:userInfo callProfile:profile];
            if (profile.videoMuted) {
                [self.currentSession setupLocalVideoView:nil scalingType:self.smallScalingType];
            } else {
                [self.currentSession setupLocalVideoView:cell scalingType:self.smallScalingType];
            }
        } else {
            for (WFAVParticipantProfile *profile in self.currentSession.participants) {
                if ([profile.userId isEqualToString:userId]) {
                    [cell setUserInfo:userInfo callProfile:profile];
                    if (profile.videoMuted) {
                        [self.currentSession setupRemoteVideoView:nil scalingType:self.smallScalingType forUser:userId];
                    } else {
                        [self.currentSession setupRemoteVideoView:cell scalingType:self.smallScalingType forUser:userId];
                    }
                    break;
                }
            }
        }

        return cell;
    } else {
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
    
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.smallCollectionView) {
        [self switchVideoView:indexPath.row];
    }
}

#endif
#pragma mark - WFCUConferenceManagerDelegate
-(void)onChangeModeRequest:(BOOL)isAudience {
    if(isAudience) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:@"主持人邀请您参与互动" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"忽略" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            
        }];
        [alertController addAction:action1];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
        }];
        [alertController addAction:action2];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end
