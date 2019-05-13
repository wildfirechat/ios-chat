//
//  ConversationTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationTableViewCell.h"
#import "WFCUUtilities.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"


@implementation WFCUConversationTableViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}
  
- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
  [self.potraitView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
  
    if (userInfo.friendAlias.length) {
        self.targetView.text = userInfo.friendAlias;
    } else if(userInfo.displayName.length > 0) {
        self.targetView.text = userInfo.displayName;
    } else {
        self.targetView.text = [NSString stringWithFormat:@"user<%@>", self.info.conversation.target];
    }
}

- (void)updateChannelInfo:(WFCCChannelInfo *)channelInfo {
    [self.potraitView sd_setImageWithURL:[NSURL URLWithString:channelInfo.portrait] placeholderImage:[UIImage imageNamed:@"channel_default_portrait"]];
    
    if(channelInfo.name.length > 0) {
        self.targetView.text = channelInfo.name;
    } else {
        self.targetView.text = [NSString stringWithFormat:@"Channel<%@>", self.info.conversation.target];
    }
}

- (void)updateGroupInfo:(WFCCGroupInfo *)groupInfo {
  [self.potraitView sd_setImageWithURL:[NSURL URLWithString:groupInfo.portrait] placeholderImage:[UIImage imageNamed:@"group_default_portrait"]];
  
  if(groupInfo.name.length > 0) {
    self.targetView.text = groupInfo.name;
  } else {
    self.targetView.text = [NSString stringWithFormat:@"group<%@>", self.info.conversation.target];
  }
}

- (void)setSearchInfo:(WFCCConversationSearchInfo *)searchInfo {
    _searchInfo = searchInfo;
    self.bubbleView.hidden = YES;
    self.timeView.hidden = YES;
    [self update:searchInfo.conversation];
    if (searchInfo.marchedCount > 1) {
        self.digestView.text = [NSString stringWithFormat:@"%d条记录", searchInfo.marchedCount];
    } else {
        NSString *strContent = searchInfo.marchedMessage.digest;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strContent];
        NSRange range = [strContent rangeOfString:searchInfo.keyword options:NSCaseInsensitiveSearch];
        [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
        self.digestView.attributedText = attrStr;
    }
    
}

- (void)setInfo:(WFCCConversationInfo *)info {
    _info = info;
    if (info.unreadCount.unread == 0) {
        self.bubbleView.hidden = YES;
    } else {
        self.bubbleView.hidden = NO;
        if (info.isSilent) {
            self.bubbleView.isShowNotificationNumber = NO;
        } else {
            self.bubbleView.isShowNotificationNumber = YES;
        }
        [self.bubbleView setBubbleTipNumber:info.unreadCount.unread];
    }
    
    if (info.isSilent) {
        self.silentView.hidden = NO;
    } else {
        _silentView.hidden = YES;
    }
  
    [self update:info.conversation];
    self.timeView.hidden = NO;
    self.timeView.text = [WFCUUtilities formatTimeLabel:info.timestamp];
    if (info.isTop) {
        [self.contentView setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f]];
    } else {
        [self.contentView setBackgroundColor:[UIColor whiteColor]];
    }
    
    if (info.lastMessage && info.lastMessage.direction == MessageDirection_Send) {
        if (info.lastMessage.status == Message_Status_Sending) {
            self.statusView.image = [UIImage imageNamed:@"conversation_message_sending"];
            self.statusView.hidden = NO;
        } else if(info.lastMessage.status == Message_Status_Send_Failure) {
            self.statusView.image = [UIImage imageNamed:@"MessageSendError"];
            self.statusView.hidden = NO;
        } else {
            self.statusView.hidden = YES;
        }
    } else {
        self.statusView.hidden = YES;
    }
    [self updateDigestFrame:!self.statusView.hidden];
}

