/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "VideoPlayerKit.h"
#import "FullScreenViewController.h"
// #import "ShareThis.h"

NSString * const kVideoPlayerVideoChangedNotification = @"VideoPlayerVideoChangedNotification";
NSString * const kVideoPlayerWillHideControlsNotification = @"VideoPlayerWillHideControlsNotitication";
NSString * const kVideoPlayerWillShowControlsNotification = @"VideoPlayerWillShowControlsNotification";
NSString * const kTrackEventVideoStart = @"Video Start";
NSString * const kTrackEventVideoLiveStart = @"Video Live Start";
NSString * const kTrackEventVideoComplete = @"Video Complete";

// Match the controls animation duration with status bar duration
static const NSTimeInterval controlsAnimationDuration = 0.4;

@interface VideoPlayerKit () <UIGestureRecognizerDelegate>

@property (readwrite, strong) NSDictionary *currentVideoInfo;
@property (readwrite, strong) VideoPlayerView *videoPlayerView;
@property (readwrite) BOOL restoreVideoPlayStateAfterScrubbing;
@property (readwrite, strong) id scrubberTimeObserver;
@property (readwrite, strong) id playClockTimeObserver;
@property (readwrite) BOOL seekToZeroBeforePlay;
@property (readwrite) BOOL rotationIsLocked;
@property (readwrite) BOOL playerIsBuffering;
@property (nonatomic, weak) UIView *containingView;
@property (nonatomic, weak) UIView *topView;
@property (readwrite) BOOL fullScreenModeToggled;
@property (nonatomic) BOOL isAlwaysFullscreen;
@property (nonatomic, readwrite) BOOL isPlaying;
@property (nonatomic, strong) FullScreenViewController *fullscreenViewController;
@property (nonatomic) CGRect previousBounds;
@property (nonatomic) BOOL hideTopViewWithControls;
@property (nonatomic) UIStatusBarStyle previousStatusBarStyle;

@end

@implementation VideoPlayerKit {
    BOOL playWhenReady;
    BOOL scrubBuffering;
    BOOL showShareOptions;
}

- (void)setTopView:(UIView *)topView
{
    _topView = topView;
    if (self.hideTopViewWithControls) {
        __weak UIView *weakTopView = _topView;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:kVideoPlayerWillHideControlsNotification
                                                          object:self
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [UIView animateWithDuration:controlsAnimationDuration
                                                                           animations:^{
                                                                               [weakTopView setAlpha:0.0f];
                                                                           }];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:kVideoPlayerWillShowControlsNotification
                                                          object:self
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [UIView animateWithDuration:controlsAnimationDuration
                                                                           animations:^{
                                                                               [weakTopView setAlpha:1.0f];
                                                                           }];
                                                      }];
    }
}

- (id)initWithContainingView:(UIView *)containingView optionalTopView:(UIView *)topView hideTopViewWithControls:(BOOL)hideTopViewWithControls
{
    if ((self = [super init])) {
        self.containingView = containingView;
        self.hideTopViewWithControls = hideTopViewWithControls;
        self.topView = topView;
        self.previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        self.view.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

+ (VideoPlayerKit *)videoPlayerWithContainingViewController:(UIViewController *)containingViewController
                                                       optionalTopView:(UIView *)topView
                                               hideTopViewWithControls:(BOOL)hideTopViewWithControls
{
    VideoPlayerKit *videoPlayer = [[VideoPlayerKit alloc] initWithContainingView:containingViewController.view
                                                                 optionalTopView:topView
                                                         hideTopViewWithControls:hideTopViewWithControls];
    
    return videoPlayer;
}

+ (VideoPlayerKit *)videoPlayerWithContainingView:(UIView *)containingView
                                            optionalTopView:(UIView *)topView
                                    hideTopViewWithControls:(BOOL)hideTopViewWithControls
{
    VideoPlayerKit *videoPlayer = [[VideoPlayerKit alloc] initWithContainingView:containingView
                                                                 optionalTopView:topView
                                                         hideTopViewWithControls:hideTopViewWithControls];
    
    return videoPlayer;
}

- (void)setControlsEdgeInsets:(UIEdgeInsets)controlsEdgeInsets
{
    if (!self.videoPlayerView) {
        self.videoPlayerView = [[VideoPlayerView alloc] initWithFrame:self.containingView.bounds];
    }
    _controlsEdgeInsets = controlsEdgeInsets;
    self.videoPlayerView.controlsEdgeInsets = _controlsEdgeInsets;

    [self.view setNeedsLayout];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserversFromVideoPlayerItem];
    [self removePlayerTimeObservers];
}

- (void)removeObserversFromVideoPlayerItem
{
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_videoPlayer removeObserver:self forKeyPath:@"externalPlaybackActive"];
    [_videoPlayer removeObserver:self forKeyPath:@"airPlayVideoActive"];
}

