//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteImageCell.h"

@interface WFCFavoriteImageCell ()
@property(nonatomic, strong)UIImageView *thumbView;
@end

@implementation WFCFavoriteImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[favoriteItem.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    NSString *thumbStr = dict[@"thumb"];
    NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:thumbData];
    self.thumbView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.thumbView.image = image;
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[favoriteItem.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    NSString *thumbStr = dict[@"thumb"];
    NSData *thumbData = [[NSData alloc] initWithBase64EncodedString:thumbStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:thumbData];
    return image.size.height;
}

- (UIImageView *)thumbView {
    if (!_thumbView) {
        _thumbView = [[UIImageView alloc] init];
        [self.contentArea addSubview:_thumbView];
    }
    return _thumbView;
}
@end
