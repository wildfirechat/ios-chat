/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "VideoPlayerSampleView.h"

@interface VideoPlayerSampleView()

@property (nonatomic, readwrite, strong) UIView *videoPlayerView;
@property (nonatomic, readwrite, strong) UIButton *playFullScreenButton;
@property (nonatomic, readwrite, strong) UIButton *playInlineButton;

@end

@implementation VideoPlayerSampleView

- (id)init
{
    if ((self = [super init])) {
        self.playInlineButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.playInlineButton setTitle:@"Play Inline" forState:UIControlStateNormal];
        [self addSubview:self.playInlineButton];
        
        self.playFullScreenButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.playFullScreenButton setTitle:@"Play Fullscreen" forState:UIControlStateNormal];
        [self addSubview:self.playFullScreenButton];
        
        self.videoPlayerView = [[UIView alloc] init];
        self.videoPlayerView.autoresizesSubviews = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.videoPlayerView];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    self.playInlineButton.frame = CGRectMake((bounds.size.width - 150)/2.0,
                                             (bounds.size.height - 50)/2.0,
                                             150,
                                             50);
    
    self.playFullScreenButton.frame = CGRectMake((bounds.size.width - 150)/2.0,
                                       (bounds.size.height + 50)/2.0,
                                       150,
                                       50);
    
    CGFloat videoHeight = bounds.size.width * 9 / 16;
    self.videoPlayerView.frame = CGRectMake(0, [[UIApplication sharedApplication] statusBarFrame].size.height, bounds.size.width, videoHeight);
}

@end