- (void)loadView
{
    if (!self.videoPlayerView) {
        self.videoPlayerView = [[VideoPlayerView alloc] initWithFrame:self.containingView.bounds];
    }
    
    if (self.topView) {
        self.topView.frame = CGRectMake(0, 0, self.videoPlayerView.frame.size.width, self.topView.frame.size.height);
        [self.videoPlayerView addSubview:self.topView];
    }
    
    self.view = self.videoPlayerView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _currentVideoInfo = [[NSDictionary alloc] init];
    
    [_videoPlayerView.playPauseButton addTarget:self action:@selector(playPauseHandler) forControlEvents:UIControlEventTouchUpInside];
    
    [_videoPlayerView.fullScreenButton addTarget:self action:@selector(fullScreenButtonHandler) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoPlayerView.shareButton addTarget:self action:@selector(shareButtonHandler) forControlEvents:UIControlEventTouchUpInside];
    
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubberIsScrolling) forControlEvents:UIControlEventValueChanged];
    [_videoPlayerView.videoScrubber addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    
    UITapGestureRecognizer *playerTouchedGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoTapHandler)];
    playerTouchedGesture.delegate = self;
    [_videoPlayerView addGestureRecognizer:playerTouchedGesture];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [pinchRecognizer setDelegate:self];
    [self.view addGestureRecognizer:pinchRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:self.videoPlayerView.playerControlBar] || [touch.view isDescendantOfView:self.videoPlayerView.shareButton]) {
        return NO;
    }
    return YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.fullScreenModeToggled) {
        BOOL isHidingPlayerControls = self.videoPlayerView.playerControlBar.alpha == 0;
        [[UIApplication sharedApplication] setStatusBarHidden:isHidingPlayerControls withAnimation:UIStatusBarAnimationNone];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)presentShareOptions
{
    showShareOptions = NO;
//    [ShareThis showShareOptionsToShareUrl:[_currentVideoInfo objectForKey:@"shareURL"] title:[_currentVideoInfo objectForKey:@"title"] image:nil onViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController] forTypeOfContent:STContentTypeVideo];
}

- (void)shareButtonHandler
{
    // Minimize the video if fullscreen so that ShareThis can work
    if (self.fullScreenModeToggled) {
        showShareOptions = YES;
        [self minimizeVideo];
    } else {    
        [self presentShareOptions];
    }
}

- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen
{
    [self.videoPlayer pause];
    
    [[_videoPlayerView activityIndicator] startAnimating];
    // Reset the buffer bar back to 0
    [self.videoPlayerView.progressView setProgress:0 animated:NO];
    [self showControls];
    
    NSString *vidID = videoID ?: @"";
    _currentVideoInfo = @{ @"title": title ?: @"", @"videoID": vidID, @"isStreaming": @(streaming), @"shareURL": shareURL ? @"" : url};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerVideoChangedNotification
                                                        object:self
                                                      userInfo:_currentVideoInfo];
    if ([self.delegate respondsToSelector:@selector(trackEvent:videoID:title:)]) {
        if (streaming) {
            [self.delegate trackEvent:kTrackEventVideoLiveStart videoID:vidID title:title];
        } else {
            [self.delegate trackEvent:kTrackEventVideoStart videoID:vidID title:title];
        }
    }
    
    [_videoPlayerView.currentPositionLabel setText:@""];
    [_videoPlayerView.timeLeftLabel setText:@""];
    _videoPlayerView.videoScrubber.value = 0;
    
    [_videoPlayerView setTitle:title];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
                                     MPMediaItemPropertyTitle: title,
     }];
    
    [self setURL:url];
    
    [self syncPlayPauseButtons];
    
    if (playInFullScreen) {
        self.isAlwaysFullscreen = YES;
        [self launchFullScreen];
    } else {
        [self.containingView addSubview:self.videoPlayerView];
    }
}

