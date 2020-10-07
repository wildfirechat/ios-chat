//
//  MeTableViewCell.m
//  WildFireChat
//
//  Created by WF Chat on 2018/10/2.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCMeTableViewHeaderViewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCMeTableViewHeaderViewCell ()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *displayName;
@property (strong, nonatomic) UILabel *userName;
@end

@implementation WFCMeTableViewHeaderViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(16, 64, 60, 60)];
        _portrait.layer.cornerRadius = 10.0;
        _portrait.layer.masksToBounds = YES;
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}


- (UILabel *)displayName {
    if (!_displayName) {
        _displayName = [[UILabel alloc] initWithFrame:CGRectMake(16 + 60 + 20, 64, [UIScreen mainScreen].bounds.size.width - 64, 32)];
        [_displayName setFont:[UIFont pingFangSCWithWeight:FontWeightStyleSemibold size:20]];
        _displayName.textColor = [WFCUConfigManager globalManager].naviTextColor;
        [self.contentView addSubview:_displayName];
    }
    return _displayName;
}

- (UILabel *)userName {
    if (!_userName) {
        _userName = [[UILabel alloc] initWithFrame:CGRectMake(16 + 60 + 20, 64 + 32 + 8, [UIScreen mainScreen].bounds.size.width - 128, 14)];
        [_userName setFont:[UIFont systemFontOfSize:14]];
        _userName.textColor = [WFCUConfigManager globalManager].naviTextColor;
        [self.contentView addSubview:_userName];
    }
    return _userName;
}

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:self.userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    self.displayName.text = self.userInfo.displayName;
    self.userName.text = [NSString stringWithFormat:@"野火号:%@", self.userInfo.name];
}
@end
