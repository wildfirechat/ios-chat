//
//  WFCFavoriteUnknownCell.m
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCFavoriteSoundCell.h"
#import <WFChatUIKit/WFChatUIKit.h>


@interface WFCFavoriteSoundCell ()
@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)NSTimer *animateTimeer;
@end

@implementation WFCFavoriteSoundCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setFavoriteItem:(WFCUFavoriteItem *)favoriteItem {
    [super setFavoriteItem:favoriteItem];
    [self iconView];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[favoriteItem.data dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    int duration = [dict[@"duration"] intValue];
    
    self.nameLabel.text = [NSString stringWithFormat:@"%d 秒", duration];
}

+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem {
    return 56;
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    if (isPlaying) {
        __weak typeof(self)ws = self;
        if (@available(iOS 10.0, *)) {
            self.animateTimeer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                if((NSUInteger)[NSDate date].timeIntervalSince1970 % 2) {
                    ws.iconView.image = nil;
                } else {
                    ws.iconView.image = [UIImage imageNamed:@"sound_icon"];
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    } else {
        [self.animateTimeer invalidate];
        self.animateTimeer = nil;
        self.iconView.image = [UIImage imageNamed:@"sound_icon"];
    }
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        _iconView.image = [UIImage imageNamed:@"sound_icon"];
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
