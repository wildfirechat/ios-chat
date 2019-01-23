//
//  VoiceCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUVoiceCell.h"
#import <WFChatClient/WFCChatClient.h>

@interface WFCUVoiceCell ()
@property(nonatomic, strong) NSTimer *animationTimer;
@property(nonatomic) int animationIndex;
@end

@implementation WFCUVoiceCell
+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCSoundMessageContent *soundContent = (WFCCSoundMessageContent *)msgModel.message.content;
    long duration = soundContent.duration;
    return CGSizeMake(50 + 30 * (MIN(MAX(0, duration-5), 20)/20.0), 30);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    CGRect bounds = self.contentArea.bounds;
    if (model.message.direction == MessageDirection_Send) {
        self.voiceBtn.frame = CGRectMake(bounds.size.width - 30, 4, 22, 22);
        self.durationLabel.frame = CGRectMake(bounds.size.width - 48, 19, 18, 9);
        self.unplayedView.hidden = YES;
    } else {
        self.voiceBtn.frame = CGRectMake(4, 4, 22, 22);
        self.durationLabel.frame = CGRectMake(32, 19, 18, 9);
        
        if (model.message.status == Message_Status_Played) {
            self.unplayedView.hidden = YES;
        } else {
            self.unplayedView.hidden = NO;
            CGRect frame = [self.contentView convertRect:CGRectMake(self.contentArea.bounds.size.width + 10, 12, 10, 10) fromView:self.contentArea];
            self.unplayedView.frame = frame;
        }
    }
    WFCCSoundMessageContent *soundContent = (WFCCSoundMessageContent *)model.message.content;
    self.durationLabel.text = [NSString stringWithFormat:@"%ld''", soundContent.duration];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnimationTimer) name:kVoiceMessageStartPlaying object:@(model.message.messageId)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAnimationTimer) name:kVoiceMessagePlayStoped object:nil];
    if (model.voicePlaying) {
        [self startAnimationTimer];
    } else {
        [self stopAnimationTimer];
    }
}

- (UIView *)unplayedView {
    if (!_unplayedView) {
        _unplayedView = [[UIView alloc] init];
        _unplayedView.layer.cornerRadius = 5.f;
        _unplayedView.layer.masksToBounds = YES;
        _unplayedView.backgroundColor = [UIColor redColor];
        
        [self.contentView addSubview:_unplayedView];
    }
    return _unplayedView;
}

- (UIImageView *)voiceBtn {
    if (!_voiceBtn) {
        _voiceBtn = [[UIImageView alloc] init];
        [self.contentArea addSubview:_voiceBtn];
    }
    return _voiceBtn;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.font = [UIFont systemFontOfSize:9];
        [self.contentArea addSubview:_durationLabel];
    }
    return _durationLabel;
}

- (void)startAnimationTimer {
    [self stopAnimationTimer];
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                           target:self
                                                         selector:@selector(scheduleAnimation:)
                                                         userInfo:nil
                                                          repeats:YES];
    [self.animationTimer fire];
}


- (void)scheduleAnimation:(id)sender {
    NSString *_playingImg;
    
    if (MessageDirection_Send == self.model.message.direction) {
        _playingImg = [NSString stringWithFormat:@"sent_voice_%d", (self.animationIndex++ % 3) + 1];
    } else {
        _playingImg = [NSString stringWithFormat:@"received_voice_%d", (self.animationIndex++ % 3) + 1];
    }

    [self.voiceBtn setImage:[UIImage imageNamed:_playingImg]];
}

- (void)stopAnimationTimer {
    if (self.animationTimer && [self.animationTimer isValid]) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.animationIndex = 0;
    }
    
    if (self.model.message.direction == MessageDirection_Send) {
        [self.voiceBtn setImage:[UIImage imageNamed:@"sent_voice"]];
    } else {
        [self.voiceBtn setImage:[UIImage imageNamed:@"received_voice"]];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
