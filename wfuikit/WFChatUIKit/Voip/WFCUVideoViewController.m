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
#import "UIFont+YH.h"
#import "UIColor+YH.h"
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
@property (nonatomic, strong) UIImageView *backGroudPortraitView;

@property (nonatomic, strong) UILabel *userNameLabel;
@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, assign) BOOL swapVideoView;

@property (nonatomic, strong) WFAVCallSession *currentSession;

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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.scalingType = kWFAVVideoScalingTypeAspectBalanced;
    self.bigVideoView = [[UIView alloc] initWithFrame:self.view.bounds];
    UITapGestureRecognizer *tapBigVideo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickedBigVideoView:)];
    [self.bigVideoView addGestureRecognizer:tapBigVideo];
    [self.view addSubview:self.bigVideoView];
    
    self.smallVideoView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SmallVideoView, kStatusBarAndNavigationBarHeight, SmallVideoView, SmallVideoView * 4 /3)];
    [self.smallVideoView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoPan:)]];
    [self.smallVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSmallVideoTaped:)]];
    [self.view addSubview:self.smallVideoView];
    
    [self checkAVPermission];
    
    if(self.currentSession.state == kWFAVEngineStateOutgoing && !self.currentSession.isAudioOnly) {
        [[WFAVEngineKit sharedEngineKit] startPreview];
    }
    
    WFCCUserInfo *user = [[WFCCIMService sharedWFCIMService] getUserInfo:self.currentSession.participantIds[0] inGroup:self.currentSession.conversation.type == Group_Type ? self.currentSession.conversation.target : nil refresh:NO];
    
    self.portraitView = [[UIImageView alloc] init];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[user.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    self.portraitView.layer.masksToBounds = YES;
    self.portraitView.layer.cornerRadius = 10.f;
    self.portraitView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.portraitView.layer.borderWidth = 1.0;
    [self.view addSubview:self.portraitView];
    
    
    self.userNameLabel = [[UILabel alloc] init];
    self.userNameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:27];
    self.userNameLabel.text = user.displayName;
    self.userNameLabel.textColor = [UIColor colorWithHexString:@"0xffffff"];
    [self.view addSubview:self.userNameLabel];
    
    self.stateLabel = [[UILabel alloc] init];
    self.stateLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:14];
    self.stateLabel.textColor = [UIColor colorWithHexString:@"0xB4B4B6"];
    [self.view addSubview:self.stateLabel];
    
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

