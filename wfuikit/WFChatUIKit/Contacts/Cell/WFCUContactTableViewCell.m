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
        if (self.isBig) {
            _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 52, 52)];
        } else {
            _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 36, 36)];
        }
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 3.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        if (self.isBig) {
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 24, [UIScreen mainScreen].bounds.size.width - 64, 20)];
            _nameLabel.font = [UIFont systemFontOfSize:20];
        } else {
            _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 19, [UIScreen mainScreen].bounds.size.width - 64, 16)];
            _nameLabel.font = [UIFont systemFontOfSize:16];
        }
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
