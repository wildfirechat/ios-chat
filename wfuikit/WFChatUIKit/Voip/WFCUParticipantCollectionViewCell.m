//
//  WFCUParticipantCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUParticipantCollectionViewCell.h"
#import "SDWebImage.h"

@interface WFCUParticipantCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *stateLabel;
@end

@implementation WFCUParticipantCollectionViewCell
- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
}

- (void)setState:(WFAVEngineState)state {
    _state = state;
    if (state == kWFAVEngineStateIncomming) {
        self.stateLabel.hidden = NO;
        self.stateLabel.text = @"连接中";
    } else {
        self.stateLabel.hidden = YES;
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

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _stateLabel.font = [UIFont systemFontOfSize:12];
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        [self addSubview:_stateLabel];
    }
    return _stateLabel;
}
@end
