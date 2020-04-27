//
//  DiscoverTableViewCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/3/10.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "DiscoverMomentsTableViewCell.h"
#import "SDWebImage.h"


@interface DiscoverMomentsTableViewCell ()
@property(nonatomic, strong)UIImageView *lastFeedPortrait;
@property (nonatomic, strong)BubbleTipView *bubbleView2;
@end

@implementation DiscoverMomentsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (BubbleTipView *)bubbleView {
    if (!_bubbleView) {
        if(self.textLabel) {
            _bubbleView = [[BubbleTipView alloc] initWithSuperView:self.textLabel];
            _bubbleView.hidden = YES;
            _bubbleView.isShowNotificationNumber = YES;
        }
    }
    return _bubbleView;
}

- (BubbleTipView *)bubbleView2 {
    if (!_bubbleView2) {
        if(self.lastFeedPortrait) {
            _bubbleView2 = [[BubbleTipView alloc] initWithSuperView:self.lastFeedPortrait];
            _bubbleView2.hidden = YES;
            _bubbleView2.bubbleTipPositionAdjustment = CGPointMake(-25, -8);
            _bubbleView2.isShowNotificationNumber = NO;
        }
    }
    return _bubbleView2;
}

- (UIImageView *)lastFeedPortrait {
    if (!_lastFeedPortrait) {
        _lastFeedPortrait = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 80, 8, 32, 32)];
        [self.contentView addSubview:_lastFeedPortrait];
    }
    return _lastFeedPortrait;
}
#ifdef WFC_MOMENTS
- (void)setLastFeed:(WFMFeed *)lastFeed {
    _lastFeed = lastFeed;
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:lastFeed.sender refresh:NO];
    
    [self.lastFeedPortrait sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    if (lastFeed.serverTime > [[WFMomentService sharedService] getLastReadTimestamp]*1000) {
        [self.bubbleView2 setBubbleTipNumber:1];
        self.bubbleView2.hidden = NO;
    } else {
        [self.bubbleView2 setBubbleTipNumber:0];
        self.bubbleView2.hidden = YES;
    }
}
#endif
@end
