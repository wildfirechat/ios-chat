/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "VideoPlayerSampleViewController.h"
#import "VideoPlayerSampleView.h"

#define LABEL_PADDING 10
#define TOPVIEW_HEIGHT 40

@interface VideoPlayerSampleViewController ()

@property (nonatomic, strong) VideoPlayerKit *videoPlayerViewController;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) VideoPlayerSampleView *videoPlayerSampleView;
@property (nonatomic) BOOL fullScreenOnOrientationChange;
@property (nonatomic) BOOL isFullScreenPortraitOrientation;
@end

@implementation VideoPlayerSampleViewController

- (id)init
{
    if ((self = [super init])) {
        // Optional auto-fullscreen on orientation change
        self.fullScreenOnOrientationChange = YES;
        
        // Optional Top View
        _topView = [[UIView alloc] init];
        UILabel *topViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_PADDING, 5, 200, 40.0)];
        topViewLabel.text = @"Top View Label";
        topViewLabel.textColor = [UIColor whiteColor];
        [_topView addSubview:topViewLabel];
    }
    return self;
}

- (void) handleOrientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
            if (!self.videoPlayerViewController.fullScreenModeToggled) {
                [self.videoPlayerViewController launchFullScreen];
            } else if (self.videoPlayerViewController.allowPortraitFullscreen) {
                // Preserve portrait fullscreen mode
                self.isFullScreenPortraitOrientation = YES;
            }
            break;
        case UIDeviceOrientationPortrait:
            if (self.videoPlayerViewController.fullScreenModeToggled) {
                if (self.videoPlayerViewController.allowPortraitFullscreen &&
                    self.isFullScreenPortraitOrientation) {
                    // Reset the portrait mode flag
                    self.isFullScreenPortraitOrientation = NO;
                } else {
                    [self.videoPlayerViewController minimizeVideo];
                }
            }
            break;
        default:
            break;
    }
}

// Fullscreen / minimize without need for user's input
- (void)fullScreen
{
    if (!self.videoPlayerViewController.fullScreenModeToggled) {
        [self.videoPlayerViewController launchFullScreen];
    } else {
        [self.videoPlayerViewController minimizeVideo];
    }
}

- (void)loadView
{
    self.videoPlayerSampleView = [[VideoPlayerSampleView alloc] init];
    [self.videoPlayerSampleView.playFullScreenButton addTarget:self action:@selector(playVideoFullScreen) forControlEvents:UIControlEventTouchUpInside];
    [self.videoPlayerSampleView.playInlineButton addTarget:self action:@selector(playVideoInline) forControlEvents:UIControlEventTouchUpInside];
    [self setView:self.videoPlayerSampleView];
}

- (void)playVideoFullScreen
{
    // Hide Play Inline button on FullScreen to avoid layout conflicts
    [self.videoPlayerSampleView.playInlineButton setHidden:YES];
    
    [self playVideo:YES];
}

- (void)playVideoInline
{
    [self playVideo:NO];
}

- (void)playVideo:(BOOL)playInFullScreen
{
    NSURL *url = [NSURL URLWithString:@"https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"];
    
    if (!self.videoPlayerViewController) {
        self.videoPlayerViewController = [VideoPlayerKit videoPlayerWithContainingView:self.videoPlayerSampleView.videoPlayerView optionalTopView:_topView hideTopViewWithControls:YES];
        // Need to set edge inset if top view is inserted
        [self.videoPlayerViewController setControlsEdgeInsets:UIEdgeInsetsMake(self.topView.frame.size.height, 0, 0, 0)];
        self.videoPlayerViewController.delegate = self;
        self.videoPlayerViewController.allowPortraitFullscreen = YES;
    } else {
        [self.videoPlayerViewController.view removeFromSuperview];
    }
    
    [self.view addSubview:self.videoPlayerViewController.view];
    
    [self.videoPlayerViewController playVideoWithTitle:@"Video Title" URL:url videoID:nil shareURL:nil isStreaming:NO playInFullScreen:playInFullScreen];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.topView.frame = CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height, self.view.bounds.size.width, TOPVIEW_HEIGHT);
    
    if (self.fullScreenOnOrientationChange) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter]
                             addObserver:self
                                selector:@selector(handleOrientationChanged:)
                                    name:UIDeviceOrientationDidChangeNotification
                                  object:[UIDevice currentDevice]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
