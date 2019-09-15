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

@interface WFCUFloatingWindow () <WFAVCallSessionDelegate>

@property(nonatomic, strong) NSTimer *activeTimer;
@property(nonatomic, copy) void (^touchedBlock)(WFAVCallSession *callSession);
@property(nonatomic, strong) CTCallCenter *callCenter;

@end

static WFCUFloatingWindow *staticWindow = nil;

static NSString *kFloatingWindowPosX = @"kFloatingWindowPosX";
static NSString *kFloatingWindowPosY = @"kFloatingWindowPosY";

@implementation WFCUFloatingWindow

+ (void)startCallFloatingWindow:(WFAVCallSession *)callSession
              withTouchedBlock:(void (^)(WFAVCallSession *callSession))touchedBlock {
    staticWindow = [[WFCUFloatingWindow alloc] init];
    staticWindow.callSession = callSession;
    [staticWindow.callSession setDelegate:staticWindow];
    staticWindow.touchedBlock = touchedBlock;
    [staticWindow initWindow];
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
                                             selector:@selector(onOrientationChanged:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [self addProximityMonitoringObserver];
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

- (void)onOrientationChanged:(NSNotification *)notification {
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
    if (self.callSession.state == kWFAVEngineStateConnected && ![self isVideoViewEnabledSession]) {
        NSString *timeStr;
        if (sec < 60 * 60) {
            timeStr = [NSString stringWithFormat:@"%02ld:%02ld", sec / 60, sec % 60];
        } else {
            timeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", sec / 60 / 60, (sec / 60) % 60, sec % 60];
        }
        [self.floatingButton setTitle:timeStr forState:UIControlStateNormal];
        [self layoutTextUnderImageButton:self.floatingButton];
    }
}

- (void)updateWindow {
    CGFloat posX = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosX] floatValue];
    CGFloat posY = [[[NSUserDefaults standardUserDefaults] objectForKey:kFloatingWindowPosY] floatValue];
    posX = posX ? posX : 30;
    posY = posY ? posY : 30;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    posX = (posX + 30) > screenBounds.size.width ? (screenBounds.size.width - 30) : posX;
    posY = (posY + 48) > screenBounds.size.height ? (screenBounds.size.height - 48) : posY;

    if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft &&
        [self isSupportOrientation:UIInterfaceOrientationLandscapeLeft]) {
        self.window.transform = CGAffineTransformMakeRotation(M_PI / 2);
        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 96, 64);
        if ([self isVideoViewEnabledSession]) {
            self.videoView.frame = CGRectMake(0, 0, 96, 64);
        }
    } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight &&
               [self isSupportOrientation:UIInterfaceOrientationLandscapeRight]) {
        self.window.transform = CGAffineTransformMakeRotation(-M_PI / 2);
        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 96, 64);
        if ([self isVideoViewEnabledSession]) {
            self.videoView.frame = CGRectMake(0, 0, 96, 64);
        }
    } else {
        if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown &&
            [self isSupportOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
            self.window.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            self.window.transform = CGAffineTransformMakeRotation(0);
        }

        self.window.frame = CGRectMake(posX, posY, 64, 96);
        self.floatingButton.frame = CGRectMake(0, 0, 64, 96);
        if ([self isVideoViewEnabledSession]) {
            self.videoView.frame = CGRectMake(0, 0, 64, 96);
        }
    }

    if ([self isVideoViewEnabledSession]) {
        if (self.callSession.state == kWFAVEngineStateConnected) {
            [self.callSession setupRemoteVideoView:self.videoView scalingType:kWFAVVideoScalingTypeAspectBalanced];
            [self.callSession setupLocalVideoView:nil scalingType:kWFAVVideoScalingTypeAspectBalanced];
        } else if (self.callSession.state == kWFAVEngineStateIdle) {
            UILabel *videoStopTips =
                [[UILabel alloc] initWithFrame:CGRectMake(0, self.videoView.frame.size.height / 2 - 10,
                                                          self.videoView.frame.size.width, 20)];
            videoStopTips.textAlignment = NSTextAlignmentCenter;
            videoStopTips.text = WFCString(@"Ended");
            videoStopTips.textColor = HEXCOLOR(0x0195ff);
            [self.videoView addSubview:videoStopTips];
        }
    } else {
        if (self.callSession.state == kWFAVEngineStateConnected) {
            [self.floatingButton setBackgroundColor:[UIColor clearColor]];
        } else if (self.callSession.state == kWFAVEngineStateIdle) {
            [self.floatingButton setTitle:WFCString(@"Ended")
                                 forState:UIControlStateNormal];
        }
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
        if (false /*self.callSession.mediaType == Audio*/) {
            [_floatingButton setImage:[UIImage imageNamed:@"floatingaudio"]
                             forState:UIControlStateNormal];
        } else {
            [_floatingButton setImage:[UIImage imageNamed:@"floatingvideo"]
                             forState:UIControlStateNormal];
        }
        [_floatingButton setTitle:@"" forState:UIControlStateNormal];
        _floatingButton.backgroundColor = [UIColor clearColor];
        _floatingButton.frame = CGRectMake(0, 0, 64, 96);
        CGRect windowFrame = self.window.frame;
        windowFrame.size.width = _floatingButton.frame.size.width;
        windowFrame.size.height = _floatingButton.frame.size.height;
        self.window.frame = windowFrame;

        [_floatingButton addTarget:self action:@selector(touchedWindow:) forControlEvents:UIControlEventTouchUpInside];

        [self.window addSubview:_floatingButton];
    }
    return _floatingButton;
}

