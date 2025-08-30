//
//  WFCUFloatingWindow.m
//  WFDemo
//
//  Created by heavyrain on 17/9/27.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUFloatingWindow.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>
#import <UIKit/UIKit.h>
#import "WFCUConferenceManager.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"
#import "WFZConferenceInfo.h"

@interface WFCUFloatingWindow () <WFAVCallSessionDelegate, WFCUConferenceManagerDelegate>

@property(nonatomic, strong) NSTimer *activeTimer;
@property(nonatomic, copy) void (^touchedBlock)(WFAVCallSession *callSession, WFZConferenceInfo *conferenceInfo);
@property(nonatomic, strong) CTCallCenter *callCenter;
@property(nonatomic, strong) WFAVParticipantProfile *focusUserProfile;

@property(nonatomic, assign)CGFloat winWidth;
@property(nonatomic, assign)CGFloat winHeight;

@property(nonatomic, strong)NSTimer *broadcastOngoingTimer;
@end

static WFCUFloatingWindow *staticWindow = nil;

static NSString *kFloatingWindowPosX = @"kFloatingWindowPosX";
static NSString *kFloatingWindowPosY = @"kFloatingWindowPosY";

@implementation WFCUFloatingWindow

+ (void)startCallFloatingWindow:(WFAVCallSession *)callSession focusUser:(WFAVParticipantProfile *)focusUserProfile
              withTouchedBlock:(void (^)(WFAVCallSession *callSession, WFZConferenceInfo *conferenceInfo))touchedBlock {
    staticWindow = [[WFCUFloatingWindow alloc] init];
    staticWindow.callSession = callSession;
    [staticWindow.callSession setDelegate:staticWindow];
    staticWindow.touchedBlock = touchedBlock;
    staticWindow.focusUserProfile = focusUserProfile;
    [staticWindow initWindow];
    if(callSession.isConference) {
        [callSession.participants enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj.userId isEqualToString:focusUserProfile.userId] && obj.screeSharing == focusUserProfile.screeSharing) {
                [callSession setParticipant:obj.userId screenSharing:obj.screeSharing videoType:WFAVVideoType_SmallStream];
            } else {
                [callSession setParticipant:obj.userId screenSharing:obj.screeSharing videoType:WFAVVideoType_None];
            }
        }];
    }
}

+ (void)stopCallFloatingWindow {
    [staticWindow hideCallFloatingWindow];
    [staticWindow clearCallFloatingWindow];
    staticWindow = nil;
}

- (void)initWindow {
    if (self.callSession.state == kWFAVEngineStateIdle) {
        [self performSelector:@selector(clearCallFloatingWindow) withObject:nil afterDelay:2];
    }
    [self updateActiveTimer];
    [self startActiveTimer];
    [self updateWindow];
    [self registerTelephonyEvent];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [self addProximityMonitoringObserver];
    [WFCUConferenceManager sharedInstance].delegate = self;
    
    if(!self.callSession.isConference) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
    }
    
    if(!self.callSession.isConference) {
        if(self.callSession.state == kWFAVEngineStateConnected && [self.callSession.initiator isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [self startBroadcastCallOngoing:YES];
        } else {
            [self startBroadcastCallOngoing:NO];
        }
    }
}

- (void)onReceiveMessages:(NSNotification *)notification {
    NSArray<WFCCMessage *> *messages = notification.object;
    for (WFCCMessage *msg in messages) {
        if([msg.content isKindOfClass:WFCCJoinCallRequestMessageContent.class]) {
            WFCCJoinCallRequestMessageContent *join = (WFCCJoinCallRequestMessageContent *)msg.content;
            if([self.callSession.callId isEqualToString:join.callId] && self.callSession.state == kWFAVEngineStateConnected && [self.callSession.initiator isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [self.callSession inviteNewParticipants:@[msg.fromUser] targetClientId:join.clientId autoAnswer:YES];
            }
        }
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [self startBroadcastCallOngoing:NO];
}

- (void)startBroadcastCallOngoing:(BOOL)start {
    if([WFCUConfigManager globalManager].enableMultiCallAutoJoin) {
        if(start && !self.broadcastOngoingTimer) {
            __weak typeof(self)ws = self;
            WFCCMultiCallOngoingMessageContent *ongoing = [[WFCCMultiCallOngoingMessageContent alloc] init];
            ongoing.callId = self.callSession.callId;
            ongoing.audioOnly = self.callSession.audioOnly;
            ongoing.initiator = self.callSession.initiator;
            ongoing.targetIds = self.callSession.participantIds;
            if (@available(iOS 10.0, *)) {
                self.broadcastOngoingTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                    typeof(self) strongSelf = ws;
                    if(strongSelf.callSession.state == kWFAVEngineStateConnected) {
                        [[WFCCIMService sharedWFCIMService] send:strongSelf.callSession.conversation content:ongoing success:nil error:nil];
                    }
                }];
            } else {
                // Fallback on earlier versions
            }
        } else if(!start && self.broadcastOngoingTimer) {
            [self.broadcastOngoingTimer invalidate];
            self.broadcastOngoingTimer = nil;
        }
    }
}


