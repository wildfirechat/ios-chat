//
//  ViewController.m
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//


#import "WFCUVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#if WFCU_SUPPORT_VOIP
#import <WebRTC/WebRTC.h>
#import <WFAVEngineKit/WFAVEngineKit.h>
#import "WFCUFloatingWindow.h"
#endif
#import "SDWebImage.h"
#import <WFChatClient/WFCCConversation.h>


@interface WFCUVideoViewController () <UITextFieldDelegate
#if WFCU_SUPPORT_VOIP
    ,WFAVCallSessionDelegate
#endif
>
#if WFCU_SUPPORT_VOIP
@property (nonatomic, strong) UIView *bigVideoView;
@property (nonatomic, strong) UIView *smallVideoView;
@property (nonatomic, strong) UIButton *hangupButton;
@property (nonatomic, strong) UIButton *answerButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *audioButton;
@property (nonatomic, strong) UIButton *speakerButton;
@property (nonatomic, strong) UIButton *downgradeButton;
@property (nonatomic, strong) UIButton *videoButton;
@property (nonatomic, strong) UIButton *scalingButton;

@property (nonatomic, strong) UIButton *minimizeButton;

@property (nonatomic, strong) UIImageView *portraitView;
@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, assign) BOOL audioMuted;
@property (nonatomic, assign) BOOL videoMuted;

@property (nonatomic, strong) WFAVCallSession *currentSession;
@property (nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) RTCVideoTrack *remoteVideoTrack;

@property (nonatomic, assign) WFAVVideoScalingType scalingType;

@property (nonatomic, assign) CGPoint panStartPoint;
@property (nonatomic, assign) CGRect panStartVideoFrame;
@property (nonatomic, strong) NSTimer *connectedTimer;
#endif
@end

#define ButtonSize 90
#define SmallVideoView 120

#if !WFCU_SUPPORT_VOIP
@interface WFAVCallSession : NSObject
@end

@implementation WFAVCallSession
@end
#endif

@implementation WFCUVideoViewController
#if !WFCU_SUPPORT_VOIP
- (instancetype)initWithSession:(WFAVCallSession *)session {
    self = [super init];
    return self;
}

- (instancetype)initWithTarget:(NSString *)targetId conversation:(WFCCConversation *)conversation audioOnly:(BOOL)audioOnly {
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
        self.audioMuted = NO;
        self.videoMuted = NO;
    }
    return self;
}

- (instancetype)initWithTarget:(NSString *)targetId conversation:(WFCCConversation *)conversation audioOnly:(BOOL)audioOnly {
    self = [super init];
    if (self) {
        WFAVCallSession *session = [[WFAVEngineKit sharedEngineKit] startCall:targetId
                                                                    audioOnly:audioOnly
                                                                 conversation:conversation
                                                              sessionDelegate:self];
        self.currentSession = session;
        self.audioMuted = NO;
        self.videoMuted = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.scalingType = kWFAVVideoScalingTypeAspectBalanced;
    self.bigVideoView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.bigVideoView];
    
    self.smallVideoView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SmallVideoView, kStatusBarAndNavigationBarHeight, SmallVideoView, SmallVideoView * 4 /3)];
    [self.smallVideoView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoPan:)]];
    [self.view addSubview:self.smallVideoView];
    
    [self checkAVPermission];
    
    if(self.currentSession.state == kWFAVEngineStateOutgoing && !self.currentSession.isAudioOnly) {
        [[WFAVEngineKit sharedEngineKit] startPreview];
    }
    
    WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.clientId inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    self.portraitView = [[UIImageView alloc] init];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:user.portrait] placeholderImage:[UIImage wf_imageNamed:@"PersonalChat"]];
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
    
    [self updateTopViewFrame];
    
    [self didChangeState:self.currentSession.state];//update ui
}

