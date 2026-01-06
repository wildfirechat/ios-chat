//
//  ForwardMessageCell.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUForwardMessageCell.h"
#import <SDWebImage/SDWebImage.h>
#import "WFCUImage.h"

@interface WFCUForwardMessageCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;
@end

@implementation WFCUForwardMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setConversation:(WFCCConversation *)conversation {
    _conversation = conversation;
    NSString *name;
    NSString *portrait;
    
    if (conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
        if (userInfo) {
            name = userInfo.displayName;
            portrait = userInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"%@<%@>", WFCString(@"User"), conversation.target];
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    } else if (conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if (groupInfo) {
            name = groupInfo.displayName;
            if (groupInfo.portrait.length) {
                [self.portrait sd_setImageWithURL:[NSURL URLWithString:[groupInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"group_default_portrait"]];
            } else {
                NSString *path = [WFCCUtilities getGroupGridPortrait:groupInfo.target width:80 generateIfNotExist:YES defaultUserPortrait:^UIImage *(NSString *userId) {
                    return [WFCUImage imageNamed:@"PersonalChat"];
                }];
                
                if (path) {
                    [self.portrait sd_setImageWithURL:[NSURL fileURLWithPath:path] placeholderImage:[WFCUImage imageNamed:@"group_default_portrait"]];
                }
            }
        } else {
            name = WFCString(@"GroupChat");
            [self.portrait setImage:[WFCUImage imageNamed:@"group_default_portrait"]];
        }
    } else if (conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo) {
            name = channelInfo.name;
            portrait = channelInfo.portrait;
        } else {
            name = WFCString(@"Channel");
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"channel_default_portrait"]];
    } else if (conversation.type == SecretChat_Type) {
        NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:conversation.target].userId;
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
        if (userInfo) {
            name = userInfo.displayName;
            portrait = userInfo.portrait;
        } else {
            name = [NSString stringWithFormat:@"%@<%@>", WFCString(@"User"), userId];
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[WFCUImage imageNamed:@"PersonalChat"]];
    }
    
    
    self.name.text = name;
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(40, 8, 40, 40)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(88, 16, 0, 24)];
        _name.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_name];

        // 确保在 layoutSubviews 中正确设置宽度
    }
    return _name;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.contentView.bounds;
    self.name.frame = CGRectMake(88, 16, bounds.size.width - 96, 24);
}

- (UIImageView *)checkboxView {
    if (!_checkboxView) {
        _checkboxView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 18, 20, 20)];
        _checkboxView.contentMode = UIViewContentModeScaleAspectFit;
        [self updateCheckboxImage];
        [self.contentView addSubview:_checkboxView];
    }
    return _checkboxView;
}

- (void)setIsChecked:(BOOL)isChecked {
    _isChecked = isChecked;
    [self updateCheckboxImage];
}

- (void)updateCheckboxImage {
    if (self.isChecked) {
        self.checkboxView.image = [WFCUImage imageNamed:@"multi_selected"];
    } else {
        self.checkboxView.image = [WFCUImage imageNamed:@"multi_unselected"];
    }
}

@end
