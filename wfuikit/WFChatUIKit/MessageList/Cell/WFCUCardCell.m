//
//  WFCUCardCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUCardCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>


#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@interface WFCUCardCell ()
@property (nonatomic, strong)UIImageView *cardPortrait;
@property (nonatomic, strong)UILabel *cardDisplayName;
@property (nonatomic, strong)UILabel *cardName;
@property (nonatomic, strong)UIView *cardSeparateLine;
@property (nonatomic, strong)UILabel *cardHint;
@end

@implementation WFCUCardCell

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    return CGSizeMake(width, 100);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCCardMessageContent *content = (WFCCCardMessageContent *)model.message.content;
    
    self.cardDisplayName.text = content.displayName;
    self.cardName.text = content.name;
    [self.cardPortrait sd_setImageWithURL:[NSURL URLWithString:content.portrait] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    
    [self cardSeparateLine];
    [self cardHint];
}

- (UIImageView *)cardPortrait {
    if (!_cardPortrait) {
        _cardPortrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 56, 56)];
        [self.contentArea addSubview:_cardPortrait];
    }
    return _cardPortrait;
}

- (UILabel *)cardDisplayName {
    if (!_cardDisplayName) {
        CGRect bounds = self.contentArea.bounds;
        _cardDisplayName = [[UILabel alloc] initWithFrame:CGRectMake(72, 10, bounds.size.width - 72 - 8, 24)];
        [self.contentArea addSubview:_cardDisplayName];
    }
    return _cardDisplayName;
}

- (UILabel *)cardName {
    if (!_cardName) {
        CGRect bounds = self.contentArea.bounds;
        _cardName = [[UILabel alloc] initWithFrame:CGRectMake(72, 40, bounds.size.width - 72 - 8, 18)];
        _cardName.font = [UIFont systemFontOfSize:14];
        _cardName.textColor = [UIColor grayColor];
        [self.contentArea addSubview:_cardName];
    }
    return _cardName;
}

- (UIView *)cardSeparateLine {
    if (!_cardSeparateLine) {
        CGRect bounds = self.contentArea.bounds;
        _cardSeparateLine = [[UIView alloc] initWithFrame:CGRectMake(8, 78, bounds.size.width - 8 - 8, 1)];
        _cardSeparateLine.backgroundColor = [UIColor grayColor];
        [self.contentArea addSubview:_cardSeparateLine];
    }
    return _cardSeparateLine;
}

- (UILabel *)cardHint {
    if (!_cardHint) {
        _cardHint = [[UILabel alloc] initWithFrame:CGRectMake(8, 84, 80, 12)];
        _cardHint.font = [UIFont systemFontOfSize:10];
        _cardHint.text = @"个人名片";
        _cardHint.textColor = [UIColor grayColor];
        [self.contentArea addSubview:_cardHint];
    }
    return _cardHint;
}
@end