- (void)registerTelephonyEvent {
    self.callCenter = [[CTCallCenter alloc] init];
    __weak __typeof(self) weakSelf = self;
    self.callCenter.callEventHandler = ^(CTCall *call) {
        if ([call.callState isEqualToString:CTCallStateConnected]) {
            [weakSelf.callSession endCall];
        }
    };
}

- (void)onDeviceOrientationDidChange:(NSNotification *)notification {
    [self updateWindow];
}

- (void)startActiveTimer {
    self.activeTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(updateActiveTimer)
                                                      userInfo:nil
                                                       repeats:YES];
    [self.activeTimer fire];
}

- (void)stopActiveTimer {
    if (self.activeTimer) {
        [self.activeTimer invalidate];
        self.activeTimer = nil;
    }
}

- (void)updateActiveTimer {
    long sec = [[NSDate date] timeIntervalSince1970] - self.callSession.connectedTime / 1000;
    if (self.callSession.state == kWFAVEngineStateConnected && ![self isVideoViewEnabled]) {
        NSString *timeStr;
        if (sec < 60 * 60) {
            timeStr = [NSString stringWithFormat:@"%02ld:%02ld", sec / 60, sec % 60];
        } else {
            timeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", sec / 60 / 60, (sec / 60) % 60, sec % 60];
        }
        
        BOOL showFloatingButton = NO;
        if (!self.floatingButton.titleLabel.text) {
            self.floatingButton.hidden = YES;
            showFloatingButton = YES;
        }
        [self.floatingButton setTitle:timeStr forState:UIControlStateNormal];
        [self layoutTimeText:self.floatingButton];
        
        if (showFloatingButton) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.floatingButton setTitle:timeStr forState:UIControlStateNormal];
                [self layoutTimeText:self.floatingButton];
                self.floatingButton.hidden = NO;
            });
        }
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

