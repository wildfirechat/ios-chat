//
//  ContactTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCUConfigManager.h"

@interface WFCUContactTableViewCell ()

@end

@implementation WFCUContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.isBig) {
          _portraitView.frame = CGRectMake(8, (self.frame.size.height - 52) / 2.0, 52, 52);
        _nameLabel.frame = CGRectMake(72, (self.frame.size.height - 20) / 2.0, [UIScreen mainScreen].bounds.size.width - 64, 20);
        _nameLabel.font = [UIFont systemFontOfSize:20];
      } else {
          _portraitView.frame = CGRectMake(16, (self.frame.size.height - 40) / 2.0, 40, 40);
          _nameLabel.frame = CGRectMake(16 + 40 + 11, (self.frame.size.height - 17) / 2.0, [UIScreen mainScreen].bounds.size.width - (16 + 40 + 11), 17);
            _nameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:16];
      }
}
- (void)onUserInfoUpdated:(NSNotification *)notification {
    WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
    if ([self.userId isEqualToString:userInfo.userId]) {
        [self updateUserInfo:userInfo];
    }
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:userId];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    if(userInfo.userId.length == 0) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    [self updateUserInfo:userInfo];
}

- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    
    if (userInfo.friendAlias.length) {
        self.nameLabel.text = userInfo.friendAlias;
    } else if (self.groupAlias.length) {
        self.nameLabel.text = self.groupAlias;
    } else if(userInfo.displayName.length > 0) {
        self.nameLabel.text = userInfo.displayName;
    } else {
        self.nameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [UIImageView new];
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        _nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
