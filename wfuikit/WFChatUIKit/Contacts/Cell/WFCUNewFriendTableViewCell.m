//
//  NewFriendTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUNewFriendTableViewCell.h"
#import <WFChatClient/WFCChatClient.h>
#import <SDWebImage/SDWebImage.h>
#import "UIFont+YH.h"
#import "UIColor+YH.h"
#import "WFCUConfigManager.h"

@interface WFCUNewFriendTableViewCell ()

@end

@implementation WFCUNewFriendTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat portraitSize = 40 + ([WFCUConfigManager globalManager].fontScale - 1.0) * 4;
    self.portraitView.frame = CGRectMake(16, (self.frame.size.height - portraitSize) / 2.0, portraitSize, portraitSize);
    CGFloat labelHeight = MAX(16, [WFCUConfigManager scaledSize:16]);
    self.nameLabel.frame = CGRectMake(16 + portraitSize + 11, (self.frame.size.height - labelHeight) / 2.0, [UIScreen mainScreen].bounds.size.width - 64, labelHeight);
}

- (void)onFriendRequestUpdated:(NSNotification *)notification {
    [self updateBubbleNumber];
}

- (void)updateBubbleNumber {
    int unreadCount = [[WFCCIMService sharedWFCIMService] getUnreadFriendRequestStatus];
    if (unreadCount) {
        self.bubbleView.hidden = NO;
        [self.bubbleView setBubbleTipNumber:unreadCount];
    } else {
        self.bubbleView.hidden = YES;
    }
}

- (void)refresh {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendRequestUpdated:) name:kFriendRequestUpdated object:nil];
    
    [self updateBubbleNumber];
}

- (BubbleTipView *)bubbleView {
    if (!_bubbleView) {
        if (self.portraitView) {
            _bubbleView = [[BubbleTipView alloc] initWithSuperView:self.contentView];
            _bubbleView.hidden = YES;
        }
    }
    return _bubbleView;
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(16, 10, 40, 40)];
        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 4.f;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16 + 40 + 11, 19, [UIScreen mainScreen].bounds.size.width - 64, 16)];
        _nameLabel.font = [UIFont scaledPingFangSCWithWeight:FontWeightStyleRegular size:15];
        _nameLabel.textColor = [UIColor colorWithHexString:@"0x1d1d1d"];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
