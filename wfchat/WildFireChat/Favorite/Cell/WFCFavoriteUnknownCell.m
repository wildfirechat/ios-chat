//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteUnknownCell.h"

@interface WFCFavoriteUnknownCell ()
@property(nonatomic, strong)UILabel *unknownLabel;
@end

@implementation WFCFavoriteUnknownCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    [self unknownLabel];
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem {
    return 30;
}

- (UILabel *)unknownLabel {
    if (!_unknownLabel) {
        _unknownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 30)];
        _unknownLabel.font = [UIFont systemFontOfSize:18];
        _unknownLabel.numberOfLines = 1;
        _unknownLabel.text = @"当前版本不支持，请升级察看";
        [self.contentArea addSubview:_unknownLabel];
    }
    return _unknownLabel;;
}
@end
