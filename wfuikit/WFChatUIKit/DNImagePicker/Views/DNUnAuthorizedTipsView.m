//
//  UnAuthorizedTipsView.m
//  ImagePicker
//
//  Created by DingXiao on 15/3/18.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNUnAuthorizedTipsView.h"

@implementation DNUnAuthorizedTipsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self imageView];
        [self label];
        [self addContentConstraints];
    }
    return self;
}

- (void)addContentConstraints {
    NSDictionary *imageViewMetric = @{@"imageLength":@130,@"labelHeight":@60};
    NSString *vflV = @"V:|-120-[_imageView(imageLength)]-30-[_label(<=labelHeight@750)]";
    NSString *vflH = @"H:|-33-[_label]-33-|";
    NSArray *contstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:vflV options:0 metrics:imageViewMetric views:NSDictionaryOfVariableBindings(_imageView,_label)];
    NSArray *contstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:vflH options:0 metrics:imageViewMetric views:NSDictionaryOfVariableBindings(_label)];
    NSLayoutConstraint *imageViewContstraintsCenterX = [NSLayoutConstraint
                                                        constraintWithItem:self.imageView
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                        attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0f
                                                        constant:0];
    NSLayoutConstraint *imageViewConstraintsWidth = [NSLayoutConstraint
                                                     constraintWithItem:self.imageView
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                     toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                     multiplier:0
                                                     constant:130.0f];
    [self addConstraints:@[imageViewConstraintsWidth,imageViewContstraintsCenterX]];
    [self addConstraints:contstraintsV];
    [self addConstraints:contstraintsH];
}

#pragma mark - getter
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.image = [UIImage imageNamed:@"image_unAuthorized"];
        [_imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [UILabel new];
        [_label setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSString *text = WFCString(@"UnAuthorizedTip");
        NSDictionary* infoDict =[[NSBundle mainBundle] infoDictionary];
        NSString*appName =[infoDict objectForKey:@"CFBundleDisplayName"]
        ;
        NSString *tipsString = [NSString stringWithFormat:text,appName];
        _label.text = tipsString;
        _label.textColor = [UIColor blackColor];
        _label.font = [UIFont systemFontOfSize:14.0f];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 0;
        _label.backgroundColor = [UIColor clearColor];
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:_label];
    }
    return _label;
}

@end
