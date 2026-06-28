//
//  ContactSelectTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/25.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactSelectTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "WFCUConfigManager.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCUImage.h"


@interface WFCUContactSelectTableViewCell()
@property(nonatomic, strong)UIImageView *checkImageView;
@property(nonatomic, strong)UIImageView *portraitView;
@end

@implementation WFCUContactSelectTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat portraitSize = 40 + ([WFCUConfigManager globalManager].fontScale - 1.0) * 4;
    self.checkImageView.frame = CGRectMake(16, (self.frame.size.height - 20) / 2.0, 20, 20);
    self.portraitView.frame = CGRectMake(50, (self.frame.size.height - portraitSize) / 2.0, portraitSize, portraitSize);
    CGFloat labelHeight = MAX(16, [WFCUConfigManager scaledSize:16]);
    self.nameLabel.frame = CGRectMake(50 + portraitSize + 12, (self.frame.size.height - labelHeight) / 2.0, [UIScreen mainScreen].bounds.size.width - (16 + 20 + 19 + portraitSize + 12) - 48, labelHeight);
}

- (UIImageView *)checkImageView {
    if (!_checkImageView) {
        _checkImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_checkImageView];
    }
    return _checkImageView;
}
- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if(!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:16];
               _nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
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
            self.checkImageView.image = [WFCUImage imageNamed:@"multi_selected"];
        } else {
            self.checkImageView.image = [WFCUImage imageNamed:@"multi_unselected"];
        }
    } else {
        if (checked) {
            self.checkImageView.image = [WFCUImage imageNamed:@"single_selected"];
        } else {
            self.checkImageView.image = [WFCUImage imageNamed:@"single_unselected"];
        }
    }
}
- (void)setMultiSelect:(BOOL)multiSelect {
    _multiSelect = multiSelect;
}

- (void)setFriendUid:(NSString *)friendUid {
    _friendUid = friendUid;
    self.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
    WFCCUserInfo *friendInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:friendUid refresh:NO];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[friendInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    if (friendInfo.friendAlias.length) {
        self.nameLabel.text = friendInfo.friendAlias;
    } else {
        self.nameLabel.text = friendInfo.displayName;
    }
    if([WFCCUtilities isExternalTarget:friendUid]) {
        NSString *domainId = [WFCCUtilities getExternalDomain:friendUid];
        self.nameLabel.attributedText = [WFCCUtilities getExternal:domainId withName:self.nameLabel.text withColor:[WFCUConfigManager globalManager].externalNameColor withSize:12];
    }
}
@end
