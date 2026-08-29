//
//  ChatroomItemCell.m
//  WildFireChat
//
//  Created by heavyrain lee on 2018/8/24.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "ChatroomItemCell.h"
#import <SDWebImage/SDWebImage.h>

@implementation ChatroomItemCell
- (void)setChatroomInfo:(WFCCChatroomInfo *)chatroomInfo {
    _chatroomInfo = chatroomInfo;
    if (_chatroomInfo.portrait) {
        [self.portraitIV sd_setImageWithURL:[NSURL URLWithString:_chatroomInfo.portrait] placeholderImage:[UIImage imageNamed:@"GroupChatRound"]];
    } else {
        [self.portraitIV setImage:[UIImage imageNamed:@"GroupChatRound"]];
    }
    
    self.titleLable.text = _chatroomInfo.title;
}

//格子尺寸不是固定的：iPad 上按栏宽算，栏宽还会随旋转/分屏/台前调度变（见
//ChatroomListViewController 的 viewWillLayoutSubviews）。子视图是在 getter 里按当时的
//bounds 定死的，尺寸变了不会自己跟，头像就还是旧的大小、圆角也对不上。
//排版统一放到这里，按每次的真实 bounds 来。iPhone 上格子宽度恒定，算出来与原先同一个数。
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    self.portraitIV.frame = CGRectMake(0, 0, width, width);
    self.portraitIV.layer.cornerRadius = width / 2;
    self.titleLable.frame = CGRectMake(0, width, width, MAX(height - width, 0));
}

- (UIImageView *)portraitIV {
    if (!_portraitIV) {
        _portraitIV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.width)];
        _portraitIV.layer.masksToBounds = YES;
        _portraitIV.layer.cornerRadius = self.bounds.size.width/2;
        [self addSubview:_portraitIV];
    }
    return _portraitIV;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] initWithFrame:CGRectMake(0, self.bounds.size.width, self.bounds.size.width, self.bounds.size.height - self.bounds.size.width)];
        [_titleLable setTextAlignment:NSTextAlignmentCenter];
        [self addSubview:_titleLable];
    }
    return _titleLable;
}
@end
