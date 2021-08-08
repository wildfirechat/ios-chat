//
//  WFCUConferenceMemberTableViewCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUConferenceMemberTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>

@interface WFCUConferenceMemberTableViewCell ()
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *extraLabel;
@property(nonatomic, strong)UIImageView *audioImageView;
@property(nonatomic, strong)UIImageView *videoImageView;

@end

@implementation WFCUConferenceMemberTableViewCell

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
    if(member.isAudience) {
        self.audioImageView.hidden = YES;
        self.videoImageView.hidden = YES;
    } else {
        if(member.isAudioOnly) {
            self.audioImageView.hidden = NO;
            self.videoImageView.hidden = YES;
            self.audioImageView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 40, 12, 24, 24);
        } else {
            self.audioImageView.hidden = NO;
            self.videoImageView.hidden = NO;
            self.audioImageView.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 72, 12, 24, 24);
        }
        
        if(member.isAudioEnabled) {
            self.audioImageView.image = [UIImage imageNamed:@"conference_audio"];
        } else {
            self.audioImageView.image = [UIImage imageNamed:@"conference_audio_mute_hover"];
        }
        if(member.isVideoEnabled) {
            self.videoImageView.image = [UIImage imageNamed:@"conference_video"];
        } else {
            self.videoImageView.image = [UIImage imageNamed:@"conference_video_mute_hover"];
        }
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
- (UIImageView *)videoImageView {
    if(!_videoImageView) {
        _videoImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 40, 12, 24, 24)];
        [self.contentView addSubview:_videoImageView];
    }
    return _videoImageView;
}

- (UIImageView *)audioImageView {
    if(!_audioImageView) {
        _audioImageView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 72, 12, 24, 24)];
        [self.contentView addSubview:_audioImageView];
    }
    return _audioImageView;
}

@end
