/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "AirplayActiveView.h"
#import <QuartzCore/QuartzCore.h>

@interface AirplayActiveView ()

@property (readwrite, strong) CAGradientLayer *gradientLayer;
@property (readwrite, strong) UIImageView *displayImageView;
@property (readwrite, strong) UILabel *titleLabel;
@property (readwrite, strong) UILabel *descriptionLabel;

@end

@implementation AirplayActiveView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        _gradientLayer = [[CAGradientLayer alloc] init];
        [_gradientLayer setColors:@[
         (id)[[UIColor colorWithWhite:0.22f alpha:1.0f] CGColor],
         (id)[[UIColor colorWithWhite:0.09f alpha:1.0f] CGColor],
         ]];
        [_gradientLayer setLocations:@[ @0.0, @1.0 ]];
        [[self layer] addSublayer:_gradientLayer];
        
        _displayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"airplay-display.png"]];
        [self addSubview:_displayImageView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_titleLabel setText:@"Airplay"];
        [_titleLabel setFont:[UIFont fontWithName:@"DINRoundCompPro" size:20.0f]];
        [_titleLabel setTextColor:[UIColor colorWithWhite:0.5f alpha:1.0f]];
        [_titleLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_titleLabel];
        
        _descriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_descriptionLabel setText:@"This video is playing elsewhere"];
        [_descriptionLabel setFont:[UIFont fontWithName:@"DINRoundCompPro" size:14.0f]];
        [_descriptionLabel setTextColor:[UIColor colorWithWhite:0.36f alpha:1.0f]];
        [_descriptionLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_descriptionLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = [self bounds];
    
    [_gradientLayer setFrame:bounds];
    
    CGSize displayImageSize = [[_displayImageView image] size];
    
    if (bounds.size.height < 300) {
        displayImageSize = CGSizeMake(displayImageSize.width / 2, displayImageSize.height / 2);
    }
    
    CGSize titleLabelSize;
    CGSize descriptionLabelSize;
    if (@available(iOS 7.0, *)) {
        titleLabelSize = [[_titleLabel text] sizeWithAttributes:@{NSFontAttributeName:[_titleLabel font]}];
        descriptionLabelSize = [[_descriptionLabel text] sizeWithAttributes:@{NSFontAttributeName:[_descriptionLabel font]}];
    } else {
        titleLabelSize = [[_titleLabel text] sizeWithFont:[_titleLabel font]];
        descriptionLabelSize = [[_descriptionLabel text] sizeWithFont:[_descriptionLabel font]];
    }
    
    
    
    
    
    CGFloat contentHeight = displayImageSize.height + titleLabelSize.height + descriptionLabelSize.height;
    
    CGFloat y = (bounds.size.height / 2) - (contentHeight / 2);
    [_displayImageView setFrame:CGRectMake((bounds.size.width / 2) - (displayImageSize.width / 2),
                                           y,
                                           displayImageSize.width,
                                           displayImageSize.height)];
    y += displayImageSize.height;
    
    [_titleLabel setFrame:CGRectMake((bounds.size.width / 2) - (titleLabelSize.width / 2),
                                     y,
                                     titleLabelSize.width,
                                     titleLabelSize.height)];
    y += titleLabelSize.height - 8;
    
    [_descriptionLabel setFrame:CGRectMake((bounds.size.width / 2) - (descriptionLabelSize.width / 2),
                                           y,
                                           descriptionLabelSize.width,
                                           descriptionLabelSize.height)];
}

@end
