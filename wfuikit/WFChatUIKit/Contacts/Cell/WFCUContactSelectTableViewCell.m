//
//  ContactSelectTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/25.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactSelectTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"

@interface WFCUContactSelectTableViewCell()
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@end

@implementation WFCUContactSelectTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 44, 18, 20, 20)];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 40, 40)];
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if(!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 19, [UIScreen mainScreen].bounds.size.width - 56 - 48, 16)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}
- (void)setDisabled:(BOOL)disabled {
    _disabled = disabled;
    if (disabled) {
        [self.checkImageView setAlpha:0.5];
    } else {
        [self.checkImageView setAlpha:1.f];
    }
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    if (self.multiSelect) {
        if (checked) {
            self.checkImageView.image = [UIImage imageNamed:@"multi_selected"];
        } else {
            self.checkImageView.image = [UIImage imageNamed:@"multi_unselected"];
        }
    } else {
        if (checked) {
            self.checkImageView.image = [UIImage imageNamed:@"single_selected"];
        } else {
            self.checkImageView.image = [UIImage imageNamed:@"single_unselected"];
        }
    }
}
- (void)setMultiSelect:(BOOL)multiSelect {
    _multiSelect = multiSelect;
}

- (void)setFriendUid:(NSString *)friendUid {
    _friendUid = friendUid;
    WFCCUserInfo *friendInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:friendUid refresh:NO];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[friendInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    if (friendInfo.friendAlias.length) {
        self.nameLabel.text = friendInfo.friendAlias;
    } else {
        self.nameLabel.text = friendInfo.displayName;
    }
}
@end
