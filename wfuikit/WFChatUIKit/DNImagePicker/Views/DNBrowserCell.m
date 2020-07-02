//
//  DNBrowserCell.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/28.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNBrowserCell.h"
#import "DNTapDetectingImageView.h"
#import "DNPhotoBrowser.h"
#import "UIView+DNImagePicker.h"
#import "DNAsset.h"
#import "DNImagePickerHelper.h"

@interface DNBrowserCell () <UIScrollViewDelegate,DNTapDetectingImageViewDelegate>
@property (nonatomic, strong) UIScrollView *zoomingScrollView;
@property (nonatomic, strong) DNTapDetectingImageView *photoImageView;

@end

@implementation DNBrowserCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self zoomingScrollView];
        [self photoImageView];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.photoImageView.image = nil;
    [self.photoImageView removeFromSuperview];
    [self.zoomingScrollView removeFromSuperview];
    self.zoomingScrollView = nil;
    self.photoImageView = nil;
    self.photoBrowser = nil;
    self.asset = nil;
}

#pragma mark - set
- (void)setAsset:(DNAsset *)asset {
    if (_asset != asset) {
        _asset = asset;
        [self displayImage];
    }
}

// Get and display image
- (void)displayImage {
    self.zoomingScrollView.maximumZoomScale = 1;
    self.zoomingScrollView.minimumZoomScale = 1;
    self.zoomingScrollView.zoomScale = 1;
    self.zoomingScrollView.contentSize = CGSizeMake(0, 0);
    __weak typeof(self)weakSelf = self;
    [DNImagePickerHelper fetchImageWithAsset:self.asset targetSize:self.zoomingScrollView.size needHighQuality:YES imageResutHandler:^(UIImage * _Nonnull image) {
        if (!image) {
            return;
        }
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.photoImageView.image = image;
        strongSelf.photoImageView.hidden = NO;
        CGRect photoImageViewFrame;
        photoImageViewFrame.origin = CGPointZero;
        photoImageViewFrame.size = image.size;
        strongSelf.photoImageView.frame = photoImageViewFrame;
        strongSelf.zoomingScrollView.contentSize = photoImageViewFrame.size;
        
        // Set zoom to minimum zoom
        [strongSelf setMaxMinZoomScalesForCurrentBounds];
        [strongSelf setNeedsLayout];
    }];
}


#pragma mark - get
- (DNTapDetectingImageView *)photoImageView
{
    if (!_photoImageView) {
        _photoImageView = [[DNTapDetectingImageView alloc] initWithFrame:CGRectZero];
        _photoImageView.tapDelegate = self;
        _photoImageView.contentMode = UIViewContentModeCenter;
        _photoImageView.backgroundColor = [UIColor blackColor];
        [self.zoomingScrollView addSubview:_photoImageView];
    }
    return _photoImageView;
}

- (UIScrollView *)zoomingScrollView
{
    if (!_zoomingScrollView) {
        _zoomingScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width-20, self.frame.size.height)];
        _zoomingScrollView.delegate = self;
        _zoomingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleWidth;
        _zoomingScrollView.showsHorizontalScrollIndicator = NO;
        _zoomingScrollView.showsVerticalScrollIndicator = NO;
        _zoomingScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
            [self addSubview:_zoomingScrollView];
    }
    return _zoomingScrollView;
}

#pragma mark - Setup
- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.zoomingScrollView.minimumZoomScale;
    // Zoom image to fill if the aspect ratios are fairly similar
    CGSize boundsSize = self.zoomingScrollView.bounds.size;
    CGSize imageSize = self.photoImageView.image.size;
    CGFloat boundsAR = boundsSize.width / boundsSize.height;
    CGFloat imageAR = imageSize.width / imageSize.height;
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
    if (ABS(boundsAR - imageAR) < 0.17) {
        zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
        zoomScale = MIN(MAX(self.zoomingScrollView.minimumZoomScale, zoomScale), self.zoomingScrollView.maximumZoomScale);
        }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    // Reset
    self.zoomingScrollView.maximumZoomScale = 1;
    self.zoomingScrollView.minimumZoomScale = 1;
    self.zoomingScrollView.zoomScale = 1;
    
    // Bail if no image
    if (!_photoImageView.image) return;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Sizes
    CGSize boundsSize = self.zoomingScrollView.bounds.size;
    CGSize imageSize = _photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 1.5;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Image is smaller than screen so no zooming!
    if (xScale >= 1 && yScale >= 1) {
        minScale = 1.0;
    }
    
    // Set min/max zoom
    self.zoomingScrollView.maximumZoomScale = maxScale;
    self.zoomingScrollView.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomingScrollView.zoomScale = [self initialZoomScaleWithMinScale];
    
    // If we're zooming to fill then centralise
    if (self.zoomingScrollView.zoomScale != minScale) {
        // Centralise
        self.zoomingScrollView.contentOffset = CGPointMake((imageSize.width * self.zoomingScrollView.zoomScale - boundsSize.width) / 2.0,
                                         (imageSize.height * self.zoomingScrollView.zoomScale - boundsSize.height) / 2.0);
        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
        self.zoomingScrollView.scrollEnabled = NO;
    }
    
    // Layout
    [self setNeedsLayout];
    
}

#pragma mark - Layout

- (void)layoutSubviews {
    // Super
    [super layoutSubviews];
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.zoomingScrollView.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
        _photoImageView.frame = frameToCenter;
    
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.photoImageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.zoomingScrollView.scrollEnabled = YES; // reset
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection
- (void)handleSingleTap:(CGPoint)touchPoint {
    [self.photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:self.photoBrowser];
    // Zoom
    if (self.zoomingScrollView.zoomScale != self.zoomingScrollView.minimumZoomScale && self.zoomingScrollView.zoomScale != [self initialZoomScaleWithMinScale]) {
        
        // Zoom out
        [self.zoomingScrollView setZoomScale:self.zoomingScrollView.minimumZoomScale animated:YES];
        
    } else {
        
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.zoomingScrollView.maximumZoomScale + self.zoomingScrollView.minimumZoomScale) / 2);
        CGFloat xsize = self.zoomingScrollView.bounds.size.width / newZoomScale;
        CGFloat ysize = self.zoomingScrollView.bounds.size.height / newZoomScale;
        [self.zoomingScrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:imageView]];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

@end
