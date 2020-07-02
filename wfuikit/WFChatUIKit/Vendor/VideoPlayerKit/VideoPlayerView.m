/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "VideoPlayerView.h"

#define PLAYER_CONTROL_BAR_HEIGHT 40
#define LABEL_PADDING 10
#define CURRENT_POSITION_WIDTH 56
#define TIME_LEFT_WIDTH 59
#define ALIGNMENT_FUZZ 2
#define ROUTE_BUTTON_ALIGNMENT_FUZZ 8

@interface VideoPlayerView ()

@property (readwrite, strong) UILabel *titleLabel;
@property (readwrite, strong) UIView *playerControlBar;
@property (readwrite, strong) AirplayActiveView *airplayIsActiveView;
@property (readwrite, strong) UIButton *airplayButton;
@property (readwrite, strong) MPVolumeView *volumeView;
@property (readwrite, strong) UIButton *fullScreenButton;
@property (readwrite, strong) UIButton *playPauseButton;
@property (readwrite, strong) UISlider *videoScrubber;
@property (readwrite, strong) UILabel *currentPositionLabel;
@property (readwrite, strong) UILabel *timeLeftLabel;
@property (readwrite, strong) UIProgressView *progressView;
@property (readwrite, strong) UIActivityIndicatorView *activityIndicator;
@property (readwrite, strong) UIButton *shareButton;
@end

