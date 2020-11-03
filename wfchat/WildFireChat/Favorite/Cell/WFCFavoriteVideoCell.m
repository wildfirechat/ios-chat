//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteVideoCell.h"

@interface WFCFavoriteVideoCell ()
@property(nonatomic, strong)UIImageView *thumbView;
@property(nonatomic, strong)UIImageView *videoIcon;
@property(nonatomic, strong)UILabel *durationLabel;
@end

@implementation WFCFavoriteVideoCell

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
    self.videoIcon.center = self.thumbView.center;
    
    int duration = [dict[@"duration"] intValue];
    self.durationLabel.text = [NSString stringWithFormat:@"%d 秒", duration];
    self.durationLabel.frame = CGRectMake(8, image.size.height - 30, image.size.width-16, 20);
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
- (UIImageView *)videoIcon {
    if (!_videoIcon) {
        _videoIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _videoIcon.image = [UIImage imageNamed:@"video_msg_cover"];
        [self.thumbView addSubview:_videoIcon];
    }
    return _videoIcon;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.textAlignment = NSTextAlignmentRight;
        _durationLabel.font = [UIFont systemFontOfSize:14];
        [self.thumbView addSubview:_durationLabel];
    }
    return _durationLabel;
}
@end
