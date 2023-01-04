//
//  WFCUSelectedUserTableViewCell.m
//  WFChatUIKit
//
//  Created by Zack Zhang on 2020/4/5.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUSelectedUserTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCUImage.h"
#import "WFCUOrganizationCache.h"
#import "WFCUEmployee.h"
#import "WFCUOrganization.h"
#import "WFCUOrgRelationship.h"
#import "WFCUOrganizationEx.h"
#import "WFCUConfigManager.h"
#import "WFCUEmployeeEx.h"

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
    if (selectedStatus == Disable_Checked) {
        self.checkImageView.image = [WFCUImage imageNamed:@"multi_has_selected"];
    }
    
    if (selectedStatus == Checked) {
        self.checkImageView.image = [WFCUImage imageNamed:@"multi_selected"];
    }
    
    if (selectedStatus == Unchecked) {
        self.checkImageView.image = [WFCUImage imageNamed:@"multi_unselected"];
    }
    
    if(selectedStatus == Disable_Unchecked) {
        self.checkImageView.image = [WFCUImage imageNamed:@"multi_unselected"];
    }
}

- (void)setSelectedObject:(WFCUSelectModel *)selectedUserInfo {
    _selectedObject = selectedUserInfo;
    [self setCheckImage:selectedUserInfo.selectedStatus];
    if(selectedUserInfo.userInfo) {
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        if (selectedUserInfo.userInfo.friendAlias.length) {
            self.nameLabel.text = selectedUserInfo.userInfo.friendAlias;
        } else {
            self.nameLabel.text = selectedUserInfo.userInfo.displayName;
        }
        _nextLevel.hidden = YES;
    } else if(selectedUserInfo.organization) {
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.organization.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"organization_icon"]];
        self.nameLabel.text = selectedUserInfo.organization.name;
        self.nextLevel.hidden = NO;
    } else if(selectedUserInfo.employee) {
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[selectedUserInfo.employee.portraitUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"employee"]];
        self.nameLabel.text = selectedUserInfo.employee.name;
        _nextLevel.hidden = YES;
    }
}

- (void)onNextLevel:(id)sender {
    if([self.delegate respondsToSelector:@selector(didTapNextLevel:)]) {
        [self.delegate didTapNextLevel:self.selectedObject];
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

- (UIButton *)nextLevel {
    if(!_nextLevel) {
        _nextLevel = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 80, 19, 80, 16)];
        [_nextLevel setTitle:@"下级" forState:UIControlStateNormal];
        [_nextLevel setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _nextLevel.titleLabel.font = [UIFont systemFontOfSize:12];
        [_nextLevel addTarget:self action:@selector(onNextLevel:) forControlEvents:UIControlEventTouchDown];
        [self.contentView addSubview:_nextLevel];
    }
    return _nextLevel;
}

@end