- (void)showCannotFetchStreamError
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Sad Panda says..."
                              message:@"I can't seem to fetch that stream. Please try again later."
                              delegate:nil
                              cancelButtonTitle:@"Bummer!"
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)playPauseHandler
{
    if (_seekToZeroBeforePlay) {
        _seekToZeroBeforePlay = NO;
        [_videoPlayer seekToTime:kCMTimeZero];
    }
    
    if ([self isPlaying]) {
        [_videoPlayer pause];
    } else {
        [self playVideo];
        [[_videoPlayerView activityIndicator] stopAnimating];
    }
    
    [self syncPlayPauseButtons];
    [self showControls];
}

- (void)launchFullScreen
{
    if (!self.fullScreenModeToggled) {
        self.fullScreenModeToggled = YES;
        
        if (!self.isAlwaysFullscreen) {
            [self hideControlsAnimated:YES];
        }
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [self syncFullScreenButton:[[UIApplication sharedApplication] statusBarOrientation]];
        
        if (!self.fullscreenViewController) {
            self.fullscreenViewController = [[FullScreenViewController alloc] init];
            self.fullscreenViewController.allowPortraitFullscreen = self.allowPortraitFullscreen;
        }
        
        [self.videoPlayerView setFullscreen:YES];
        [self.fullscreenViewController.view addSubview:self.videoPlayerView];
        
        
        if (self.topView) {
            [self.topView removeFromSuperview];
            [self.fullscreenViewController.view addSubview:self.topView];
        }
        
        if (self.isAlwaysFullscreen) {
            self.videoPlayerView.alpha = 0.0;
            if (self.topView) {
                self.topView.alpha = 0.0;
            }
        } else {
            self.previousBounds = self.videoPlayerView.frame;
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationCurveLinear
                             animations:^{
                                 [self.videoPlayerView setCenter:CGPointMake( self.videoPlayerView.superview.bounds.size.width / 2, ( self.videoPlayerView.superview.bounds.size.height / 2))];
                                 self.videoPlayerView.bounds = self.videoPlayerView.superview.bounds;
                             }
                             completion:nil];
        }
        self.fullscreenViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.fullscreenViewController animated:YES completion:^{
            if (self.isAlwaysFullscreen) {
                self.videoPlayerView.frame = CGRectMake(self.videoPlayerView.superview.bounds.size.width / 2, self.videoPlayerView.superview.bounds.size.height / 2, 0, 0);
                self.previousBounds = CGRectMake(self.videoPlayerView.superview.bounds.size.width / 2, self.videoPlayerView.superview.bounds.size.height / 2, 0, 0);
                [self.videoPlayerView setCenter:CGPointMake( self.videoPlayerView.superview.bounds.size.width / 2, self.videoPlayerView.superview.bounds.size.height / 2)];
                [UIView animateWithDuration:0.25f
                                      delay:0.0f
                                    options:UIViewAnimationCurveLinear
                                 animations:^{
                                     self.videoPlayerView.alpha = 1.0;
                                     self.topView.alpha = 1.0;
                                 }
                                 completion:nil];
                
                self.videoPlayerView.frame = self.videoPlayerView.superview.bounds;
            }
            
            if (self.topView) {
                self.topView.frame = CGRectMake(0, 0, self.videoPlayerView.frame.size.width, self.topView.frame.size.height);
            }
            
            if ([self.delegate respondsToSelector:@selector(setFullScreenToggled:)]) {
                [self.delegate setFullScreenToggled:self.fullScreenModeToggled];
            }
        }];
    }
}

