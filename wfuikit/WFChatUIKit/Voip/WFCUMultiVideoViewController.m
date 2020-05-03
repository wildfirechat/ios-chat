//
//  ViewController.m
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import "WFCUMultiVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#if WFCU_SUPPORT_VOIP
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUFloatingWindow.h"
#import "WFCUParticipantCollectionViewCell.h"
#endif
#import "SDWebImage.h"
#import <WFChatClient/WFCCConversation.h>
#import "WFCUPortraitCollectionViewCell.h"
#import "WFCUParticipantCollectionViewLayout.h"
#import "WFCUSeletedUserViewController.h"
#import "UIView+Toast.h"

@interface WFCUMultiVideoViewController () <UITextFieldDelegate
#if WFCU_SUPPORT_VOIP
    ,WFAVCallSessionDelegate
#endif
    ,UICollectionViewDataSource
    ,UICollectionViewDelegate
>
#if WFCU_SUPPORT_VOIP
@property (nonatomic, strong) UIView *bigVideoView;
@property (nonatomic, strong) UICollectionView *smallCollectionView;

@property (nonatomic, strong) UICollectionView *portraitCollectionView;
@property (nonatomic, strong) UIButton *hangupButton;
@property (nonatomic, strong) UIButton *answerButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *speakerButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *scalingButton;

@property (nonatomic, strong) UIButton *minimizeButton;
@property (nonatomic, strong) UIButton *addParticipantButton;

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

//视频时，大屏用户正在说话
@property (nonatomic, strong)UIImageView *speakingView;
#endif
@end

#define ButtonSize 60
#define BottomPadding 36
#define SmallVideoView 120
#define OperationTitleFont 10
#define OperationButtonSize 50

#define PortraitItemSize 48
#define PortraitLabelSize 16

@implementation WFCUMultiVideoViewController
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
        [self didChangeState:kWFAVEngineStateIncomming];
        [self rearrangeParticipants];
    }
    return self;
}

- (instancetype)initWithTargets:(NSArray<NSString *> *)targetIds conversation:(WFCCConversation *)conversation audioOnly:(BOOL)audioOnly {
    self = [super init];
    if (self) {
        WFAVCallSession *session = [[WFAVEngineKit sharedEngineKit] startCall:targetIds
                                                                    audioOnly:audioOnly
                                                                 conversation:conversation
                                                              sessionDelegate:self];
        self.currentSession = session;
        [self rearrangeParticipants];
    }
    return self;
}

/*
 session的participantIds是除了自己外的所有成员。这里把自己也加入列表，然后把发起者放到最后面。
 */
- (void)rearrangeParticipants {
    self.participants = [[NSMutableArray alloc] init];
    [self.participants addObjectsFromArray:self.currentSession.participantIds];
    if ([self.currentSession.initiator isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        [self.participants addObject:[WFCCNetworkService sharedInstance].userId];
    } else {
        [self.participants insertObject:[WFCCNetworkService sharedInstance].userId atIndex:[self.participants indexOfObject:self.currentSession.initiator]];
        [self.participants removeObject:self.currentSession.initiator];
        [self.participants addObject:self.currentSession.initiator];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.smallScalingType = kWFAVVideoScalingTypeAspectFill;
    self.bigScalingType = kWFAVVideoScalingTypeAspectBalanced;
    self.bigVideoView = [[UIView alloc] initWithFrame:self.view.bounds];
    UITapGestureRecognizer *tapBigVideo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickedBigVideoView:)];
    [self.bigVideoView addGestureRecognizer:tapBigVideo];
    [self.view addSubview:self.bigVideoView];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWidth = (self.view.frame.size.width + layout.minimumLineSpacing)/3 - layout.minimumLineSpacing;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.smallCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, kStatusBarAndNavigationBarHeight, self.view.frame.size.width, itemWidth) collectionViewLayout:layout];
    
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
    
    [self didChangeState:self.currentSession.state];//update ui
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [self onDeviceOrientationDidChange];

}

