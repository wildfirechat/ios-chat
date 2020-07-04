//
//  DNSendButton.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/24.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNSendButton.h"
#import "UIView+DNImagePicker.h"
#import "UIColor+Hex.h"
#import "WFCUConfigManager.h"

#define kSendButtonFont  [UIFont systemFontOfSize:15]
static NSString *const dnSendButtonTintNormalColor = @"#1FB823";
//static NSString *const dnSendButtonTintAbnormalColor = @"#C9DCCA";
static NSString *const dnSendButtonTintAbnormalColor = @"#C9EFCA";

static CGFloat const kSendButtonTextWitdh = 38.0f;

@interface DNSendButton ()
@property (nonatomic, strong) UILabel *badgeValueLabel;
@property (nonatomic, strong) UIView *backGroudView;
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation DNSendButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.left = 0;
        self.right = 0;
        self.top = 0;
        self.bottom = 0;
        self.width = 58;
        self.height = 26;
        [self setupViews];
        self.badgeValue = @"0";
    }
    return self;
}

- (void)setupViews
{
    _backGroudView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _backGroudView.centerY = self.centerY;
    _backGroudView.backgroundColor = [UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9];
    _backGroudView.layer.cornerRadius = _backGroudView.height/2;
    [self addSubview:_backGroudView];
    
    _badgeValueLabel = [[UILabel alloc] initWithFrame:_backGroudView.frame];
    _badgeValueLabel.backgroundColor = [UIColor clearColor];
    _badgeValueLabel.textColor = [UIColor whiteColor];
    _badgeValueLabel.font = [UIFont systemFontOfSize:15.0f];
    _badgeValueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_badgeValueLabel];
    
    _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendButton.frame = CGRectMake(0, 0, self.width, self.height);
    [_sendButton setTitle:WFCString(@"send")
                 forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor colorWithRed:0.1 green:0.27 blue:0.9 alpha:0.9] forState:UIControlStateNormal];
    [_sendButton setTitleColor:[UIColor colorWithRed:0.03 green:0.09 blue:0.3 alpha:0.9] forState:UIControlStateHighlighted];
    [_sendButton setTitleColor:[UIColor colorWithRed:0.03 green:0.09 blue:0.3 alpha:0.9] forState:UIControlStateDisabled];
    _sendButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    _sendButton.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
    _sendButton.backgroundColor = [UIColor clearColor];
    [self addSubview:_sendButton];
}

- (void)setBadgeValue:(NSString *)badgeValue
{
    CGRect rect = [badgeValue boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:kSendButtonFont} context:nil];
    self.badgeValueLabel.frame = CGRectMake(self.badgeValueLabel.left, self.badgeValueLabel.top, (rect.size.width + 9) > 20?(rect.size.width + 9):20, 20);
    self.backGroudView.width = self.badgeValueLabel.width;
    self.backGroudView.height = self.badgeValueLabel.height;
    
    self.sendButton.width = self.badgeValueLabel.width + kSendButtonTextWitdh;
    self.width = self.sendButton.width;
    
    self.badgeValueLabel.text = badgeValue;
    
    if (badgeValue.integerValue > 0) {
        [self showBadgeValue];
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
        [self hideBadgeValue];
    }
}

- (void)showBadgeValue
{
    self.badgeValueLabel.hidden = NO;
    self.backGroudView.hidden = NO;
}

- (void)hideBadgeValue
{
    self.badgeValueLabel.hidden = YES;
    self.backGroudView.hidden = YES;
    self.sendButton.adjustsImageWhenDisabled = YES;
}


- (void)addTaget:(id)target action:(SEL)action
{
    [self.sendButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end
