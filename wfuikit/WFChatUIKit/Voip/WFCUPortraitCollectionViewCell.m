//
//  WFCUPortraitCollectionViewCell.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/20.
//  Copyright © 2020 Tom Lee. All rights reserved.
//

#import "WFCUPortraitCollectionViewCell.h"
#import "SDWebImage.h"

@interface WFCUPortraitCollectionViewCell ()
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@end

@implementation WFCUPortraitCollectionViewCell

- (void)setUserInfo:(WFCCUserInfo *)userInfo {
    _userInfo = userInfo;
    [self.portraitView sd_setImageWithURL:[NSURL URLWithString:[userInfo.portrait stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    self.nameLabel.text = userInfo.displayName;
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.itemSize, self.itemSize)];

        _portraitView.layer.masksToBounds = YES;
        _portraitView.layer.cornerRadius = 2.f;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.itemSize, self.itemSize, self.labelSize)];
        _nameLabel.font = [UIFont systemFontOfSize:self.labelSize - 2];
        _nameLabel.textColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}
@end
