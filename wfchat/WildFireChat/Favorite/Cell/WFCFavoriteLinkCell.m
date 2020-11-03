//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteLinkCell.h"
#import <WFChatUIKit/WFChatUIKit.h>


@interface WFCFavoriteLinkCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@end

@implementation WFCFavoriteLinkCell

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
    return 60;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        _iconView.image = [UIImage imageNamed:@"default_link"];
        _iconView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        [self.contentArea addSubview:_iconView];
    }
    return _iconView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 4, self.bounds.size.width-72, 56)];
        _nameLabel.font = [UIFont systemFontOfSize:18];
        _nameLabel.numberOfLines = 0;
        [self.contentArea addSubview:_nameLabel];
    }
    return _nameLabel;
}

@end
