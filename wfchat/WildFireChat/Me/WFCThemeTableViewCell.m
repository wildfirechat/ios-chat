//
//  WFCThemeTableViewCell.m
//  WildFireChat
//
//  Created by dali on 2020/4/11.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCThemeTableViewCell.h"

@interface WFCThemeTableViewCell ()
@property(nonatomic, strong)UIImageView *checkImageView;
@end

@implementation WFCThemeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 44, 18, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}


- (void)setChecked:(BOOL)checked {
    _checked = checked;
    if (checked) {
        self.checkImageView.image = [UIImage imageNamed:@"single_selected"];
    } else {
        self.checkImageView.image = [UIImage imageNamed:@"single_unselected"];
    }
}
@end
