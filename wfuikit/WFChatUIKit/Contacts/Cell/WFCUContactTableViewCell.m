//
//  ContactTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUContactTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
#import "WFCUConfigManager.h"
#import "WFCUImage.h"

@interface WFCUContactTableViewCell ()
@property (nonatomic, strong)WFCCUserInfo *userInfo;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnlineState) name:kUserOnlineStateUpdated object:nil];
    
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
    if(userInfo.userId.length == 0) {
        userInfo = [[WFCCUserInfo alloc] init];
        userInfo.userId = userId;
    }
    [self updateUserInfo:userInfo];
}

- (void)updateOnlineState {
    [self updateUserInfo:_userInfo];
}

- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
    if(!userInfo) {
        return;
    }
    _userInfo = userInfo;
    
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    
    if (userInfo.friendAlias.length) {
        self.nameLabel.text = userInfo.friendAlias;
    } else if (self.groupAlias.length) {
        self.nameLabel.text = self.groupAlias;
    } else if(userInfo.displayName.length > 0) {
        self.nameLabel.text = userInfo.displayName;
    } else {
        self.nameLabel.text = [NSString stringWithFormat:@"user<%@>", userInfo.userId];
    }
    
    if ([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
        WFCCUserOnlineState *state = [[WFCCIMService sharedWFCIMService] getUserOnlineState:self.userId];
        BOOL online = NO;
        BOOL hasMobileSession = NO;
        long long mobileLastSeen = 0;
        if(state.clientStates.count) { //有设备在线
            if(state.customState.state != 4) { //没有设置为隐身
                for (WFCCClientState *cs in state.clientStates) {
                    if(cs.state == 0) {
                        online = YES;
                        break;
                    }
                    if(cs.state == 1 && (cs.platform == 1 || cs.platform == 2)) {
                        hasMobileSession = YES;
                        if(mobileLastSeen < cs.lastSeen) {
                            mobileLastSeen = cs.lastSeen;
                        }
                    }
                }
            }
        }
        self.onlineView.hidden = !(online || hasMobileSession);
        if(!online && hasMobileSession && mobileLastSeen > 0) {
            NSString *strSeenTime = nil;
            long long duration = [[[NSDate alloc] init] timeIntervalSince1970] - (mobileLastSeen/1000);
            int days = (int)(duration / 86400);
            if(days) {
                strSeenTime = [NSString stringWithFormat:@"%d天前", days];
            } else {
                int hours = (int)(duration/3600);
                if(hours) {
                    strSeenTime = [NSString stringWithFormat:@"%d时前", hours];
                } else {
                    int mins = (int)(duration/60);
                    if(mins) {
                        strSeenTime = [NSString stringWithFormat:@"%d分前", mins];
                    } else {
                        strSeenTime = [NSString stringWithFormat:@"不久前"];
                    }
                }
            }
            self.nameLabel.text = [NSString stringWithFormat:@"%@(%@)", self.nameLabel.text, strSeenTime];
        }
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

- (UIImageView *)onlineView {
    if([[WFCCIMService sharedWFCIMService] isEnableUserOnlineState]) {
        if (!_onlineView) {
            _onlineView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 48, 16, 24, 24)];;
            _onlineView.image = [WFCUImage imageNamed:@"ic_online"];
            [self.contentView addSubview:_onlineView];
        }
    }
    return _onlineView;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
