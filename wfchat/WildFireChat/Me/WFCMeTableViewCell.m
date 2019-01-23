//
//  MeTableViewCell.m
//  WildFireChat
//
//  Created by WF Chat on 2018/10/2.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCMeTableViewCell.h"
#import "SDWebImage.h"


@interface WFCMeTableViewCell ()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *displayName;
@end

@implementation WFCMeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 52, 52)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}


- (UILabel *)displayName {
    if (!_displayName) {
        _displayName = [[UILabel alloc] initWithFrame:CGRectMake(72, 8, [UIScreen mainScreen].bounds.size.width - 64, 52)];
        [_displayName setFont:[UIFont systemFontOfSize:18]];
        [self.contentView addSubview:_displayName];
    }
    return _displayName;
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:self.userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    self.displayName.text = self.userInfo.displayName;
}
@end
