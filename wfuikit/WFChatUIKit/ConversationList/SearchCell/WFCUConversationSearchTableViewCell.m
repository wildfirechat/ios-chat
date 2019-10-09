//
//  ConversationSearchTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/8/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSearchTableViewCell.h"
#import "WFCUUtilities.h"
#import <WFChatClient/WFCChatClient.h>
#import "SDWebImage.h"
#import "WFCUConfigManager.h"

@implementation WFCUConversationSearchTableViewCell
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}
  

  
- (void)updateUserInfo:(WFCCUserInfo *)userInfo {
  [self.potraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
  
    if (userInfo.friendAlias.length) {
        self.targetView.text = userInfo.friendAlias;
    } else if(userInfo.displayName.length > 0) {
        self.targetView.text = userInfo.displayName;
    } else {
        self.targetView.text = [NSString stringWithFormat:@"user<%@>", self.message.fromUser];
    }
}

- (void)setMessage:(WFCCMessage *)message {
    _message = message;
    
  
    
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:message.fromUser refresh:NO];
        if(userInfo.userId.length == 0) {
            userInfo = [[WFCCUserInfo alloc] init];
            userInfo.userId = message.fromUser;
        }
        [self updateUserInfo:userInfo];
    NSString *strContent = message.digest;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:strContent];
    NSRange range = [strContent rangeOfString:self.keyword options:NSCaseInsensitiveSearch];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range];
    self.digestView.attributedText = attrStr;
    
    self.potraitView.layer.cornerRadius = 4.f;
    
    self.timeView.hidden = NO;
    self.timeView.text = [WFCUUtilities formatTimeLabel:message.serverTime];
    self.contentView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
}

- (UIImageView *)potraitView {
    if (!_potraitView) {
        _potraitView = [[UIImageView alloc] initWithFrame:CGRectMake(19, 19, 30, 30)];
        _potraitView.clipsToBounds = YES;
        _potraitView.layer.cornerRadius = 2.f;
        [self.contentView addSubview:_potraitView];
    }
    return _potraitView;
}

- (UILabel *)targetView {
    if (!_targetView) {
        _targetView = [[UILabel alloc] initWithFrame:CGRectMake(16 + 28 + 16, 19, [UIScreen mainScreen].bounds.size.width - 68  - 68, 10)];
        _targetView.font = [UIFont systemFontOfSize:10];
        _targetView.textColor = [UIColor grayColor];
        [self.contentView addSubview:_targetView];
    }
    return _targetView;
}

- (UILabel *)digestView {
    if (!_digestView) {
        _digestView = [[UILabel alloc] initWithFrame:CGRectMake(16 + 28 + 16, 34, [UIScreen mainScreen].bounds.size.width - 60  - 16, 14)];
        _digestView.font = [UIFont systemFontOfSize:14];
        _digestView.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:_digestView];
    }
    return _digestView;
}

- (UILabel *)timeView {
    if (!_timeView) {
        _timeView = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 52  - 8, 18, 52, 12)];
        _timeView.font = [UIFont systemFontOfSize:11];
        _timeView.textAlignment = NSTextAlignmentRight;
        _timeView.textColor = [UIColor grayColor];
        [self.contentView addSubview:_timeView];
    }

    return _timeView;
}

@end
