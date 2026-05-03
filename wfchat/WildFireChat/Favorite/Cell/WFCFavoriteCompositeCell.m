//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteCompositeCell.h"

@interface WFCFavoriteCompositeCell ()
@property(nonatomic, strong)UILabel *label;
+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem width:(CGFloat)width;
@end

@implementation WFCFavoriteCompositeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    self.label.frame = self.contentArea.bounds;
    self.label.text = favoriteItem.title;
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem width:(CGFloat)width {
    return [WFCUUtilities getTextDrawingSize:favoriteItem.title font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(width-16, 1000)].height;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:18];
        _label.numberOfLines = 0;
        [self.contentArea addSubview:_label];
    }
    return _label;;
}
@end