- (void)minimizeVideo
{
    if (self.fullScreenModeToggled) {
        self.fullScreenModeToggled = NO;
        [self.videoPlayerView setFullscreen:NO];
        [self hideControlsAnimated:NO];
        [self syncFullScreenButton:self.interfaceOrientation];
        
        if (self.topView) {
            [self.topView removeFromSuperview];
            [self.videoPlayerView addSubview:self.topView];
        }
        
        if (self.isAlwaysFullscreen) {
            [self.videoPlayer pause];
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationCurveLinear
                             animations:^{
                                 self.videoPlayerView.frame = self.previousBounds;
                             }
                             completion:^(BOOL success){
                                 
                                 if (showShareOptions) {
                                     [self presentShareOptions];
                                 }
                                 
                                 [self.videoPlayerView removeFromSuperview];
                             }];
        } else {
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationCurveLinear
                             animations:^{
                                 self.videoPlayerView.frame = self.previousBounds;
                             }
                             completion:^(BOOL success){
                                 if (showShareOptions) {
                                     [self presentShareOptions];
                                 }
                             }];
            
            [self.videoPlayerView removeFromSuperview];
            [self.containingView addSubview:self.videoPlayerView];
        }
        
        [[UIApplication sharedApplication] setStatusBarStyle:self.previousStatusBarStyle];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:self.isAlwaysFullscreen completion:^{

            if (!self.isAlwaysFullscreen) {
                [self showControls];
            }
            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationFade];
            
            if ([self.delegate respondsToSelector:@selector(setFullScreenToggled:)]) {
                [self.delegate setFullScreenToggled:self.fullScreenModeToggled];
            }
        }];
    }
}

- (void)fullScreenButtonHandler
{
    [self showControls];
    
    if (self.fullScreenModeToggled) {
        [self minimizeVideo];
    } else {
        [self launchFullScreen];
    }
}

- (void)pinchGesture:(id)sender
{
    if([(UIPinchGestureRecognizer *)sender state] == UIGestureRecognizerStateEnded) {
        [self fullScreenButtonHandler];
    }
}

- (void)forceOrientationChange
{
    _rotationIsLocked = YES;
    [self performSelector:@selector(unlockRotationLock) withObject:nil afterDelay:0.5];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        UIView *view = [window.subviews objectAtIndex:0];
        [view removeFromSuperview];
        [window addSubview:view];
        
        [_videoPlayerView.superview layoutSubviews];
    } else {
        // Have the VideoPlayerVC's parent VC implement rotation trigger
        if ([self.delegate respondsToSelector:@selector(setFullScreenToggled:)]) {
            [self.delegate setFullScreenToggled:self.fullScreenModeToggled];
        }
    }
}

- (void)unlockRotationLock
{
    _rotationIsLocked = NO;
}

