//
//  WFCUConferenceParticipantCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 WildFireChat. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUConferenceParticipantCollectionViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUWaitingAnimationView.h"
#import "WFCUImage.h"
#import "WFCUConferenceLabelView.h"

@interface WFCUConferenceParticipantCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)WFCUWaitingAnimationView *stateLabel;
@property(nonatomic, strong)NSString *userId;
@property (nonatomic, strong)WFCUConferenceLabelView *conferenceLabelView;
@property(nonatomic, strong)WFAVParticipantProfile *profile;
@end

@implementation WFCUConferenceParticipantCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.4];
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 3.f;
        self.layer.borderWidth = 1.f;
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
    return self;
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo callProfile:(WFAVParticipantProfile *)profile {
    self.profile = profile;
    self.userId = userInfo.userId;

    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    self.portraitView.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);

    if (profile.state == kWFAVEngineStateIncomming
        || profile.state == kWFAVEngineStateOutgoing
        || profile.state == kWFAVEngineStateConnecting) {
        [self.stateLabel start];
        self.stateLabel.hidden = NO;
    } else {
        [self.stateLabel stop];
        if (profile.videoMuted || profile.audience) {
            self.stateLabel.hidden = NO;
            self.stateLabel.image = [WFCUImage imageNamed:@"disable_video"];
        } else {
            self.stateLabel.hidden = YES;
        }
    }

    self.conferenceLabelView.name = userInfo.displayName;
    
    BOOL isVideoMuted = YES;
    BOOL isAudioMuted = YES;
    if ([WFAVEngineKit sharedEngineKit].currentSession.isConference) {
        if(!profile.audience) {
            isVideoMuted = profile.videoMuted;
            isAudioMuted = profile.audioMuted;
        }
    } else {
        isVideoMuted = NO;
        isAudioMuted = NO;
    }
    
    self.conferenceLabelView.isMuteVideo = isVideoMuted;
    self.conferenceLabelView.isMuteAudio = isAudioMuted;
    
    if(isAudioMuted) {
        self.layer.borderColor = [UIColor clearColor].CGColor;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVolumeUpdated:) name:@"wfavVolumeUpdated" object:nil];
    
}

- (void)addSubview:(UIView *)view {
    [super addSubview:view];
    [self bringSubviewToFront:self.conferenceLabelView];
}

- (void)onVolumeUpdated:(NSNotification *)notification {
    if([notification.object isEqual:self.userId]) {
        NSInteger volume = [notification.userInfo[@"volume"] integerValue];
        if (volume > 1000) {
            self.layer.borderColor = [UIColor greenColor].CGColor;
        } else {
            self.layer.borderColor = [UIColor clearColor].CGColor;
        }
        self.conferenceLabelView.volume = volume;
    }
}

- (WFCUConferenceLabelView *)conferenceLabelView {
    if(!_conferenceLabelView) {
        CGSize size = [WFCUConferenceLabelView sizeOffView];
        _conferenceLabelView = [[WFCUConferenceLabelView alloc] initWithFrame:CGRectMake(4, self.bounds.size.height - size.height - 4, size.width, size.height)];
        [self addSubview:_conferenceLabelView];
    }
    return _conferenceLabelView;
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _portraitView.center = self.center;
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 30;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (WFCUWaitingAnimationView *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[WFCUWaitingAnimationView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _stateLabel.center = self.center;
        _stateLabel.animationImages = @[[WFCUImage imageNamed:@"connect_ani1"],[WFCUImage imageNamed:@"connect_ani2"],[WFCUImage imageNamed:@"connect_ani3"]];
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
