//
//  ConversationSettingMemberCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSettingMemberCell.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUConfigManager.h"


@interface WFCUConversationSettingMemberCell ()
@property(nonatomic, strong) NSObject *model;
@end

@implementation WFCUConversationSettingMemberCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.hidden = YES;
        
        CGFloat nameLabelHeight = 16;

        _nameLabel.frame =
        CGRectMake(0, self.bounds.size.height - nameLabelHeight,
                   self.bounds.size.width, nameLabelHeight);
        if (nameLabelHeight > 0) {
            _nameLabel.hidden = NO;
        } else {
            _nameLabel.hidden = YES;
        }
        
        [[self contentView] addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _headerImageView.autoresizingMask =
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headerImageView.clipsToBounds = YES;
        
        _headerImageView.layer.borderWidth = 1;
        _headerImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _headerImageView.layer.cornerRadius = 4;
        _headerImageView.layer.masksToBounds = YES;
        _headerImageView.backgroundColor = [UIColor clearColor];
        
        _headerImageView.layer.edgeAntialiasingMask =
        kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge |
        kCALayerTopEdge;
        
        
        CGFloat nameLabelHeight = 16;
        CGFloat insideMargin = 5;
        
        
        CGFloat minLength =
        MIN(self.bounds.size.width,
            self.bounds.size.height - nameLabelHeight - insideMargin);
        
        _headerImageView.frame = CGRectMake(
                                                (self.bounds.size.width - minLength) / 2, 0, minLength, minLength);

        
        [[self contentView] addSubview:_headerImageView];
    }
    return _headerImageView;
}

- (void)setModel:(NSObject *)model withType:(WFCCConversationType)type {
    self.contentView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    self.nameLabel.textColor = [WFCUConfigManager globalManager].textColor;
    
    self.model = model;
    
    WFCCUserInfo *userInfo;
    WFCCGroupMember *groupMember;
    WFCCChannelInfo *channelInfo;
    if (type == Group_Type) {
        groupMember = (WFCCGroupMember *)model;
        userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:groupMember.memberId inGroup:groupMember.groupId refresh:NO];
    } else if(type == Single_Type) {
        userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:(NSString *)model refresh:NO];
    } else if(type == Channel_Type) {
        channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:(NSString *)model refresh:NO];
    } else {
        return;
    }
    
    if (type == Channel_Type) {
        [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
        self.nameLabel.text = channelInfo.name;
    } else {
        [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
        
        if (userInfo.friendAlias.length) {
            self.nameLabel.text = userInfo.friendAlias;
        } else if(userInfo.groupAlias.length) {
            self.nameLabel.text = userInfo.groupAlias;
        } else if(userInfo.displayName.length) {
            self.nameLabel.text = userInfo.displayName;
        } else {
            self.nameLabel.text = nil;
        }
    }
    self.nameLabel.hidden = NO;
}

- (void)resetLayout:(CGFloat)nameLabelHeight
       insideMargin:(CGFloat)insideMargin {
}
@end