- (void)videoTapHandler
{    
    if (_videoPlayerView.playerControlBar.alpha) {
        [self hideControlsAnimated:YES];
    } else {
        [self showControls];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)setURL:(NSURL *)url
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackBufferEmpty"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackLikelyToKeepUp"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"loadedTimeRanges"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    if (!self.videoPlayer) {
        _videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        [_videoPlayer setAllowsAirPlayVideo:YES];
        [_videoPlayer setUsesAirPlayVideoWhileAirPlayScreenIsActive:YES];
        
        if ([_videoPlayer respondsToSelector:@selector(setAllowsExternalPlayback:)]) { // iOS 6 API
            [_videoPlayer setAllowsExternalPlayback:YES];
        }
        
        [_videoPlayerView setPlayer:_videoPlayer];
    } else {
        [self removeObserversFromVideoPlayerItem];
        [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    
    // iOS 5
    [_videoPlayer addObserver:self forKeyPath:@"airPlayVideoActive" options:NSKeyValueObservingOptionNew context:nil];
    
    // iOS 6
    [_videoPlayer addObserver:self
                   forKeyPath:@"externalPlaybackActive"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.videoPlayer.currentItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:self.videoPlayer.currentItem];
    
}

// Wait for the video player status to change to ready before initializing video player controls
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _videoPlayer
        && ([keyPath isEqualToString:@"externalPlaybackActive"] || [keyPath isEqualToString:@"airPlayVideoActive"])) {
        BOOL externalPlaybackActive = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [[_videoPlayerView airplayIsActiveView] setHidden:!externalPlaybackActive];
        return;
    }
    
    if (object != [_videoPlayer currentItem]) {
        return;
    }
        
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:
                playWhenReady = YES;
                if (![self isPlaying]) {
                    [self playVideo];
                }
                break;
            case AVPlayerStatusFailed:
                // TODO:
                [self removeObserversFromVideoPlayerItem];
                [self removePlayerTimeObservers];
                self.videoPlayer = nil;
                [self minimizeVideo];
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"] && _videoPlayer.currentItem.playbackBufferEmpty) {
        self.playerIsBuffering = YES;
        [[_videoPlayerView activityIndicator] startAnimating];
        [self syncPlayPauseButtons];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _videoPlayer.currentItem.playbackLikelyToKeepUp) {
        if (![self isPlaying] && playWhenReady)
        {
            if (self.playerIsBuffering || scrubBuffering) {
                if (self.restoreVideoPlayStateAfterScrubbing) {
                    self.restoreVideoPlayStateAfterScrubbing = NO;
                    [self playVideo];
                }
            } else {
                [self playVideo];
            }
        }
        [[_videoPlayerView activityIndicator] stopAnimating];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float durationTime = CMTimeGetSeconds([[self.videoPlayer currentItem] duration]);
        float bufferTime = [self availableDuration];
        [self.videoPlayerView.progressView setProgress:bufferTime/durationTime animated:YES];
    }
    
    return;
}

- (float)availableDuration
{
    NSArray *loadedTimeRanges = [[self.videoPlayer currentItem] loadedTimeRanges];
    
    // Check to see if the timerange is not an empty array, fix for when video goes on airplay
    // and video doesn't include any time ranges
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}

- (void)playVideo
{
    if (self.view.superview) {
        self.playerIsBuffering = NO;
        scrubBuffering = NO;
        playWhenReady = NO;
        // Configuration is done, ready to start.
        [self.videoPlayer play];
        [self updatePlaybackProgress];
    }
}

- (void)showControls
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillShowControlsNotification
                                                        object:self
                                                      userInfo:nil];
    [UIView animateWithDuration:controlsAnimationDuration animations:^{
        self.videoPlayerView.playerControlBar.alpha = 1.0;
        self.videoPlayerView.titleLabel.alpha = 1.0;
        self.videoPlayerView.shareButton.alpha = 1.0;
    } completion:nil];
    
    if (self.fullScreenModeToggled) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationFade];
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(hideControlsAnimated:)
                                               object:[NSString stringWithFormat:@"YES"]];
    
    if ([self isPlaying]) {
        [self performSelector:@selector(hideControlsAnimated:)
                   withObject:[NSString stringWithFormat:@"YES"]
                   afterDelay:4.0];
    }
}

- (void)hideControlsAnimated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillHideControlsNotification
                                                        object:self
                                                      userInfo:nil];
    if (animated) {
        [UIView animateWithDuration:controlsAnimationDuration animations:^{
            self.videoPlayerView.playerControlBar.alpha = 0;
            self.videoPlayerView.titleLabel.alpha = 0;
            _videoPlayerView.shareButton.alpha = 0;
        } completion:nil];
        
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationFade];
        }
        
    } else {
        self.videoPlayerView.playerControlBar.alpha = 0;
        self.videoPlayerView.titleLabel.alpha = 0;
        _videoPlayerView.shareButton.alpha = 0;
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationNone];
        }
    }
}

