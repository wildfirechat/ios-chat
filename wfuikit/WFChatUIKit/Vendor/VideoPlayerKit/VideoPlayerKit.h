/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import <UIKit/UIKit.h>
#import "VideoPlayer.h"
#import "VideoPlayerView.h"

@interface VideoPlayerKit : UIViewController <VideoPlayer>

@property (nonatomic, weak) id <VideoPlayerDelegate> delegate;
@property (readonly, strong) NSDictionary *currentVideoInfo;
@property (readonly, strong) VideoPlayerView *videoPlayerView;
@property (readonly) BOOL fullScreenModeToggled;
@property (nonatomic) BOOL showStaticEndTime;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic) BOOL allowPortraitFullscreen;
@property (nonatomic) UIEdgeInsets controlsEdgeInsets;
@property (readwrite, strong) AVPlayer *videoPlayer;

- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen;
- (void)syncFullScreenButton:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)showCannotFetchStreamError;
- (void)launchFullScreen;
- (void)minimizeVideo;
- (void)playPauseHandler;
+ (VideoPlayerKit *)videoPlayerWithContainingViewController:(UIViewController *)containingViewController
                                            optionalTopView:(UIView *)topView
                                    hideTopViewWithControls:(BOOL)hideTopViewWithControls
                                    __attribute__((deprecated("Replaced by videoPlayerWithContainingView:(UIView *)")));
+ (VideoPlayerKit *)videoPlayerWithContainingView:(UIView *)containingView
                                  optionalTopView:(UIView *)topView
                          hideTopViewWithControls:(BOOL)hideTopViewWithControls;

@end