- (void)updateWindow {
    CGFloat posX = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosX] floatValue];
    CGFloat posY = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosY] floatValue];
    posX = posX ? posX : 30;
    posY = posY ? posY : 30;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    posX = (posX + 30) > screenBounds.size.width ? (screenBounds.size.width - 30) : posX;
    posY = (posY + 48) > screenBounds.size.height ? (screenBounds.size.height - 48) : posY;

    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
        self.window.transform = CGAffineTransformMakeRotation(M_PI / 2);
        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 96, 64);
        if ([self isVideoViewEnabled]) {
            self.videoView.frame = CGRectMake(0, 0, 96, 64);
        }
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        self.window.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 96, 64);
        if ([self isVideoViewEnabled]) {
            self.videoView.frame = CGRectMake(0, 0, 96, 64);
        }
    } else {
        if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown) {
            self.window.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            self.window.transform = CGAffineTransformMakeRotation(0);
        }

        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 64, 96);
        if ([self isVideoViewEnabled]) {
            self.videoView.frame = CGRectMake(0, 0, 64, 96);
        }
    }

    if(self.callSession.isInAppScreenSharing) {
        self.window.frame = CGRectMake(posX, posY, 64, 64);
        self.window.layer.cornerRadius = 32;
        self.window.layer.masksToBounds = YES;
        self.floatingButton.frame = CGRectMake(0, 0, 64, 64);
        self.floatingButton.layer.cornerRadius = 32;
        self.floatingButton.layer.masksToBounds = YES;
        
        [self.floatingButton setTitle:WFCString(@"EndSharing") forState:UIControlStateNormal];
        [self.floatingButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.floatingButton setBackgroundColor:[UIColor redColor]];
        self.videoView.hidden = YES;
    } else if ([self isVideoViewEnabled]) {
        if (self.callSession.state == kWFAVEngineStateIncomming) {
            [self.floatingButton setTitle:WFCString(@"WaitAnwser") forState:UIControlStateNormal];
            self.videoView.hidden = YES;
        } else if (self.callSession.state == kWFAVEngineStateOutgoing) {
            self.videoView.hidden = NO;
            [self.floatingButton setTitle:@"" forState:UIControlStateNormal];
            [self.callSession setupLocalVideoView:self.videoView scalingType:kWFAVVideoScalingTypeAspectFit];
        } else if (self.callSession.state == kWFAVEngineStateConnected) {
            self.videoView.hidden = NO;
            [self.floatingButton setTitle:@"" forState:UIControlStateNormal];
            NSString *focusUserId;
            BOOL screenSharing = NO;
            if([self.focusUserProfile isKindOfClass:[NSString class]]) {
                focusUserId = (NSString *)self.focusUserProfile;
            } else {
                focusUserId = self.focusUserProfile.userId;
                screenSharing = self.focusUserProfile.screeSharing;
            }
            
            if ([focusUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [self.callSession setupLocalVideoView:self.videoView scalingType:kWFAVVideoScalingTypeAspectFit];
            } else {
                [self.callSession setupRemoteVideoView:self.videoView scalingType:kWFAVVideoScalingTypeAspectFit forUser:focusUserId screenSharing:screenSharing];
            }
            
            [self updateVideoView];
        } else if (self.callSession.state == kWFAVEngineStateIdle) {
            UILabel *videoStopTips =
                [[UILabel alloc] initWithFrame:CGRectMake(0, self.videoView.frame.size.height / 2 - 10,
                                                          self.videoView.frame.size.width, 20)];
            videoStopTips.textAlignment = NSTextAlignmentCenter;
            videoStopTips.text = WFCString(@"Ended");
            videoStopTips.textColor = HEXCOLOR(0x0195ff);
            [self.videoView addSubview:videoStopTips];
        } else { //connecting...
            self.videoView.hidden = NO;
            [self.floatingButton setTitle:@"" forState:UIControlStateNormal];
        }
    } else {
        if (self.callSession.state == kWFAVEngineStateIdle) {
            [self.floatingButton setBackgroundColor:[UIColor clearColor]];
            [self.floatingButton setTitle:WFCString(@"Ended")
                                 forState:UIControlStateNormal];
        } else {
            if (self.callSession.state == kWFAVEngineStateOutgoing) {
                [self.floatingButton setTitle:WFCString(@"WaitAnwser") forState:UIControlStateNormal];
            } else if (self.callSession.state == kWFAVEngineStateIncomming) {
                [self.floatingButton setTitle:WFCString(@"WaitAnwser") forState:UIControlStateNormal];
            } else {
                [self.floatingButton setTitle:@"" forState:UIControlStateNormal];
                [self.floatingButton setImage:[WFCUImage imageNamed:@"floatingaudio"]
            forState:UIControlStateNormal];
            }
        }
    }
}

- (void)updateVideoView {
    __block BOOL isMuted = NO;
    NSString *focusUserId;
    BOOL screenSharing = NO;
    if([self.focusUserProfile isKindOfClass:[NSString class]]) {
        focusUserId = (NSString *)self.focusUserProfile;
    } else {
        focusUserId = self.focusUserProfile.userId;
        screenSharing = self.focusUserProfile.screeSharing;
    }
    
    if ([focusUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        isMuted = [WFAVEngineKit sharedEngineKit].currentSession.isVideoMuted || [WFAVEngineKit sharedEngineKit].currentSession.isAudience;
    } else {
        [[[WFAVEngineKit sharedEngineKit].currentSession participants] enumerateObjectsUsingBlock:^(WFAVParticipantProfile * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([obj.userId isEqual:focusUserId] && obj.screeSharing == screenSharing) {
                isMuted = obj.videoMuted || obj.audience;
                *stop = YES;
            }
        }];
    }
    if(isMuted) {
        [self.floatingButton setTitle:WFCString(@"CloseVideo")
                             forState:UIControlStateNormal];
        self.videoView.hidden = YES;
        [self.callSession setParticipant:focusUserId screenSharing:screenSharing videoType:WFAVVideoType_None];
    } else {
        self.videoView.hidden = NO;
        [self.callSession setParticipant:focusUserId screenSharing:screenSharing videoType:WFAVVideoType_SmallStream];
    }
}
- (UIWindow *)window {
    if (!_window) {
        CGFloat posX = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosX] floatValue];
        CGFloat posY = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosY] floatValue];
        posX = (posX - 30) ? posX : 30;
        posY = (posY - 48) ? posY : 48;
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        posX = (posX + 30) > screenBounds.size.width ? (screenBounds.size.width - 30) : posX;
        posY = (posY + 48) > screenBounds.size.height ? (screenBounds.size.height - 48) : posY;
        _window = [[UIWindow alloc] initWithFrame:CGRectMake(posX, posY, 64, 96)];
        _window.backgroundColor = [UIColor whiteColor];
        _window.windowLevel = UIWindowLevelAlert + 1;
        _window.layer.cornerRadius = 4;
        _window.layer.masksToBounds = YES;
        _window.layer.borderWidth = 1;
        _window.layer.borderColor = [HEXCOLOR(0x0A88E1) CGColor];
        [_window makeKeyAndVisible]; //关键语句,显示window

        UIPanGestureRecognizer *panGestureRecognizer =
            [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGestures:)];
        panGestureRecognizer.minimumNumberOfTouches = 1;
        panGestureRecognizer.maximumNumberOfTouches = 1;
        [_window addGestureRecognizer:panGestureRecognizer];
    }
    return _window;
}

