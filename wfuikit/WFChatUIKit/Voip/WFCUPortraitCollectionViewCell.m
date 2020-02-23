//
//  WFCUPortraitCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 Tom Lee. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUPortraitCollectionViewCell.h"
#import "SDWebImage.h"

@interface WFCUPortraitCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong)UIImageView *stateLabel;
@end

@implementation WFCUPortraitCollectionViewCell

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    self.nameLabel.text = userInfo.displayName;
}

-(void)setProfile:(WFAVParticipantProfile *)profile {
    _profile = profile;
    if (profile.state == kWFAVEngineStateConnected || profile.state == kWFAVEngineStateIdle) {
        [self.stateLabel stopAnimating];
        self.stateLabel.hidden = YES;
    } else {
        [self.stateLabel startAnimating];
        self.stateLabel.hidden = NO;
    }
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize, self.itemSize)];

        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 2.f;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.itemSize, self.itemSize, self.labelSize)];
        _nameLabel.font = [UIFont systemFontOfSize:self.labelSize - 4];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIImageView *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize, self.itemSize)];
        
        _stateLabel.animationImages = @[[UIImage imageNamed:@"connect_ani1"],[UIImage imageNamed:@"connect_ani2"],[UIImage imageNamed:@"connect_ani3"]];
        _stateLabel.animationDuration = 1.f;
        _stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        [self addSubview:_stateLabel];
    }
    return _stateLabel;
}
@end
#endif