- (void)updatePlaybackProgress
{
    [self syncPlayPauseButtons];
    [self showControls];
    
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (CMTIME_IS_INDEFINITE(playerDuration) || duration <= 0) {
        [_videoPlayerView.videoScrubber setHidden:YES];
        [_videoPlayerView.progressView setHidden:YES];
        [self syncPlayClock];
        return;
    }
    
    [_videoPlayerView.videoScrubber setHidden:NO];
    [_videoPlayerView.progressView setHidden:NO];

    CGFloat width = CGRectGetWidth([_videoPlayerView.videoScrubber bounds]);
    interval = 0.5f * duration / width;
    __weak VideoPlayerKit *vpvc = self;
    _scrubberTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                       queue:NULL
                                                                  usingBlock:^(CMTime time) {
                                                                      [vpvc syncScrubber];
                                                                  }];
    
    // Update the play clock every second
    _playClockTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [vpvc syncPlayClock];
                                                                   }];
    
}

-(void)removePlayerTimeObservers
{
    if (_scrubberTimeObserver) {
        [_videoPlayer removeTimeObserver:_scrubberTimeObserver];
        _scrubberTimeObserver = nil;
    }
    
    if (_playClockTimeObserver) {
        [_videoPlayer removeTimeObserver:_playClockTimeObserver];
        _playClockTimeObserver = nil;
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self syncPlayPauseButtons];
    _seekToZeroBeforePlay = YES;
    if ([self.delegate respondsToSelector:@selector(trackEvent:videoID:title:)]) {
        [self.delegate trackEvent:kTrackEventVideoComplete videoID:[_currentVideoInfo objectForKey:@"videoID"] title:[_currentVideoInfo objectForKey:@"title"]];
    }
    
    [self minimizeVideo];
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        _videoPlayerView.videoScrubber.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [_videoPlayerView.videoScrubber minimumValue];
        float maxValue = [_videoPlayerView.videoScrubber maximumValue];
        double time = CMTimeGetSeconds([_videoPlayer currentTime]);
        
        [_videoPlayerView.videoScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (void)syncPlayClock
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    if (CMTIME_IS_INDEFINITE(playerDuration)) {
        [_videoPlayerView.currentPositionLabel setText:@"LIVE"];
        [_videoPlayerView.timeLeftLabel setText:@""];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(CMTimeGetSeconds([_videoPlayer currentTime]));
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoPlayerView.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
        if (!self.showStaticEndTime) {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"-%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
        } else {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
        }
	}
}

- (CMTime)playerItemDuration
{
    if (_videoPlayer.status == AVPlayerItemStatusReadyToPlay) {
        return([_videoPlayer.currentItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
    return [_videoPlayer rate] != 0.0;
}

- (void)syncPlayPauseButtons
{
    if ([self isPlaying]) {
        [_videoPlayerView.playPauseButton setImage:[UIImage imageNamed:@"pause-button"] forState:UIControlStateNormal];
    } else {
        [_videoPlayerView.playPauseButton setImage:[UIImage imageNamed:@"play-button"] forState:UIControlStateNormal];
    }
}

- (void)syncFullScreenButton:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (_fullScreenModeToggled) {
        [_videoPlayerView.fullScreenButton setImage:[UIImage imageNamed:@"minimize-button"] forState:UIControlStateNormal];
    } else {
        [_videoPlayerView.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen-button"] forState:UIControlStateNormal];
    }
}

-(void)scrubbingDidBegin
{
    if ([self isPlaying]) {
        [_videoPlayer pause];
        [self syncPlayPauseButtons];
        self.restoreVideoPlayStateAfterScrubbing = YES;
        [self showControls];
    }
}

-(void)scrubberIsScrolling
{
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(duration * _videoPlayerView.videoScrubber.value);
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoPlayerView.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
        
        if (!self.showStaticEndTime) {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"-%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
        } else {
            [_videoPlayerView.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
        }
        [_videoPlayer seekToTime:CMTimeMakeWithSeconds((float) currentTime, NSEC_PER_SEC)];
    }
}

-(void)scrubbingDidEnd
{
    if (self.restoreVideoPlayStateAfterScrubbing) {
        scrubBuffering = YES;
    }
    [[_videoPlayerView activityIndicator] startAnimating];
    
    [self showControls];
}

- (NSString *)stringFormattedTimeFromSeconds:(double *)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:*seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    if (*seconds >= 3600) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    
    return [formatter stringFromDate:date];
}

@end
