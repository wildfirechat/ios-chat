//
//  GroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUGroupTableViewCell.h"
#import "SDWebImage.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
@interface WFCUGroupTableViewCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;

@end

@implementation WFCUGroupTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _portrait.frame = CGRectMake(18, (self.frame.size.height - 40) / 2.0, 40, 40);
    _name.frame = CGRectMake(18 + 40 + 9, (self.frame.size.height - 17) / 2.0, [UIScreen mainScreen].bounds.size.width - (18 + 40 + 9), 17);
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [UIImageView new];
        _portrait.layer.cornerRadius = 4.0f;
        _portrait.layer.masksToBounds = YES;
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [UILabel new];
        _name.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        _name.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:17];
        [self.contentView addSubview:_name];
    }
    return _name;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setGroupInfo:(WFCCGroupInfo *)groupInfo {
    _groupInfo = groupInfo;
    if (groupInfo.name.length == 0) {
        self.name.text = WFCString(@"GroupChat");
    } else {
        self.name.text = [NSString stringWithFormat:@"%@(%d)", groupInfo.name, (int)groupInfo.memberCount];
    }
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
}
@end