@implementation VideoPlayerView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _airplayIsActiveView = [[AirplayActiveView alloc] initWithFrame:CGRectZero];
        [_airplayIsActiveView setHidden:YES];
        [self addSubview:_airplayIsActiveView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_titleLabel setFont:[UIFont fontWithName:@"Forza-Medium" size:16.0f]];
        [_titleLabel setTextColor:[UIColor whiteColor]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [_titleLabel setNumberOfLines:2];
        [_titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [self addSubview:_titleLabel];
        
        _playerControlBar = [[UIView alloc] init];
        [_playerControlBar setOpaque:NO];
        [_playerControlBar setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.8]];
        
        _playPauseButton = [[UIButton alloc] init];
        [_playPauseButton setImage:[UIImage imageNamed:@"play-button"] forState:UIControlStateNormal];
        [_playPauseButton setShowsTouchWhenHighlighted:YES];
        [_playerControlBar addSubview:_playPauseButton];
        
        _fullScreenButton = [[UIButton alloc] init];
        [_fullScreenButton setImage:[UIImage imageNamed:@"fullscreen-button"] forState:UIControlStateNormal];
        [_fullScreenButton setShowsTouchWhenHighlighted:YES];
        [_playerControlBar addSubview:_fullScreenButton];
        
        _progressView = [[UIProgressView alloc] init];
        _progressView.progressTintColor = [UIColor colorWithRed:31.0/255.0 green:31.0/255.0 blue:31.0/255.0 alpha:1.0];
        _progressView.trackTintColor = [UIColor darkGrayColor];
        [_playerControlBar addSubview:_progressView];
        
        _videoScrubber = [[UISlider alloc] init];
        [_videoScrubber setMinimumTrackTintColor:[UIColor redColor]];
        [_videoScrubber setMaximumTrackImage:[UIImage imageNamed:@"transparentBar"] forState:UIControlStateNormal];
        [_videoScrubber setThumbTintColor:[UIColor whiteColor]];
        [_playerControlBar addSubview:_videoScrubber];
        
        _volumeView = [[MPVolumeView alloc] init];
        [_volumeView setShowsRouteButton:YES];
        [_volumeView setShowsVolumeSlider:NO];
        [_playerControlBar addSubview:_volumeView];
        
        // Listen to alpha changes to know when other routes are available
        for (UIButton *button in [_volumeView subviews]) {
            if (![button isKindOfClass:[UIButton class]]) {
                continue;
            }
            
            [button addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
            [self setAirplayButton:button];
        }
        
        _currentPositionLabel = [[UILabel alloc] init];
        [_currentPositionLabel setBackgroundColor:[UIColor clearColor]];
        [_currentPositionLabel setTextColor:[UIColor whiteColor]];
        [_currentPositionLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [_currentPositionLabel setTextAlignment:NSTextAlignmentCenter];
        [_playerControlBar addSubview:_currentPositionLabel];
        
        _timeLeftLabel = [[UILabel alloc] init];
        [_timeLeftLabel setBackgroundColor:[UIColor clearColor]];
        [_timeLeftLabel setTextColor:[UIColor whiteColor]];
        [_timeLeftLabel setFont:[UIFont systemFontOfSize:14.0f]];
        [_timeLeftLabel setTextAlignment:NSTextAlignmentCenter];
        [_playerControlBar addSubview:_timeLeftLabel];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_activityIndicator];

        _shareButton = [[UIButton alloc] init];
        [_shareButton setImage:[UIImage imageNamed:@"share-button"] forState:UIControlStateNormal];
        [_shareButton setShowsTouchWhenHighlighted:YES];
        
        // Hide the Share Button by default after removing ShareThis
        _shareButton.hidden = YES;
        
        [self addSubview:_shareButton];
        self.controlsEdgeInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)dealloc
{
    [_airplayButton removeObserver:self forKeyPath:@"alpha"];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = [self bounds];

    CGRect insetBounds = CGRectInset(UIEdgeInsetsInsetRect(bounds, self.controlsEdgeInsets), _padding, _padding);
    CGSize titleLabelSize = [[_titleLabel text] sizeWithFont:[_titleLabel font]
                                           constrainedToSize:CGSizeMake(insetBounds.size.width, CGFLOAT_MAX)
                                               lineBreakMode:NSLineBreakByCharWrapping];
    
    UIImage *shareImage = [UIImage imageNamed:@"share-button"];
    
    if (!_fullscreen) {
        CGSize twoLineSize = [@"M\nM" sizeWithFont:[_titleLabel font]
                                 constrainedToSize:CGSizeMake(insetBounds.size.width, CGFLOAT_MAX)
                                     lineBreakMode:UILineBreakModeWordWrap];
        
        self.autoresizingMask = UIViewAutoresizingNone;
        
        [_titleLabel setFrame:CGRectMake(insetBounds.origin.x + LABEL_PADDING,
                                         insetBounds.origin.y,
                                         insetBounds.size.width,
                                         titleLabelSize.height)];
        
        CGRect playerFrame = CGRectMake(0,
                                        0,
                                        bounds.size.width,
                                        bounds.size.height - twoLineSize.height - _padding - _padding);
        [_airplayIsActiveView setFrame:playerFrame];

        [_shareButton setFrame:CGRectMake(insetBounds.size.width - shareImage.size.width, insetBounds.origin.y, shareImage.size.width, shareImage.size.height)];
    } else {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        [_titleLabel setFrame:CGRectMake(insetBounds.origin.x + LABEL_PADDING,
                                         insetBounds.origin.y,
                                         insetBounds.size.width,
                                         titleLabelSize.height)];
        
        
        [_airplayIsActiveView setFrame:bounds];
        
        [_shareButton setFrame:CGRectMake(insetBounds.size.width - shareImage.size.width, insetBounds.origin.y, shareImage.size.width, shareImage.size.height)];
    }
    
    [_playerControlBar setFrame:CGRectMake(bounds.origin.x,
                                           bounds.size.height - PLAYER_CONTROL_BAR_HEIGHT - kTabbarSafeBottomMargin,
                                           bounds.size.width,
                                           PLAYER_CONTROL_BAR_HEIGHT)];
    
    [_activityIndicator setFrame:CGRectMake((bounds.size.width - _activityIndicator.frame.size.width)/2.0,
                                            (bounds.size.height - _activityIndicator.frame.size.width)/2.0,
                                            _activityIndicator.frame.size.width,
                                            _activityIndicator.frame.size.height)];
    
    [_playPauseButton setFrame:CGRectMake(0,
                                          0,
                                          PLAYER_CONTROL_BAR_HEIGHT,
                                          PLAYER_CONTROL_BAR_HEIGHT)];
    
    CGRect fullScreenButtonFrame = CGRectMake(bounds.size.width - PLAYER_CONTROL_BAR_HEIGHT,
                                              0,
                                              PLAYER_CONTROL_BAR_HEIGHT,
                                              PLAYER_CONTROL_BAR_HEIGHT);
    [_fullScreenButton setFrame:fullScreenButtonFrame];
    
    CGRect routeButtonRect = CGRectZero;
    _volumeView.hidden = YES;
    if (NO/*[_airplayButton alpha] > 0*/) {
        if ([_volumeView respondsToSelector:@selector(routeButtonRectForBounds:)]) {
            routeButtonRect = [_volumeView routeButtonRectForBounds:bounds];
        } else {
            routeButtonRect = CGRectMake(0, 0, 24, 18);
        }
        [_volumeView setFrame:CGRectMake(CGRectGetMinX(fullScreenButtonFrame) - routeButtonRect.size.width
                                         - ROUTE_BUTTON_ALIGNMENT_FUZZ,
                                         PLAYER_CONTROL_BAR_HEIGHT / 2 - routeButtonRect.size.height / 2,
                                         routeButtonRect.size.width,
                                         routeButtonRect.size.height)];
    }
    
    [_currentPositionLabel setFrame:CGRectMake(PLAYER_CONTROL_BAR_HEIGHT,
                                               ALIGNMENT_FUZZ,
                                               CURRENT_POSITION_WIDTH,
                                               PLAYER_CONTROL_BAR_HEIGHT)];
    [_timeLeftLabel setFrame:CGRectMake(bounds.size.width - PLAYER_CONTROL_BAR_HEIGHT - TIME_LEFT_WIDTH
                                        - routeButtonRect.size.width,
                                        ALIGNMENT_FUZZ,
                                        TIME_LEFT_WIDTH,
                                        PLAYER_CONTROL_BAR_HEIGHT)];
    
    CGRect scrubberRect = CGRectMake(PLAYER_CONTROL_BAR_HEIGHT + CURRENT_POSITION_WIDTH,
                                     0,
                                     bounds.size.width - (PLAYER_CONTROL_BAR_HEIGHT * 2) - TIME_LEFT_WIDTH -
                                     CURRENT_POSITION_WIDTH - (TIME_LEFT_WIDTH - CURRENT_POSITION_WIDTH)
                                     - routeButtonRect.size.width,
                                     PLAYER_CONTROL_BAR_HEIGHT);
    [_videoScrubber setFrame:scrubberRect];
    
    CGRect progressViewFrameWithOffset = [_videoScrubber trackRectForBounds:scrubberRect];
    progressViewFrameWithOffset.origin.y += 3;
    [_progressView setFrame:progressViewFrameWithOffset];
}

- (void)setTitle:(NSString *)title
{
    [_titleLabel setText:title];
    [self setNeedsLayout];
}

- (void)setFullscreen:(BOOL)fullscreen
{
    if (_fullscreen == fullscreen) {
        return;
    }
    
    _fullscreen = fullscreen;
    
    [self setNeedsLayout];
}

- (CGFloat)heightForWidth:(CGFloat)width
{
    CGSize titleLabelSize = [@"M\nM" sizeWithFont:[_titleLabel font]
                                constrainedToSize:CGSizeMake(width - _padding - _padding, CGFLOAT_MAX)];
    return (width / 16 * 9) + titleLabelSize.height;
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)self.layer setPlayer:player];
    [_airplayIsActiveView setHidden:YES];
    [self addSubview:self.playerControlBar];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _airplayButton && [keyPath isEqualToString:@"alpha"]) {
        [self setNeedsLayout];
    }
}

@end
