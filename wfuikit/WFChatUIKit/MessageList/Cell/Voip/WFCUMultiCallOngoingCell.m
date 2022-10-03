//
//  WFCUMultiCallOngoingCell.m
//  WFChatUIKit
//
//  Created by Rain on 2022/5/8.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUMultiCallOngoingCell.h"

@implementation WFCUMultiCallOngoingCell

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
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(UILabel *)callHintLabel {
    if(!_callHintLabel) {
        _callHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, [UIScreen mainScreen].bounds.size.width-16, 20)];
        [self.contentView addSubview:_callHintLabel];
    }
    return _callHintLabel;
}
@end
