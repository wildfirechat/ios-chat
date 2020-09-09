//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConferenceInviteCell.h"
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

@interface WFCUConferenceInviteCell ()
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UILabel *infoLabel;

@property (nonatomic, strong)UIView *separateLine;
@property (nonatomic, strong)UILabel *hint;
@end

@implementation WFCUConferenceInviteCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width, 84);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    
    WFCCConferenceInviteMessageContent *content = (WFCCConferenceInviteMessageContent *)model.message.content;

    self.titleLabel.text = [NSString stringWithFormat:@"会议邀请:%@", content.title];
    if (content.startTime == 0 || content.startTime >= [[NSDate alloc] init].timeIntervalSince1970) {
        self.infoLabel.text = @"会议已经开始了，请尽快加入会议。";
    } else {
        self.infoLabel.text = @"会议还未开始，请准时参加。";
    }

    [self separateLine];
    [self hint];
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        CGRect bounds = self.contentArea.bounds;
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 30, bounds.size.width-16, 32)];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        
        _infoLabel.textColor = [UIColor grayColor];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:12.f];
        
        [self.contentArea addSubview:_infoLabel];
    }
    return _infoLabel; 
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        CGRect bounds = self.contentArea.bounds;
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, bounds.size.width - 16, 18)];
        _titleLabel.numberOfLines = 0;
        _titleLabel.font = [UIFont systemFontOfSize:14];
        
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
        
        
        [self.contentArea addSubview:_titleLabel];
    }
    return _titleLabel;
}


- (UIView *)separateLine {
    if (!_separateLine) {
        CGRect bounds = self.contentArea.bounds;
        _separateLine = [[UIView alloc] initWithFrame:CGRectMake(8, 64, bounds.size.width - 8 - 8, 1)];
        _separateLine.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        [self.contentArea addSubview:_separateLine];
    }
    return _separateLine;
}

- (UILabel *)hint {
    if (!_hint) {
        _hint = [[UILabel alloc] initWithFrame:CGRectMake(8, 68, 80, 16)];
        _hint.font = [UIFont systemFontOfSize:8];
        _hint.text = @"野火会议";
        _hint.textColor = [UIColor grayColor];
        [self.contentArea addSubview:_hint];
    }
    return _hint;
}
@end
