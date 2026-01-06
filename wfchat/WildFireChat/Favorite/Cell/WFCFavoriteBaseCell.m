//
//  WFCFavoriteBaseCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteBaseCell.h"

@interface WFCFavoriteBaseCell ()
@property(nonatomic, strong)UILabel *buttomLabel;
@end

@implementation WFCFavoriteBaseCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    
}
- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    _favoriteItem = favoriteItem;
    CGFloat contentHeight = [[self class] contentHeight:favoriteItem containerWidth:self.contentView.bounds.size.width];
    self.contentArea.frame = CGRectMake(16, 16, self.contentView.bounds.size.width - 32, contentHeight);
    self.buttomLabel.frame = CGRectMake(16, contentHeight+24, self.bounds.size.width-32, 16);
    self.buttomLabel.text = [favoriteItem.origin stringByAppendingFormat:@"  %@", [WFCUUtilities formatTimeLabel:favoriteItem.timestamp]];
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem containerWidth:(CGFloat)containerWidth {
    return 0;
}

+ (CGFloat)heightOf:(WFCUFavoriteItem *)favoriteItem containerWidth:(CGFloat)containerWidth {
    return [self contentHeight:favoriteItem containerWidth:containerWidth] + 54;
}

- (UIView *)contentArea {
    if (!_contentArea) {
        _contentArea = [[UIView alloc] init];
        [self.contentView addSubview:_contentArea];
    }
    return _contentArea;;
}

- (UILabel *)buttomLabel {
    if (!_buttomLabel) {
        _buttomLabel = [[UILabel alloc] init];
        _buttomLabel.numberOfLines = 1;
        _buttomLabel.font = [UIFont systemFontOfSize:14];
        _buttomLabel.textColor = [UIColor grayColor];
        _buttomLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self.contentView addSubview:_buttomLabel];
    }
    return _buttomLabel;;
}
@end