- (UIButton *)hangupButton {
    if (!_hangupButton) {
        _hangupButton = [[UIButton alloc] init];
        [_hangupButton setImage:[UIImage wf_imageNamed:@"hangup"] forState:UIControlStateNormal];
        [_hangupButton setImage:[UIImage wf_imageNamed:@"hangup_hover"] forState:UIControlStateHighlighted];
        [_hangupButton setImage:[UIImage wf_imageNamed:@"hangup_hover"] forState:UIControlStateSelected];
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
        
        [_answerButton setImage:[UIImage wf_imageNamed:@"answer"] forState:UIControlStateNormal];
        [_answerButton setImage:[UIImage wf_imageNamed:@"answer_hover"] forState:UIControlStateHighlighted];
        [_answerButton setImage:[UIImage wf_imageNamed:@"answer_hover"] forState:UIControlStateSelected];
        
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
        
        [_minimizeButton setImage:[UIImage wf_imageNamed:@"minimize"] forState:UIControlStateNormal];
        [_minimizeButton setImage:[UIImage wf_imageNamed:@"minimize_hover"] forState:UIControlStateHighlighted];
        [_minimizeButton setImage:[UIImage wf_imageNamed:@"minimize_hover"] forState:UIControlStateSelected];
        
        _minimizeButton.backgroundColor = [UIColor clearColor];
        [_minimizeButton addTarget:self action:@selector(minimizeButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _minimizeButton.hidden = YES;
        [self.view addSubview:_minimizeButton];
    }
    return _minimizeButton;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [[UIButton alloc] init];
        [_switchCameraButton setImage:[UIImage wf_imageNamed:@"switchcamera"] forState:UIControlStateNormal];
        [_switchCameraButton setImage:[UIImage wf_imageNamed:@"switchcamera_hover"] forState:UIControlStateHighlighted];
        [_switchCameraButton setImage:[UIImage wf_imageNamed:@"switchcamera_hover"] forState:UIControlStateSelected];
        _switchCameraButton.backgroundColor = [UIColor clearColor];
        [_switchCameraButton addTarget:self action:@selector(switchCameraButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _switchCameraButton.hidden = YES;
        [self.view addSubview:_switchCameraButton];
    }
    return _switchCameraButton;
}

- (UIButton *)downgradeButton {
    if (!_downgradeButton) {
        _downgradeButton = [[UIButton alloc] init];
        [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio"] forState:UIControlStateNormal];
        [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio_hover"] forState:UIControlStateHighlighted];
        [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio_hover"] forState:UIControlStateSelected];
        _downgradeButton.backgroundColor = [UIColor clearColor];
        [_downgradeButton addTarget:self action:@selector(downgradeButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _downgradeButton.hidden = YES;
        [self.view addSubview:_downgradeButton];
    }
    return _downgradeButton;
}

- (UIButton *)audioButton {
    if (!_audioButton) {
        _audioButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_audioButton setImage:[UIImage wf_imageNamed:@"mute"] forState:UIControlStateNormal];
        [_audioButton setImage:[UIImage wf_imageNamed:@"mute_hover"] forState:UIControlStateHighlighted];
        [_audioButton setImage:[UIImage wf_imageNamed:@"mute_hover"] forState:UIControlStateSelected];
        _audioButton.backgroundColor = [UIColor clearColor];
        [_audioButton addTarget:self action:@selector(audioButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _audioButton.hidden = YES;
        [self.view addSubview:_audioButton];
    }
    return _audioButton;
}
- (UIButton *)speakerButton {
    if (!_speakerButton) {
        _speakerButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_speakerButton setImage:[UIImage wf_imageNamed:@"speaker"] forState:UIControlStateNormal];
        [_speakerButton setImage:[UIImage wf_imageNamed:@"speaker_hover"] forState:UIControlStateHighlighted];
        [_speakerButton setImage:[UIImage wf_imageNamed:@"speaker_hover"] forState:UIControlStateSelected];
        _speakerButton.backgroundColor = [UIColor clearColor];
        [_speakerButton addTarget:self action:@selector(speakerButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _speakerButton.hidden = YES;
        [self.view addSubview:_speakerButton];
    }
    return _speakerButton;
}

- (UIButton *)videoButton {
    if (!_videoButton) {
        _videoButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_videoButton setTitle:@"视频" forState:UIControlStateNormal];
        _videoButton.backgroundColor = [UIColor greenColor];
        [_videoButton addTarget:self action:@selector(videoButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _videoButton.hidden = YES;
        [self.view addSubview:_videoButton];
    }
    return _videoButton;
}

- (UIButton *)scalingButton {
    if (!_scalingButton) {
        _scalingButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_scalingButton setTitle:@"缩放" forState:UIControlStateNormal];
        _scalingButton.backgroundColor = [UIColor greenColor];
        [_scalingButton addTarget:self action:@selector(scalingButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _scalingButton.hidden = YES;
        [self.view addSubview:_scalingButton];
    }
    return _scalingButton;
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

- (void)updateConnectedTimeLabel {
    long sec = [[NSDate date] timeIntervalSince1970] - self.currentSession.connectedTime / 1000;
    if (sec < 60 * 60) {
        self.stateLabel.text = [NSString stringWithFormat:@"%02ld:%02ld", sec / 60, sec % 60];
    } else {
        self.stateLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", sec / 60 / 60, (sec / 60) % 60, sec % 60];
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
    [WFCUFloatingWindow startCallFloatingWindow:self.currentSession withTouchedBlock:^(WFAVCallSession *callSession) {
         [[WFAVEngineKit sharedEngineKit] presentViewController:[[WFCUVideoViewController alloc] initWithSession:callSession]];
     }];
    
    [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
}

- (void)switchCameraButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession switchCamera];
    }
}

- (void)downgradeButtonDidTap:(UIButton *)button {
    if (self.currentSession.state == kWFAVEngineStateIncomming) {
        [self.currentSession answerCall:YES];
    } else if(self.currentSession.state == kWFAVEngineStateConnected) {
        self.currentSession.audioOnly = !self.currentSession.isAudioOnly;
    }
}


- (void)audioButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        BOOL result = [self.currentSession muteAudio:!self.audioMuted];
        if (result) {
            self.audioMuted = !self.audioMuted;
            if (self.audioMuted) {
                [self.audioButton setImage:[UIImage wf_imageNamed:@"mute_hover"] forState:UIControlStateNormal];
            } else {
                [self.audioButton setImage:[UIImage wf_imageNamed:@"mute"] forState:UIControlStateNormal];
            }
            
        }
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
        [self.speakerButton setImage:[UIImage wf_imageNamed:@"speaker"] forState:UIControlStateNormal];
    } else {
        [self.speakerButton setImage:[UIImage wf_imageNamed:@"speaker_hover"] forState:UIControlStateNormal];
    }
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
    _panStartVideoFrame = self.smallVideoView.frame;
}

- (void)moveToPanPoint:(CGPoint)panPoint {
    CGRect frame = self.panStartVideoFrame;
    CGSize moveSize = CGSizeMake(panPoint.x - self.panStartPoint.x, panPoint.y - self.panStartPoint.y);
    
    frame.origin.x += moveSize.width;
    frame.origin.y += moveSize.height;
    self.smallVideoView.frame = frame;
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
        BOOL result = [self.currentSession muteVideo:!self.videoMuted];
        if (result) {
            self.videoMuted = !self.videoMuted;
        }
    }
}

- (void)scalingButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        if (self.scalingType < kWFAVVideoScalingTypeAspectBalanced) {
            self.scalingType++;
        } else {
            self.scalingType = kWFAVVideoScalingTypeAspectFit;
        }
        
        [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
        [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType];
    }
}

- (CGRect)getButtomCenterButtonFrame {
    return CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-45-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getButtomLeftButtonFrame {
    return CGRectMake(self.view.frame.size.width/4-ButtonSize/2, self.view.frame.size.height-45-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getButtomRightButtonFrame {
    return CGRectMake(self.view.frame.size.width*3/4-ButtonSize/2, self.view.frame.size.height-45-ButtonSize, ButtonSize, ButtonSize);
}

- (CGRect)getToAudioButtonFrame {
    return CGRectMake(self.view.frame.size.width*3/4-ButtonSize/2, self.view.frame.size.height-45-ButtonSize-ButtonSize-2, ButtonSize, ButtonSize);
}

- (void)updateTopViewFrame {
    if (self.currentSession.isAudioOnly) {
        CGFloat containerWidth = self.view.bounds.size.width;
        
        self.portraitView.frame = CGRectMake((containerWidth-64)/2, kStatusBarAndNavigationBarHeight, 64, 64);;
        
        self.userNameLabel.frame = CGRectMake((containerWidth - 240)/2, kStatusBarAndNavigationBarHeight + 64 + 8, 240, 26);
        self.userNameLabel.textAlignment = NSTextAlignmentCenter;
        
        self.stateLabel.frame = CGRectMake((containerWidth - 240)/2, kStatusBarAndNavigationBarHeight + 64 + 26 + 8, 240, 26);
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        self.portraitView.frame = CGRectMake(16, kStatusBarAndNavigationBarHeight, 64, 64);
        self.userNameLabel.frame = CGRectMake(96, kStatusBarAndNavigationBarHeight + 8, 240, 26);
        if(![NSThread isMainThread]) {
            NSLog(@"error not main thread");
        }
        self.userNameLabel.textAlignment = NSTextAlignmentLeft;
        if(self.currentSession.state == kWFAVEngineStateConnected) {
            self.stateLabel.frame = CGRectMake(54, 30, 240, 20);
        } else {
            self.stateLabel.frame = CGRectMake(96, kStatusBarAndNavigationBarHeight + 26 + 14, 240, 16);
        }
        self.stateLabel.textAlignment = NSTextAlignmentLeft;
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
            self.userNameLabel.hidden = NO;
            self.portraitView.hidden = NO;
            self.stateLabel.text = @"通话已结束";
            self.smallVideoView.hidden = YES;
            self.bigVideoView.hidden = YES;
            self.minimizeButton.hidden = YES;
            self.speakerButton.hidden = YES;
            self.downgradeButton.hidden = YES;
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateOutgoing:
            self.answerButton.hidden = YES;
            self.hangupButton.hidden = NO;
            self.hangupButton.frame = [self getButtomCenterButtonFrame];
            self.switchCameraButton.hidden = YES;
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = NO;
                [self updateSpeakerButton];
                self.speakerButton.frame = [self getButtomRightButtonFrame];
                self.audioButton.hidden = NO;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
            } else {
                self.speakerButton.hidden = YES;
                self.audioButton.hidden = YES;
            }
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.scalingType];
            [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType];
            self.stateLabel.text = @"等待对方接听";
            self.smallVideoView.hidden = YES;
            
            self.userNameLabel.hidden = NO;
            self.portraitView.hidden = NO;
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
            [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
            [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType];
            self.stateLabel.text = @"连接建立中";
            self.smallVideoView.hidden = NO;
            self.downgradeButton.hidden = YES;
            break;
        case kWFAVEngineStateConnected:
            self.answerButton.hidden = YES;
            self.hangupButton.hidden = NO;
            self.hangupButton.frame = [self getButtomCenterButtonFrame];
            if (self.currentSession.isAudioOnly) {
                self.speakerButton.hidden = NO;
                self.speakerButton.frame = [self getButtomRightButtonFrame];
                [self updateSpeakerButton];
                self.audioButton.hidden = NO;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
                self.switchCameraButton.hidden = YES;
            } else {
                self.speakerButton.hidden = YES;
                [self.currentSession enableSpeaker:YES];
                self.audioButton.hidden = NO;
                self.audioButton.frame = [self getButtomLeftButtonFrame];
                self.switchCameraButton.hidden = NO;
                self.switchCameraButton.frame = [self getButtomRightButtonFrame];
            }
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            self.minimizeButton.hidden = NO;
            
            if (self.currentSession.isAudioOnly) {
                self.downgradeButton.hidden = YES;;
            } else {
                self.downgradeButton.hidden = NO;
                self.downgradeButton.frame = [self getToAudioButtonFrame];
            }
            
            if (self.currentSession.isAudioOnly) {
                [self.currentSession setupLocalVideoView:nil scalingType:self.scalingType];
                [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType];
                self.smallVideoView.hidden = YES;
                self.bigVideoView.hidden = YES;
                
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_video"] forState:UIControlStateNormal];
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_video_hover"] forState:UIControlStateHighlighted];
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_video_hover"] forState:UIControlStateSelected];
            } else {
                [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
                [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType];
                self.smallVideoView.hidden = NO;
                self.bigVideoView.hidden = NO;
                
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio"] forState:UIControlStateNormal];
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio_hover"] forState:UIControlStateHighlighted];
                [_downgradeButton setImage:[UIImage wf_imageNamed:@"to_audio_hover"] forState:UIControlStateSelected];
            }
            
            
            if (!_currentSession.isAudioOnly) {
                self.userNameLabel.hidden = YES;
                self.portraitView.hidden = YES;
            } else {
                self.userNameLabel.hidden = NO;
                self.portraitView.hidden = NO;
            }
            [self updateConnectedTimeLabel];
            [self startConnectedTimer];
            [self updateTopViewFrame];
            break;
        case kWFAVEngineStateIncomming:
            self.answerButton.hidden = NO;
            self.answerButton.frame = [self getButtomRightButtonFrame];
            self.hangupButton.hidden = NO;
            self.hangupButton.frame = [self getButtomLeftButtonFrame];
            self.switchCameraButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.videoButton.hidden = YES;
            self.scalingButton.hidden = YES;
            self.downgradeButton.hidden = NO;
            self.downgradeButton.frame = [self getToAudioButtonFrame];
            
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.scalingType];
            [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType];
            self.stateLabel.text = @"对方正在邀请您通话";
            self.smallVideoView.hidden = YES;
            
            if (self.currentSession.isAudioOnly) {
                self.downgradeButton.hidden = YES;;
            } else {
                self.downgradeButton.hidden = NO;
                self.downgradeButton.frame = [self getToAudioButtonFrame];
            }
            break;
        default:
            break;
    }
}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
}

- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
    });

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
#endif
@end
