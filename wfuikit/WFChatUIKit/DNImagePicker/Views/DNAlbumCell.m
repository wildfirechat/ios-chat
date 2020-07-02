//
//  DNAlbumCell.m
//  DNImagePicker
//
//  Created by DingXiao on 16/8/29.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import "DNAlbumCell.h"

@implementation DNAlbumCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self postImageView];
        [self titleLabel];
        [self addContentConstraints];
    }
    return self;
}

- (void)addContentConstraints {
    // TODO: add Constraints
    NSString *vflForH = @"H:|-10-[_postImageView(64)]-20-[_titleLabel]-10-|";
    NSString *vflForVPostImageView = @"V:|-0-[_postImageView]-0-|";
    NSString *vflForVtitleLabel = @"V:|-1-[_titleLabel]-1-|";
    NSArray *contraintsH = [NSLayoutConstraint
                            constraintsWithVisualFormat:vflForH
                            options:0
                            metrics:nil
                            views:NSDictionaryOfVariableBindings(_postImageView,_titleLabel)];
    NSArray *contraintsVPostImageView = [NSLayoutConstraint
                                         constraintsWithVisualFormat:vflForVPostImageView
                                         options:0
                                         metrics:nil
                                         views:NSDictionaryOfVariableBindings(_postImageView)];
    NSArray *contraintsVtitleLabel = [NSLayoutConstraint
                                      constraintsWithVisualFormat:vflForVtitleLabel
                                      options:0
                                      metrics:nil
                                      views:NSDictionaryOfVariableBindings(_titleLabel)];
    [self.contentView addConstraints:contraintsH];
    [self.contentView addConstraints:contraintsVPostImageView];
    [self.contentView addConstraints:contraintsVtitleLabel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (UIImageView *)postImageView {
    if (!_postImageView) {
        _postImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [_postImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addSubview:_postImageView];
    }
    return _postImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}
@end
