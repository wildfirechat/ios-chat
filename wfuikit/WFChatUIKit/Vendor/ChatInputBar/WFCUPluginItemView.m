//
//  PluginItemView.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUPluginItemView.h"
#import "UIFont+YH.h"

@interface WFCUPluginItemView ()
@property (nonatomic, strong) UIButton *imageButton;
@end

@implementation WFCUPluginItemView
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image frame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView:title image:image];
    }
    return self;
}

- (void)setupView:(NSString *)title image:(UIImage *)image {
    UIView *myView = [UIView new];
    UIButton *imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [imageButton setImage:image forState:UIControlStateNormal];
    _imageButton = imageButton;
    myView.layer.cornerRadius = 5;
    
    [imageButton addTarget:self action:@selector(itemPlugined:) forControlEvents:UIControlEventTouchUpInside];
    imageButton.userInteractionEnabled = YES;
    
    [myView addSubview:imageButton];
    
    UILabel *label = [UILabel new];
    _titleLabel = label;
    [label setText:title];
    [label setTextColor:HEXCOLOR(0x6f7277)];
    [label setFont:[UIFont scaledSystemFontOfSize:11]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [myView addSubview:label];
    [self addSubview:myView];
    
    // add contraints
    [myView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[myView(75)]|"
                                                            options:kNilOptions
                                                            metrics:nil
                                                              views:NSDictionaryOfVariableBindings(myView)]];
    [self
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[myView]|"
                                                            options:kNilOptions
                                                            metrics:nil
                                                              views:NSDictionaryOfVariableBindings(myView)]];
    
    [self
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-7.5-[imageButton(60)]"
                                                            options:kNilOptions
                                                            metrics:nil
                                                              views:NSDictionaryOfVariableBindings(imageButton)]];
    
    [self
     addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                            options:kNilOptions
                                                            metrics:nil
                                                              views:NSDictionaryOfVariableBindings(label, myView)]];
    [self addConstraints:[NSLayoutConstraint
                                      constraintsWithVisualFormat:@"V:|[imageButton(50)]-5.5-[label]"
                                      options:kNilOptions
                                      metrics:nil
                                      views:NSDictionaryOfVariableBindings(label, imageButton)]];
}


- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    if (disabled) {
        self.alpha = 0.35;
        _imageButton.enabled = NO;
        _titleLabel.textColor = HEXCOLOR(0xbbbbbb);
    } else {
        self.alpha = 1.0;
        _imageButton.enabled = YES;
        _titleLabel.textColor = HEXCOLOR(0x6f7277);
    }
}

- (void)itemPlugined:(id)sender {
    if (self.disabled) {
        return;
    }
    self.onItemClicked();
}
@end
