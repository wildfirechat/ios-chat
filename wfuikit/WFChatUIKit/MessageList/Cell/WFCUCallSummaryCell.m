//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUCallSummaryCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation WFCUCallSummaryCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(98, 30);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];

    CGFloat width = self.contentArea.bounds.size.width;
    
    self.infoLabel.text = WFCString(@"VOIPCall");
    self.infoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    
    if (model.message.direction == MessageDirection_Send) {
        self.infoLabel.frame = CGRectMake(width - 98, 0, 70, 30);
        self.modeImageView.frame = CGRectMake(width - 25, 3, 25, 25);
    } else {
        self.infoLabel.frame = CGRectMake(0, 0, 70, 30);
        self.modeImageView.frame = CGRectMake(70, 3, 25, 25);
    }
    if ([self.model.message.content isKindOfClass:[WFCCCallStartMessageContent class]]) {
        WFCCCallStartMessageContent *startContent = (WFCCCallStartMessageContent *)self.model.message.content;
        if (startContent.isAudioOnly) {
            self.modeImageView.image = [UIImage imageNamed:@"msg_audio_call"];
        } else {
            self.modeImageView.image = [UIImage imageNamed:@"msg_video_call"];
        }
    }
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.numberOfLines = 0;
        _infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont systemFontOfSize:14.f];
        _infoLabel.layer.masksToBounds = YES;
        _infoLabel.layer.cornerRadius = 5.f;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.textColor = [UIColor blackColor];
        _infoLabel.userInteractionEnabled = YES;
        
        [self.contentArea addSubview:_infoLabel];
    }
    return _infoLabel; 
}
- (UIImageView *)modeImageView {
    if (!_modeImageView) {
        _modeImageView = [[UIImageView alloc] init];
        [self.contentArea addSubview:_modeImageView];
    }
    return _modeImageView;
}
@end
