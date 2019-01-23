//
//  VoiceCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/9.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMediaMessageCell.h"

#define kVoiceMessageStartPlaying @"kVoiceMessageStartPlaying"
#define kVoiceMessagePlayStoped @"kVoiceMessagePlayStoped"


@interface WFCUVoiceCell : WFCUMediaMessageCell
@property (nonatomic, strong)UIImageView *voiceBtn;
@property (nonatomic, strong)UILabel *durationLabel;
@property (nonatomic, strong)UIView *unplayedView;
@end
