//
//  WFCFavoriteCardCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteCardCell.h"
#import <WFChatUIKit/WFChatUIKit.h>

@interface WFCFavoriteCardCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@end

@implementation WFCFavoriteCardCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    [self iconView];
    [self nameLabel];

    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[favoriteItem.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    int type = [dict[@"type"] intValue];

    self.nameLabel.text = dict[@"name"];

    switch (type) {
        case CardType_User:
            self.iconView.image = [UIImage imageNamed:@"PersonalChat"];
            break;
        case CardType_Group:
            self.iconView.image = [UIImage imageNamed:@"group_avatar"];
            break;
        case CardType_Channel:
            self.iconView.image = [UIImage imageNamed:@"channel_avatar"];
            break;
        default:
            self.iconView.image = [UIImage imageNamed:@"PersonalChat"];
            break;
    }
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem {
    return 60;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        _iconView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        _iconView.layer.cornerRadius = 4;
        _iconView.layer.masksToBounds = YES;
        [self.contentArea addSubview:_iconView];
    }
    return _iconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 8, self.bounds.size.width-72, 44)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        _nameLabel.numberOfLines = 2;
        [self.contentArea addSubview:_nameLabel];
    }
    return _nameLabel;
}

@end
