//
//  ForwardMessageCell.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/9/27.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCUForwardMessageCell.h"
#import "SDWebImage.h"


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
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    } else if (conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if (groupInfo) {
            name = groupInfo.name;
            portrait = groupInfo.portrait;
        } else {
            name = WFCString(@"GroupChat");
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
    } else if (conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo) {
            name = channelInfo.name;
            portrait = channelInfo.portrait;
        } else {
            name = WFCString(@"Channel");
        }
        [self.portrait sd_setImageWithURL:[NSURL URLWithString:[portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"channel_default_portrait"]];
    }
    
    
    self.name.text = name;
}

- (UIImageView *)portrait {
    if (!_portrait) {
        _portrait = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 40, 40)];
        [self.contentView addSubview:_portrait];
    }
    return _portrait;
}

- (UILabel *)name {
    if (!_name) {
        _name = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, [UIScreen mainScreen].bounds.size.width - 64, 24)];
        [self.contentView addSubview:_name];
    }
    return _name;
}

@end