- (BOOL)isSupportOrientation:(UIInterfaceOrientation)orientation {
    UIInterfaceOrientationMask mask =
        [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:self.window];
    return mask & (1 << orientation);
}

- (void)handlePanGestures:(UIPanGestureRecognizer *)paramSender {
    if (paramSender.state != UIGestureRecognizerStateEnded && paramSender.state != UIGestureRecognizerStateFailed) {
        CGPoint location = [paramSender locationInView:[UIApplication sharedApplication].windows[0]];

        if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft &&
            [self isSupportOrientation:UIInterfaceOrientationLandscapeLeft]) {
            CGFloat tmp = location.x;
            location.x = [UIScreen mainScreen].bounds.size.height - location.y;
            location.y = tmp;
        } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight &&
                   [self isSupportOrientation:UIInterfaceOrientationLandscapeRight]) {
            CGFloat tmp = location.x;
            location.x = location.y;
            location.y = [UIScreen mainScreen].bounds.size.width - tmp;
        } else if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown &&
                   [self isSupportOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
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
        if (isLandscape && [self isSupportOrientation:(UIInterfaceOrientation)[UIDevice currentDevice].orientation]) {
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
    [self hideCallFloatingWindow];
    if (self.touchedBlock) {
        self.touchedBlock(self.callSession);
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

- (void)layoutTextUnderImageButton:(UIButton *)button {
    [button.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [button setTitleColor:HEXCOLOR(0x0195ff) forState:UIControlStateNormal];

    button.titleEdgeInsets = UIEdgeInsetsMake(0, -button.imageView.frame.size.width,
                                              -button.imageView.frame.size.height - 6 / 2, 0);
    // button.imageEdgeInsets =
    // UIEdgeInsetsMake(-button.titleLabel.frame.size.height-offset/2, 0, 0,
    // -button.titleLabel.frame.size.width);
    // 由于iOS8中titleLabel的size为0，用上面这样设置有问题，修改一下即可
    button.imageEdgeInsets = UIEdgeInsetsMake(-button.titleLabel.intrinsicContentSize.height - 6 / 2,
                                              0, 0, -button.titleLabel.intrinsicContentSize.width);
}

- (BOOL)isVideoViewEnabledSession {
    if (YES/*self.callSession.mediaType == video && !self.callSession.isMultiCall*/) {
        return YES;
    } else {
        return NO;
    }
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
            break;
    }
}

- (void)didCallEndWithReason:(WFAVCallEndReason)reason {
    
}

- (void)didError:(NSError *)error {
    
}

- (void)didGetStats:(NSArray *)stats {
    
}

- (void)didCreateLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    
}

- (void)didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    
}

- (void)didChangeMode:(BOOL)isAudioOnly {
    [self.videoView removeFromSuperview];
    [self initWindow];
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
@end
#endif