- (void)updateDigestFrame:(BOOL)isSending {
    if (isSending) {
        _digestView.frame = CGRectMake(8 + 52 + 8 + 18, 36, [UIScreen mainScreen].bounds.size.width - 68  - 16 - 8 - 18, 19);
    } else {
        _digestView.frame = CGRectMake(8 + 52 + 8, 36, [UIScreen mainScreen].bounds.size.width - 68  - 16 - 8, 19);
    }
}
- (void)update:(WFCCConversation *)conversation {
    if(conversation.type == Single_Type) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:conversation.target refresh:NO];
        if(userInfo.userId.length == 0) {
            userInfo = [[WFCCUserInfo alloc] init];
            userInfo.userId = conversation.target;
        }
        [self updateUserInfo:userInfo];
    } else if (conversation.type == Group_Type) {
        WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:conversation.target refresh:NO];
        if(groupInfo.target.length == 0) {
            groupInfo = [[WFCCGroupInfo alloc] init];
            groupInfo.target = conversation.target;
        }
        [self updateGroupInfo:groupInfo];
        
    } else if(conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:conversation.target refresh:NO];
        if (channelInfo.channelId.length == 0) {
            channelInfo = [[WFCCChannelInfo alloc] init];
            channelInfo.channelId = conversation.target;
        }
        [self updateChannelInfo:channelInfo];
    } else {
        self.targetView.text = [NSString stringWithFormat:@"chatroom<%@>", conversation.target];
    }
    
    self.potraitView.layer.cornerRadius = 4.f;
    
    if (_info.draft.length) {
        NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:@"[草稿]" attributes:@{NSForegroundColorAttributeName : [UIColor redColor]}];
        
        NSError *__error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[_info.draft dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:kNilOptions
                                                                     error:&__error];
        
        BOOL hasMentionInfo = NO;
        NSString *text = nil;
        if (!__error) {
            if (dictionary[@"text"] != nil && [dictionary[@"mentions"] isKindOfClass:[NSArray class]]) {
                hasMentionInfo = YES;
                text = dictionary[@"text"];
            }
        }
        if (text != nil) {
            [attString appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
        } else {
        [attString appendAttributedString:[[NSAttributedString alloc] initWithString:_info.draft]];
        }
        self.digestView.attributedText = attString;
    } else if (_info.lastMessage.direction == MessageDirection_Receive && (_info.conversation.type == Group_Type || _info.conversation.type == Channel_Type)) {
        NSString *groupId = nil;
        if (_info.conversation.type == Group_Type) {
            groupId = _info.conversation.target;
        }
        WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:_info.lastMessage.fromUser inGroup:groupId refresh:NO];
        if (sender.friendAlias.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            self.digestView.text = [NSString stringWithFormat:@"%@:%@", sender.friendAlias, _info.lastMessage.digest];
        } else if (sender.groupAlias.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            self.digestView.text = [NSString stringWithFormat:@"%@:%@", sender.groupAlias, _info.lastMessage.digest];
        } else if (sender.displayName.length && ![_info.lastMessage.content isKindOfClass:[WFCCNotificationMessageContent class]]) {
            self.digestView.text = [NSString stringWithFormat:@"%@:%@", sender.displayName, _info.lastMessage.digest];
        } else {
            self.digestView.text = _info.lastMessage.digest;
        }
    } else {
        self.digestView.text = _info.lastMessage.digest;
    }
}

- (UIImageView *)potraitView {
    if (!_potraitView) {
        _potraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 52, 52)];
        _potraitView.clipsToBounds = YES;
        _potraitView.layer.cornerRadius = 8.f;
        [self.contentView addSubview:_potraitView];
    }
    return _potraitView;
}

- (UIImageView *)statusView {
    if (!_statusView) {
        _statusView = [[UIImageView alloc] initWithFrame:CGRectMake(8 + 52 + 8, 38, 16, 16)];
        _statusView.image = [UIImage imageNamed:@"conversation_message_sending"];
        [self.contentView addSubview:_statusView];
    }
    return _statusView;
}

- (UILabel *)targetView {
    if (!_targetView) {
        _targetView = [[UILabel alloc] initWithFrame:CGRectMake(8 + 52 + 8, 12, [UIScreen mainScreen].bounds.size.width - 68  - 68, 20)];
        _targetView.font = [UIFont systemFontOfSize:18];
        [self.contentView addSubview:_targetView];
    }
    return _targetView;
}

- (UILabel *)digestView {
    if (!_digestView) {
        _digestView = [[UILabel alloc] initWithFrame:CGRectMake(8 + 52 + 8, 36, [UIScreen mainScreen].bounds.size.width - 68  - 16 - 8, 19)];
        _digestView.font = [UIFont systemFontOfSize:14];
        _digestView.lineBreakMode = NSLineBreakByTruncatingTail;
        _digestView.textColor = [UIColor grayColor];
        [self.contentView addSubview:_digestView];
    }
    return _digestView;
}

- (UIImageView *)silentView {
    if (!_silentView) {
        _silentView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 12  - 12, 40, 12, 12)];
        _silentView.image = [UIImage imageNamed:@"conversation_mute"];
        [self.contentView addSubview:_silentView];
    }
    return _silentView;
}

- (UILabel *)timeView {
    if (!_timeView) {
        _timeView = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 52  - 8, 15, 52, 15)];
        _timeView.font = [UIFont systemFontOfSize:13];
        _timeView.textAlignment = NSTextAlignmentRight;
        _timeView.textColor = [UIColor grayColor];
        [self.contentView addSubview:_timeView];
    }

    return _timeView;
}

- (BubbleTipView *)bubbleView {
    if (!_bubbleView) {
        if(self.potraitView) {
            _bubbleView = [[BubbleTipView alloc] initWithParentView:self.contentView];
            _bubbleView.hidden = YES;
        }
    }
    return _bubbleView;
}
@end