- (UIView *)videoView {
    if (!_videoView) {
        _videoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 64, 96)];
        _videoView.backgroundColor = [UIColor blackColor];
        CGRect windowFrame = self.window.frame;
        windowFrame.size.width = _videoView.frame.size.width;
        windowFrame.size.height = _videoView.frame.size.height;
        self.window.frame = windowFrame;
        [self.window addSubview:_videoView];

        UITapGestureRecognizer *tap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedWindow:)];
        [_videoView addGestureRecognizer:tap];
    }
    return _videoView;
}

- (UIButton *)floatingButton {
    if (!_floatingButton) {
        _floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_floatingButton setTitle:@"" forState:UIControlStateNormal];
        _floatingButton.backgroundColor = [UIColor clearColor];
        _floatingButton.frame = CGRectMake(0, 0, 64, 96);
        
        [_floatingButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _floatingButton.titleLabel.font = [UIFont systemFontOfSize:14];
        CGRect windowFrame = self.window.frame;
        windowFrame.size.width = _floatingButton.frame.size.width;
        windowFrame.size.height = _floatingButton.frame.size.height;
        self.window.frame = windowFrame;

        [_floatingButton addTarget:self action:@selector(touchedWindow:) forControlEvents:UIControlEventTouchUpInside];
        [self.window addSubview:_floatingButton];
    }
    return _floatingButton;
}

