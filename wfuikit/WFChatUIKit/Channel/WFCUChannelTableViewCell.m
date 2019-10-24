//
//  GroupTableViewCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/13.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUChannelTableViewCell.h"
#import "SDWebImage.h"

@interface WFCUChannelTableViewCell()
@property (strong, nonatomic) UIImageView *portrait;
@property (strong, nonatomic) UILabel *name;

@end

@implementation WFCUChannelTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setChannelInfo:(WFCCChannelInfo *)channelInfo {
    _channelInfo = channelInfo;
    if (channelInfo.name.length == 0) {
        self.name.text = WFCString(@"Channel");
    } else {
        self.name.text = [NSString stringWithFormat:@"%@", channelInfo.name];
    }
    [self.portrait sd_setImageWithURL:[NSURL URLWithString:[channelInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"channel_default_portrait"]];
}
@end