- (UIButton *)downgradeButton {
    if (!_downgradeButton) {
        _downgradeButton = [[UIButton alloc] init];
        [_downgradeButton setImage:[UIImage imageNamed:@"to_audio"] forState:UIControlStateNormal];
        [_downgradeButton setImage:[UIImage imageNamed:@"to_audio_hover"] forState:UIControlStateHighlighted];
        [_downgradeButton setImage:[UIImage imageNamed:@"to_audio_hover"] forState:UIControlStateSelected];
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
        _videoButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-ButtonSize/2, self.view.frame.size.height-10-ButtonSize, ButtonSize, ButtonSize)];
        [_videoButton setTitle:WFCString(@"Video") forState:UIControlStateNormal];
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
        [_scalingButton setTitle:WFCString(@"Scale") forState:UIControlStateNormal];
        _scalingButton.backgroundColor = [UIColor greenColor];
        [_scalingButton addTarget:self action:@selector(scalingButtonDidTap:) forControlEvents:UIControlEventTouchDown];
        _scalingButton.hidden = YES;
        [self.view addSubview:_scalingButton];
    }
    return _scalingButton;
}
- (void)setSwapVideoView:(BOOL)swapVideoView {
    _swapVideoView = swapVideoView;
    if (swapVideoView) {
        [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.scalingType];
        [self.currentSession setupRemoteVideoView:self.smallVideoView scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
    } else {
        [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
        [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
    }
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
    [WFCUFloatingWindow startCallFloatingWindow:self.currentSession focusUser:self.currentSession.participantIds[0] withTouchedBlock:^(WFAVCallSession *callSession) {
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

- (void)onSmallVideoTaped:(id)sender {
    if (self.currentSession.state == kWFAVEngineStateConnected) {
        self.swapVideoView = !_swapVideoView;
    }
}

- (void)videoButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        [self.currentSession muteVideo:!self.currentSession.isVideoMuted];
    }
}

- (void)scalingButtonDidTap:(UIButton *)button {
    if (self.currentSession.state != kWFAVEngineStateIdle) {
        if (self.scalingType < kWFAVVideoScalingTypeAspectBalanced) {
            self.scalingType++;
        } else {
            self.scalingType = kWFAVVideoScalingTypeAspectFit;
        }
        
        self.swapVideoView = _swapVideoView;
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
    CGFloat containerWidth = self.view.bounds.size.width;
    CGFloat containerHeight = self.view.bounds.size.height;

    if (self.currentSession.isAudioOnly) {
        
        CGFloat postionY = (containerHeight - 110) / 2.0 - 70;
        self.portraitView.frame = CGRectMake((containerWidth-110)/2, postionY, 110, 110);;
        
        postionY += 110 + 16;
        self.userNameLabel.frame = CGRectMake((containerWidth - 240)/2, postionY, 240, 27);
        self.userNameLabel.textAlignment = NSTextAlignmentCenter;
        
        postionY += 12 + 27;
        self.stateLabel.frame = CGRectMake((containerWidth - 240)/2, postionY, 240, 26);
        self.stateLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        CGFloat postionX = 16;
        self.portraitView.frame = CGRectMake(postionX, kStatusBarAndNavigationBarHeight, 62, 62);
        postionX += 62;
        postionX += 8;
        self.userNameLabel.frame = CGRectMake(postionX, kStatusBarAndNavigationBarHeight + 8, 240, 26);
        self.userNameLabel.textAlignment = NSTextAlignmentLeft;

        if(![NSThread isMainThread]) {
            NSLog(@"error not main thread");
        }
        if(self.currentSession.state == kWFAVEngineStateConnected) {
            self.stateLabel.frame = CGRectMake(54, 30, 240, 20);
        } else {
            self.stateLabel.frame = CGRectMake(88, kStatusBarAndNavigationBarHeight + 26 + 14, 240, 16);
        }
//        self.stateLabel.hidden = YES;
        self.stateLabel.textAlignment = NSTextAlignmentLeft;
    }
}

- (void)onClickedBigVideoView:(id)sender {
    if (self.currentSession.state != kWFAVEngineStateConnected) {
        return;
    }
    
    if (self.currentSession.audioOnly) {
        return;
    }
    
    if (self.smallVideoView.hidden) {
        if (self.hangupButton.hidden) {
            self.hangupButton.hidden = NO;
            self.audioButton.hidden = NO;
            self.switchCameraButton.hidden = NO;
            self.smallVideoView.hidden = NO;
            self.minimizeButton.hidden = NO;
            self.downgradeButton.hidden = NO;
        } else {
            self.hangupButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.downgradeButton.hidden = YES;
            self.switchCameraButton.hidden = YES;
            self.minimizeButton.hidden = YES;
        }
    } else {
        self.smallVideoView.hidden = YES;
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
            self.stateLabel.text = WFCString(@"CallEnded");
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
            [self.currentSession setupLocalVideoView:self.bigVideoView scalingType:self.scalingType];
            [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
            self.stateLabel.text = WFCString(@"WaitingAccept");
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
            self.swapVideoView = NO;
            self.stateLabel.text = WFCString(@"CallConnecting");
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
                [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
                self.smallVideoView.hidden = YES;
                self.bigVideoView.hidden = YES;
                
                [_downgradeButton setImage:[UIImage imageNamed:@"to_video"] forState:UIControlStateNormal];
                [_downgradeButton setImage:[UIImage imageNamed:@"to_video_hover"] forState:UIControlStateHighlighted];
                [_downgradeButton setImage:[UIImage imageNamed:@"to_video_hover"] forState:UIControlStateSelected];
            } else {
                [self.currentSession setupLocalVideoView:self.smallVideoView scalingType:self.scalingType];
                [self.currentSession setupRemoteVideoView:self.bigVideoView scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
                self.smallVideoView.hidden = NO;
                self.bigVideoView.hidden = NO;
                
                [_downgradeButton setImage:[UIImage imageNamed:@"to_audio"] forState:UIControlStateNormal];
                [_downgradeButton setImage:[UIImage imageNamed:@"to_audio_hover"] forState:UIControlStateHighlighted];
                [_downgradeButton setImage:[UIImage imageNamed:@"to_audio_hover"] forState:UIControlStateSelected];
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
            [self.currentSession setupRemoteVideoView:nil scalingType:self.scalingType forUser:self.currentSession.participantIds[0]];
            self.stateLabel.text = WFCString(@"InvitingYou");
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

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack fromUser:(NSString *)userId {
}

- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString *)userId {
    
}
- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString *)userId {
    
}
- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[WFAVEngineKit sharedEngineKit] dismissViewController:self];
    });

}
- (void)didParticipantJoined:(NSString *)userId {
    
}

- (void)didParticipantConnected:(NSString *)userId {
    
}

- (void)didParticipantLeft:(NSString *)userId withReason:(WFAVCallEndReason)reason {
    
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
    //识别当前设备的旋转方向
    CGRect smallVideoFrame = CGRectZero;
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
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
            self.smallVideoView.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.bigVideoView.transform = CGAffineTransformMakeRotation(M_PI_2);
            smallVideoFrame = CGRectMake(width - SmallVideoView - 8, height - 8 - kStatusBarAndNavigationBarHeight + 64 - SmallVideoView - SmallVideoView/3 - kTabbarSafeBottomMargin, SmallVideoView * 4 /3, SmallVideoView);
            NSLog(@"屏幕向左橫置");
            break;

        case UIDeviceOrientationLandscapeRight:
            self.smallVideoView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.bigVideoView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            smallVideoFrame = CGRectMake(8-SmallVideoView/3, 8 + kStatusBarAndNavigationBarHeight - 64+SmallVideoView/3, SmallVideoView * 4 /3, SmallVideoView);
            NSLog(@"屏幕向右橫置");
            break;

        case UIDeviceOrientationPortrait:
            self.smallVideoView.transform = CGAffineTransformMakeRotation(0);
            self.bigVideoView.transform = CGAffineTransformMakeRotation(0);
            smallVideoFrame = CGRectMake(self.view.frame.size.width - SmallVideoView, kStatusBarAndNavigationBarHeight, SmallVideoView, SmallVideoView * 4 /3);
            NSLog(@"屏幕直立");
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"屏幕直立，上下顛倒");
            break;

        default:
            NSLog(@"無法识别");
            break;
    }
    self.smallVideoView.frame = smallVideoFrame;
    return YES;
}
#endif
@end
