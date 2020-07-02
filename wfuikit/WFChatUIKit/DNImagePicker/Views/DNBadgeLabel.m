//
//  DNBadgeLabel.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/27.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNBadgeLabel.h"
#import "UIColor+Hex.h"
#import "UIView+DNImagePicker.h"

@interface DNBadgeLabel ()
@property (nonatomic, strong) UIView *backGroudView;
@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation DNBadgeLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupViews];
        self.hidden = YES;
    }
    return self;
}

- (void)setupViews {
    _backGroudView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _backGroudView.backgroundColor = [UIColor dn_hexStringToColor:@"#1FB823"];
    _backGroudView.layer.cornerRadius = 10;
    [self addSubview:_backGroudView];
    
    _badgeLabel = [[UILabel alloc] initWithFrame:_backGroudView.frame];
    _badgeLabel.backgroundColor = [UIColor clearColor];
    _badgeLabel.textColor = [UIColor whiteColor];
    _badgeLabel.font = [UIFont systemFontOfSize:16.0f];
    _badgeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_badgeLabel];
    
    _badgeLabel.userInteractionEnabled = YES;
    _backGroudView.userInteractionEnabled = YES;
    self.userInteractionEnabled = YES;
}

- (void)setTitle:(NSString *)title {
    CGRect rect = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingTruncatesLastVisibleLine attributes:nil context:nil];
    self.frame = CGRectMake(self.left, self.top, (rect.size.width + 9) > 20?(rect.size.width + 9):20, 20);
    self.backGroudView.width = self.width;
    self.backGroudView.height = self.height;
    self.badgeLabel.width = self.width;
    self.badgeLabel.height = self.height;
    self.badgeLabel.text = title;
    
    if (title.integerValue > 0) {
        [self show];
        self.backGroudView.transform =CGAffineTransformMakeScale(0, 0);
        [UIView animateWithDuration:0.2 animations:^{
            self.backGroudView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.1 animations:^{
                                 self.backGroudView.transform = CGAffineTransformMakeScale(1.0, 1.0);
                             }];
                         }];

    } else {
        [self hide];
    }
}

- (void)show {
    self.hidden = NO;
}

- (void)hide {
    self.hidden = YES;
}
@end
