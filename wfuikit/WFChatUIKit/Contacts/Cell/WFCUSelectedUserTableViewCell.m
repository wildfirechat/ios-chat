//
//  WFCUSelectedUserTableViewCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUSelectedUserTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
@interface WFCUSelectedUserTableViewCell()


@end

@implementation WFCUSelectedUserTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCheckImage:(SelectedStatusType)selectedStatus {
    if (selectedStatus == Disable) {
        self.checkImageView.image = [UIImage imageNamed:@"multi_has_selected"];
    }
    
    if (selectedStatus == Checked) {
        self.checkImageView.image = [UIImage imageNamed:@"multi_selected"];
    }
    
    if (selectedStatus == Unchecked) {
        self.checkImageView.image = [UIImage imageNamed:@"multi_unselected"];
    }
}

- (void)setSelectedUserInfo:(WFCUSelectedUserInfo *)selectedUserInfo {
    _selectedUserInfo = selectedUserInfo;
    [self setCheckImage:selectedUserInfo.selectedStatus];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
       if (selectedUserInfo.friendAlias.length) {
           self.nameLabel.text = selectedUserInfo.friendAlias;
       } else {
           self.nameLabel.text = selectedUserInfo.displayName;
       }
}


- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 18, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 8, 40, 40)];
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if(!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(50 + 40 + 12, 19, [UIScreen mainScreen].bounds.size.width - (16 + 20 + 19 + 40 + 12) - 48, 16)];
        _nameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
        _nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

@end
