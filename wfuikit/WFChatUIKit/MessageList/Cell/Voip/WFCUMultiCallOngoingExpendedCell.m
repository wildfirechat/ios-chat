//
//  WFCUMultiCallOngoingExpendedCell.m
//  WFChatUIKit
//
//  Created by Rain on 2022/5/8.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUMultiCallOngoingExpendedCell.h"

@implementation WFCUMultiCallOngoingExpendedCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        [self.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
        }];
        self.backgroundColor = [UIColor colorWithRed:0.5 green:0.9 blue:0.5 alpha:0.5];
        [self joinButton];
        [self cancelButton];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    self.callHintLabel.frame = CGRectMake(16, 4, width - 16, 20);
    self.joinButton.frame = CGRectMake(width/2 - 60 - 40, 28, 60, 24);
    self.cancelButton.frame = CGRectMake(width/2 + 40, 28, 60, 24);
}

-(UILabel *)callHintLabel {
    if(!_callHintLabel) {
        _callHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, 0, 20)];
        [self.contentView addSubview:_callHintLabel];
    }
    return _callHintLabel;
}

-(UIButton *)joinButton {
    if(!_joinButton) {
        _joinButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 28, 60, 24)];
        [_joinButton setTitle:WFCString(@"Join") forState:UIControlStateNormal];
        [_joinButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_joinButton addTarget:self action:@selector(onJoinButton) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_joinButton];
    }
    return _joinButton;
}

-(UIButton *)cancelButton {
    if(!_cancelButton) {
        _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 28, 60, 24)];
        [_cancelButton setTitle:WFCString(@"Cancel") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(onCancelButton) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_cancelButton];
    }
    return _cancelButton;
}

- (void)onJoinButton {
    if([self.delegate respondsToSelector:@selector(didJoinButtonPressed)]) {
        [self.delegate didJoinButtonPressed];
    }
}

- (void)onCancelButton {
    if([self.delegate respondsToSelector:@selector(didCancelButtonPressed)]) {
        [self.delegate didCancelButtonPressed];
    }
}
@end
