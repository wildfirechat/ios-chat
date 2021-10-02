//
//  WFCUConferenceMemberTableViewCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUPTTMemberCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>

@interface WFCUPTTMemberCell ()
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *extraLabel;

@end

@implementation WFCUPTTMemberCell

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)setMember:(WFCUConferenceMember *)member {
    _member = member;
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:member.userId refresh:NO];
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    NSString *title = userInfo.displayName;
    if(userInfo.friendAlias.length) {
        title = userInfo.friendAlias;
    }
    
    self.nameLabel.text = title;
    self.nameLabel.frame = CGRectMake(56, 8, [UIScreen mainScreen].bounds.size.width - 80-56, 18);
    if(member.isHost && member.isMe) {
        self.extraLabel.hidden = NO;
        self.extraLabel.text = @"(主持人，我)";
    } else if(member.isHost) {
        self.extraLabel.hidden = NO;
        self.extraLabel.text = @"(主持人)";
    } else if(member.isMe) {
        self.extraLabel.hidden = NO;
        self.extraLabel.text = @"(我)";
    } else {
        self.extraLabel.hidden = YES;
        self.nameLabel.frame = CGRectMake(56, 8, [UIScreen mainScreen].bounds.size.width - 80-56, 40);
    }
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
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 8, [UIScreen mainScreen].bounds.size.width - 80-56, 18)];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UILabel *)extraLabel {
    if (!_extraLabel) {
        _extraLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 32, [UIScreen mainScreen].bounds.size.width - 80-56, 12)];
        _extraLabel.textColor = [UIColor grayColor];
        _extraLabel.font = [UIFont systemFontOfSize:12];
        [self.contentView addSubview:_extraLabel];
    }
    return _extraLabel;
}
@end
