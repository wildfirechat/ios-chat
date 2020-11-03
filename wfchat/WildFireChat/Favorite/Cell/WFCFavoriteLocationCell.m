//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteLocationCell.h"
#import <WFChatUIKit/WFChatUIKit.h>


@interface WFCFavoriteLocationCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@end

@implementation WFCFavoriteLocationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    [self iconView];
    self.nameLabel.text = favoriteItem.title;
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem {
    return 56;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        _iconView.image = [UIImage imageNamed:@"location_icon"];
        _iconView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        [self.contentArea addSubview:_iconView];
    }
    return _iconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 8, self.bounds.size.width-72, 20)];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        [self.contentArea addSubview:_nameLabel];
    }
    return _nameLabel;
}

@end
