//
//  WFCUParticipantCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 Tom Lee. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUParticipantCollectionViewCell.h"
#import "SDWebImage.h"
#import "WFCUWaitingAnimationView.h"

@interface WFCUParticipantCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)WFCUWaitingAnimationView *stateLabel;

@property (nonatomic, strong)UIImageView *speakingView;
@end

@implementation WFCUParticipantCollectionViewCell
- (void)setUserInfo:(WFCCUserInfo *)userInfo callProfile:(WFAVParticipantProfile *)profile {
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];

    if (profile.state == kWFAVEngineStateIncomming
        || profile.state == kWFAVEngineStateOutgoing
        || profile.state == kWFAVEngineStateConnecting) {
        [self.stateLabel start];
        self.stateLabel.hidden = NO;
    } else {
        [self.stateLabel stop];
        if (profile.videoMuted) {
            self.stateLabel.hidden = NO;
            self.stateLabel.image = [UIImage imageNamed:@"disable_video"];
        } else {
            self.stateLabel.hidden = YES;
        }
    }
    _speakingView.hidden = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVolumeUpdated:) name:@"wfavVolumeUpdated" object:userInfo.userId];
    
}

- (void)onVolumeUpdated:(NSNotification *)notification {
    NSInteger volume = [notification.userInfo[@"volume"] integerValue];
    if (volume > 1000) {
        self.speakingView.hidden = NO;
        [self bringSubviewToFront:self.speakingView];
    } else {
        self.speakingView.hidden = YES;
    }
}


- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:self.bounds];

        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 2.f;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}


- (UIImageView *)speakingView {
    if (!_speakingView) {
        _speakingView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 20, 20, 20)];

        _speakingView.layer.masksToBounds = YES;
        _speakingView.layer.cornerRadius = 2.f;
        _speakingView.image = [UIImage imageNamed:@"speaking"];
        [self addSubview:_speakingView];
    }
    return _speakingView;
}

- (WFCUWaitingAnimationView *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[WFCUWaitingAnimationView alloc] initWithFrame:self.bounds];

        _stateLabel.animationImages = @[[UIImage imageNamed:@"connect_ani1"],[UIImage imageNamed:@"connect_ani2"],[UIImage imageNamed:@"connect_ani3"]];
        _stateLabel.animationDuration = 1;
        _stateLabel.animationRepeatCount = 200;
        _stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
        _stateLabel.hidden = YES;
        [self addSubview:_stateLabel];
    }
    return _stateLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
#endif