- (void)handlePanGestures:(UIPanGestureRecognizer *)paramSender {
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed) {
        CGPoint location = [paramSender locationInView:[UIApplication sharedApplication].windows[0]];

        if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
            CGFloat tmp = location.x;
            location.x = [UIScreen mainScreen].bounds.size.height - location.y;
            location.y = tmp;
        } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
            CGFloat tmp = location.x;
            location.x = location.y;
            location.y = [UIScreen mainScreen].bounds.size.width - tmp;
        } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown) {
            CGFloat tmp = location.x;
            location.x = [UIScreen mainScreen].bounds.size.height - location.y;
            location.y = [UIScreen mainScreen].bounds.size.width - tmp;
        }

        CGRect frame = self.window.frame;
        frame.origin.x = location.x - frame.size.width / 2;
        frame.origin.y = location.y - frame.size.height / 2;

        if (frame.origin.x < 0) {
            frame.origin.x = 2;
        }
        if (frame.origin.y < 0) {
            frame.origin.y = 2;
        }

        CGRect screenBounds = [UIScreen mainScreen].bounds;
        BOOL isLandscape = screenBounds.size.width > screenBounds.size.height;
        if (isLandscape) {
            if (frame.origin.y + frame.size.height > [UIScreen mainScreen].bounds.size.width) {
                frame.origin.y = [UIScreen mainScreen].bounds.size.width - 2 - frame.size.height;
            }

            if (frame.origin.x + frame.size.width > [UIScreen mainScreen].bounds.size.height) {
                frame.origin.x = [UIScreen mainScreen].bounds.size.height - 2 - frame.size.width;
            }
        } else {
            if (frame.origin.x + frame.size.width > [UIScreen mainScreen].bounds.size.width) {
                frame.origin.x = [UIScreen mainScreen].bounds.size.width - 2 - frame.size.width;
            }

            if (frame.origin.y + frame.size.height > [UIScreen mainScreen].bounds.size.height) {
                frame.origin.y = [UIScreen mainScreen].bounds.size.height - 2 - frame.size.height;
            }
        }
        self.window.frame = frame;
    } else if (paramSender.state == UIGestureRecognizerStateEnded) {
        CGRect frame = self.window.frame;
        [[NSUserDefaults standardUserDefaults] setObject:@(frame.origin.x) forKey:kFloatingWindowPosX];
        [[NSUserDefaults standardUserDefaults] setObject:@(frame.origin.y) forKey:kFloatingWindowPosY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)touchedWindow:(id)sender {
    if(self.callSession.isInAppScreenSharing) {
        [self.callSession setInAppScreenSharing:NO];
    }
    
    [self hideCallFloatingWindow];
    if (self.touchedBlock) {
        self.touchedBlock(self.callSession, [WFCUConferenceManager sharedInstance].currentConferenceInfo);
    }
    [self clearCallFloatingWindow];
}

- (void)hideCallFloatingWindow {
    [self stopActiveTimer];

    if (_videoView) {
        [_videoView removeFromSuperview];
        _videoView = nil;
    }
    if (_floatingButton) {
        [_floatingButton removeFromSuperview];
        _floatingButton = nil;
    }
    [_window setHidden:YES];
}

- (void)clearCallFloatingWindow {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _activeTimer = nil;
    _callSession = nil;
    _touchedBlock = nil;
    _floatingButton = nil;
    _videoView = nil;
    _window = nil;
    staticWindow = nil;
}

- (void)layoutTimeText:(UIButton *)button {
//    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [button.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [button setTitleColor:HEXCOLOR(0x0195ff) forState:UIControlStateNormal];

    //top left buttom right
    button.titleEdgeInsets = UIEdgeInsetsMake(button.imageView.frame.size.height / 2, -button.imageView.frame.size.width,
                                              -button.imageView.frame.size.height, 0);

    button.imageEdgeInsets = UIEdgeInsetsMake(0,
                                              0, button.imageView.frame.size.height / 2, -button.titleLabel.bounds.size.width);
}

- (BOOL)isVideoViewEnabled {
    return !self.callSession.isAudioOnly;
}

#pragma mark - WFAVCallSessionDelegate
- (void)didChangeState:(WFAVEngineState)state {
    switch (state) {
        case kWFAVEngineStateIdle:
            [self updateWindow];
            [self performSelector:@selector(clearCallFloatingWindow) withObject:nil afterDelay:2];
            [self removeProximityMonitoringObserver];
            break;
            
        case kWFAVEngineStateConnected:
            [self updateWindow];
            break;
            
        default:
            [self updateWindow];
            break;
    }
    if(!self.callSession.isConference) {
        if(state == kWFAVEngineStateConnected && [self.callSession.initiator isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            [self startBroadcastCallOngoing:YES];
        } else {
            [self startBroadcastCallOngoing:NO];
        }
    }
}

- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    if(self.callSession.isConference) {
        [[WFCUConferenceManager sharedInstance] addHistory:[WFCUConferenceManager sharedInstance].currentConferenceInfo duration:(int)([WFAVEngineKit sharedEngineKit].currentSession.endTime - [WFAVEngineKit sharedEngineKit].currentSession.startTime)];
    }
}

- (void)didParticipantJoined:(NSString *)userId screenSharing:(BOOL)screenSharing {
    
}

- (void)didParticipantConnected:(NSString *)userId screenSharing:(BOOL)screenSharing {
    
}

- (void)didParticipantLeft:(NSString *)userId screenSharing:(BOOL)screenSharing withReason:(WFAVCallEndReason)reason {
    
}
- (void)didError:(NSError *)error {
    
}

- (void)didGetStats:(NSArray *)stats {
    
}

- (void)didChangeAudioRoute {
    
}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack fromUser:(NSString *)userId screenSharing:(BOOL)screenSharing {
    [self updateWindow];
}
- (void)didChangeType:(BOOL)audience ofUser:(NSString *)userId screenSharing:(BOOL)screenSharing {
    [self updateVideoView];
}
- (void)didVideoMuted:(BOOL)videoMuted fromUser:(NSString *)userId {
    
}
- (void)didReportAudioVolume:(NSInteger)volume ofUser:(NSString *)userId {
    
}
- (void)didChangeMode:(BOOL)isAudioOnly {
    [self.videoView removeFromSuperview];
    [self initWindow];
}

- (void)didChangeInitiator:(NSString * _Nullable)initiator {
    if(!self.callSession.isConference) {
        [self startBroadcastCallOngoing:[initiator isEqualToString:[WFCCNetworkService sharedInstance].userId]];
    }
}

- (void)didMuteStateChanged:(NSArray<NSString *> *)userIds {
    if(![WFAVEngineKit sharedEngineKit].currentSession.isAudioOnly) {
        [self updateVideoView];
    }
}
- (void)addProximityMonitoringObserver {
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityStatueChanged:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
}

- (void)removeProximityMonitoringObserver {
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
}

- (void)proximityStatueChanged:(NSNotificationCenter *)notification {
    
}

- (void)onChangeModeRequest:(BOOL)isAudience {
    if(isAudience) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
    } else {
        //Todo 该怎么处理？
    }
}
@end
#endif