- (UIButton *)hangupButton {
    if (!_hangupButton) {
        _hangupButton = [[UIButton alloc] init];
        [_hangupButton setImage:[UIImage imageNamed:@"hangup"] forState:UIControlStateNormal];
        [_hangupButton setImage:[UIImage imageNamed:@"hangup_hover"] forState:UIControlStateHighlighted];
        [_hangupButton setImage:[UIImage imageNamed:@"hangup_hover"] forState:UIControlStateSelected];
        _hangupButton.backgroundColor = [UIColor clearColor];
        [_hangupButton addTarget:self action:@selector(hanupButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _hangupButton.hidden = YES;
        [self.view addSubview:_hangupButton];
    }
    return _hangupButton;
}

- (UIButton *)answerButton {
    if (!_answerButton) {
        _answerButton = [[UIButton alloc] init];
        
        [_answerButton setImage:[UIImage imageNamed:@"answer"] forState:UIControlStateNormal];
        [_answerButton setImage:[UIImage imageNamed:@"answer_hover"] forState:UIControlStateHighlighted];
        [_answerButton setImage:[UIImage imageNamed:@"answer_hover"] forState:UIControlStateSelected];
        
        _answerButton.backgroundColor = [UIColor clearColor];
        [_answerButton addTarget:self action:@selector(answerButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _answerButton.hidden = YES;
        [self.view addSubview:_answerButton];
    }
    return _answerButton;
}

- (UIButton *)minimizeButton {
    if (!_minimizeButton) {
        _minimizeButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 26, 30, 30)];
        
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

- (UIButton *)addParticipantButton {
    if (!_addParticipantButton) {
        _addParticipantButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 16 - 30, 26, 30, 30)];
        
        [_addParticipantButton setImage:[UIImage imageNamed:@"plus-circle"] forState:UIControlStateNormal];
        [_addParticipantButton setImage:[UIImage imageNamed:@"plus-circle"] forState:UIControlStateHighlighted];
        [_addParticipantButton setImage:[UIImage imageNamed:@"plus-circle"] forState:UIControlStateSelected];
        
        _addParticipantButton.backgroundColor = [UIColor clearColor];
        [_addParticipantButton addTarget:self action:@selector(addParticipantButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _addParticipantButton.hidden = YES;
        [self.view addSubview:_addParticipantButton];
    }
    return _addParticipantButton;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [[UIButton alloc] init];
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

- (UIButton *)audioButton {
    if (!_audioButton) {
        _audioButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_audioButton setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal];
        [_audioButton setImage:[UIImage imageNamed:@"mute_hover"] forState:UIControlStateHighlighted];
        [_audioButton setImage:[UIImage imageNamed:@"mute_hover"] forState:UIControlStateSelected];
        _audioButton.backgroundColor = [UIColor clearColor];
        [_audioButton addTarget:self action:@selector(audioButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _audioButton.hidden = YES;
        [self updateAudioButton];
        [self.view addSubview:_audioButton];
    }
    return _audioButton;
}
- (UIButton *)speakerButton {
    if (!_speakerButton) {
        _speakerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_speakerButton setImage:[UIImage imageNamed:@"speaker"] forState:UIControlStateNormal];
        [_speakerButton setImage:[UIImage imageNamed:@"speaker_hover"] forState:UIControlStateHighlighted];
        [_speakerButton setImage:[UIImage imageNamed:@"speaker_hover"] forState:UIControlStateSelected];
        _speakerButton.backgroundColor = [UIColor clearColor];
        [_speakerButton addTarget:self action:@selector(speakerButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _speakerButton.hidden = YES;
        [self.view addSubview:_speakerButton];
    }
    return _speakerButton;
}

- (UIButton *)videoButton {
    if (!_videoButton) {
        _videoButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width*3/4-ButtonSize/4, self.view.frame.size.height-45-ButtonSize-ButtonSize/2-2, ButtonSize/2, ButtonSize/2)];
        
        [_videoButton setImage:[UIImage imageNamed:@"enable_video"] forState:UIControlStateNormal];
        _videoButton.backgroundColor = [UIColor clearColor];
        [_videoButton addTarget:self action:@selector(videoButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _videoButton.hidden = YES;
        [self updateVideoButton];
        [self.view addSubview:_videoButton];
    }
    return _videoButton;
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
    if (userId) {
        [self.participants removeObject:userId];
        [self.participants addObject:userId];
        [self reloadVideoUI];
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
    if(self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession endCall];
    }
}

- (void)answerButtonDidTap:(UIButton *)button {
    if (self.currentSession.state == kWFAVEngineStateIncomming) {
        [self.currentSession answerCall:NO];
    }
}

- (void)minimizeButtonDidTap:(UIButton *)button {
    __block NSString *focusUser = [self.participants lastObject];
    [WFCUFloatingWindow startCallFloatingWindow:self.currentSession focusUser:focusUser withTouchedBlock:^(WFAVCallSession *callSession) {
        WFCUMultiVideoViewController *vc = [[WFCUMultiVideoViewController alloc] initWithSession:callSession];
        [vc setFocusUser:focusUser];
         [[WFAVEngineKit sharedEngineKit] presentViewController:vc];
     }];
    
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)addParticipantButtonDidTap:(UIButton *)button {
    WFCUSeletedUserViewController *pvc = [[WFCUSeletedUserViewController alloc] init];
    
    NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
    [disabledUser addObjectsFromArray:self.participants];
    pvc.disableUserIds = disabledUser;
    
    pvc.maxSelectCount = self.currentSession.audioOnly ? [WFAVEngineKit sharedEngineKit].maxAudioCallCount : [WFAVEngineKit sharedEngineKit].maxVideoCallCount;
    pvc.groupId = self.currentSession.conversation.target;
    
    NSMutableArray *candidateUser = [[NSMutableArray alloc] init];
    NSArray<WFCCGroupMember *> *members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.currentSession.conversation.target forceUpdate:NO];
    for (WFCCGroupMember *member in members) {
      [candidateUser addObject:member.memberId];
    }
    pvc.candidateUsers = candidateUser;
    pvc.type = Vertical;
    
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        if (contacts.count) {
            [ws.currentSession inviteNewParticipants:contacts];
        }
    };
        
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    navi.modalPresentationStyle = UIModalPresentationFullScreen;
    dispatch_async(dispatch_get_main_queue(), ^{
        [ws presentViewController:navi animated:YES completion:nil];
    });
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
        [self.audioButton setImage:[UIImage imageNamed:@"mute_hover"] forState:UIControlStateNormal];
    } else {
        [self.audioButton setImage:[UIImage imageNamed:@"mute"] forState:UIControlStateNormal];
    }
}
- (void)speakerButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession enableSpeaker:!self.currentSession.isSpeaker];
        [self updateSpeakerButton];
    }
}

- (void)updateSpeakerButton {
    if (!self.currentSession.isSpeaker) {
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker"] forState:UIControlStateNormal];
    } else {
        [self.speakerButton setImage:[UIImage imageNamed:@"speaker_hover"] forState:UIControlStateNormal];
    }
}

- (void)updateVideoButton {
    if (self.currentSession.videoMuted) {
        [self.videoButton setImage:[UIImage imageNamed:@"disable_video"] forState:UIControlStateNormal];
    } else {
        [self.videoButton setImage:[UIImage imageNamed:@"enable_video"] forState:UIControlStateNormal];
    }
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

    switch (device.orientation) {
        case UIDeviceOrientationFaceUp:
            NSLog(@"屏幕幕朝上平躺");
            break;

        case UIDeviceOrientationFaceDown:
            NSLog(@"屏幕朝下平躺");
            break;

        case UIDeviceOrientationUnknown:
            //系统当前无法识别设备朝向，可能是倾斜
            NSLog(@"未知方向");
            break;

        case UIDeviceOrientationLandscapeLeft:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(M_PI_2);
            NSLog(@"屏幕向左橫置");
            break;

        case UIDeviceOrientationLandscapeRight:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            NSLog(@"屏幕向右橫置");
            break;

        case UIDeviceOrientationPortrait:
            self.bigVideoView.transform = CGAffineTransformMakeRotation(0);
            NSLog(@"屏幕直立");
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"屏幕直立，上下顛倒");
            break;

        default:
            NSLog(@"無法识别");
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

- (CGRect)getButtomCenterButtonFrame {
    return CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-BottomPadding-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getButtomLeftButtonFrame {
    return CGRectMake(self.view.frame.size.width/4-ButtonSize/2, self.view.frame.size.height-BottomPadding-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getButtomRightButtonFrame {
    return CGRectMake(self.view.frame.size.width*3/4-ButtonSize/2, self.view.frame.size.height-BottomPadding-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getToAudioButtonFrame {
    return CGRectMake(self.view.frame.size.width*3/4-ButtonSize/2, self.view.frame.size.height-BottomPadding-ButtonSize-ButtonSize-2, ButtonSize, ButtonSize);
}

- (void)updateTopViewFrame {
//    if (self.currentSession.isAudioOnly) {
        CGFloat containerWidth = self.view.bounds.size.width;
        
        self.portraitView.frame = CGRectMake((containerWidth-64)/2, kStatusBarAndNavigationBarHeight, 64, 64);;
        
        self.userNameLabel.frame = CGRectMake((containerWidth - 240)/2, kStatusBarAndNavigationBarHeight + 64 + 8, 240, 26);
        self.userNameLabel.textAlignment = NSTextAlignmentCenter;
        
        self.connectTimeLabel.frame = CGRectMake((containerWidth - 240)/2, self.smallCollectionView.frame.origin.y + self.smallCollectionView.frame.size.height + 8, 240, 16);
        self.connectTimeLabel.textAlignment = NSTextAlignmentCenter;
    
        self.stateLabel.frame = CGRectMake((containerWidth - 240)/2, self.smallCollectionView.frame.origin.y + self.smallCollectionView.frame.size.height + 30, 240, 16);
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
//    } else {
//        self.portraitView.frame = CGRectMake(16, kStatusBarAndNavigationBarHeight, 64, 64);
//        self.userNameLabel.frame = CGRectMake(96, kStatusBarAndNavigationBarHeight + 8, 240, 26);
//        if(![NSThread isMainThread]) {
//            NSLog(@"error not main thread");
//        }
//        self.userNameLabel.textAlignment = NSTextAlignmentLeft;
//        if(self.currentSession.state == kWFAVEngineStateConnected) {
//            self.stateLabel.frame = CGRectMake(54, 30, 240, 20);
//        } else {
//            self.stateLabel.frame = CGRectMake(96, kStatusBarAndNavigationBarHeight + 26 + 14, 240, 16);
//        }
//        self.stateLabel.textAlignment = NSTextAlignmentLeft;
//    }
}

- (void)onClickedBigVideoView:(id)sender {
    if (self.currentSession.state != kWFAVEngineStateConnected) {
        return;
    }
    
    if (self.currentSession.audioOnly) {
        return;
    }
    
    if (self.smallCollectionView.hidden) {
        if (self.hangupButton.hidden) {
            self.hangupButton.hidden = NO;
            self.audioButton.hidden = NO;
            if (self.currentSession.audioOnly) {
                self.videoButton.hidden = YES;
            } else {
                self.videoButton.hidden = NO;
            }
            self.switchCameraButton.hidden = NO;
            self.smallCollectionView.hidden = NO;
            self.minimizeButton.hidden = NO;
            self.addParticipantButton.hidden = NO;
        } else {
            self.hangupButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
            self.minimizeButton.hidden = YES;
            self.addParticipantButton.hidden = YES;
        }
    } else {
        self.smallCollectionView.hidden = YES;
    }
}

#pragma mark - WFAVEngineDelegate
- (void)didChangeState:(WFAVEngineState)state {
    if (!self.viewLoaded) {
        return;
    }
    switch (state) {
        case kWFAVEngineStateIdle:
            self.answerButton.hidden = YES;
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
            self.addParticipantButton.hidden = YES;
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateOutgoing:
            self.answerButton.hidden = YES;
            self.connectTimeLabel.hidden = YES;
            self.hangupButton.hidden = NO;
            self.hangupButton.frame = [self getButtomCenterButtonFrame];
            self.switchCameraButton.hidden = YES;
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = YES;
                [self updateSpeakerButton];
                self.speakerButton.frame = [self getButtomRightButtonFrame];
                self.audioButton.hidden = YES;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
            } else {
                self.speakerButton.hidden = YES;
                self.audioButton.hidden = YES;
            }
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
            self.answerButton.hidden = YES;
            self.hangupButton.hidden = NO;
            self.speakerButton.hidden = YES;
            self.hangupButton.frame = [self getButtomCenterButtonFrame];
            self.switchCameraButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
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
            self.answerButton.hidden = YES;
            self.hangupButton.hidden = NO;
            self.connectTimeLabel.hidden = NO;
            self.stateLabel.hidden = YES;
            self.hangupButton.frame = [self getButtomCenterButtonFrame];
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = NO;
                self.speakerButton.frame = [self getButtomRightButtonFrame];
                [self updateSpeakerButton];
                self.audioButton.hidden = NO;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
                self.switchCameraButton.hidden = YES;
                self.videoButton.hidden = YES;
            } else {
                self.speakerButton.hidden = YES;
                [self.currentSession enableSpeaker:YES];
                self.audioButton.hidden = NO;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
                self.switchCameraButton.hidden = NO;
                self.switchCameraButton.frame = [self getButtomRightButtonFrame];
                self.videoButton.hidden = NO;
            }
            
            self.scalingButton.hidden = YES;
            self.minimizeButton.hidden = NO;
            self.addParticipantButton.hidden = NO;
            
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
            
            
//            if (!_currentSession.isAudioOnly) {
                self.userNameLabel.hidden = YES;
                self.portraitView.hidden = YES;
//            } else {
//                self.userNameLabel.hidden = NO;
//                self.portraitView.hidden = NO;
//            }
            [self updateConnectedTimeLabel];
            [self startConnectedTimer];
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateIncomming:
            self.connectTimeLabel.hidden = YES;
            self.answerButton.hidden = NO;
            self.answerButton.frame = [self getButtomRightButtonFrame];
            self.hangupButton.hidden = NO;
            self.hangupButton.frame = [self getButtomLeftButtonFrame];
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
    NSLog(@"user %@ report volume %ld", userId, volume);
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
    });
}

- (void)didParticipantJoined:(NSString *)userId {
    if ([self.participants containsObject:userId] || [userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        return;
    }
    [self.participants insertObject:userId atIndex:0];
    [self reloadVideoUI];
}

- (void)didParticipantConnected:(NSString *)userId {
    [self reloadVideoUI];
}

- (void)didParticipantLeft:(NSString *)userId withReason:(WFAVCallEndReason)reason {
    [self.participants removeObject:userId];
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
    
}

- (void)didGetStats:(NSArray *)stats {
    
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
- (void)reloadVideoUI {
    if (!self.currentSession.audioOnly) {
        if (self.currentSession.state == kWFAVEngineStateConnecting || self.currentSession.state == kWFAVEngineStateConnected) {
            UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
            CGFloat itemWidth = (self.view.frame.size.width + layout.minimumLineSpacing)/3 - layout.minimumLineSpacing;
            
            if (self.participants.count - 1 > 3) {
                self.smallCollectionView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, self.view.frame.size.width, itemWidth * 2 + layout.minimumLineSpacing);
            } else {
                self.smallCollectionView.frame = CGRectMake(0, kStatusBarAndNavigationBarHeight, self.view.frame.size.width, itemWidth);
            }
            
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
@end
