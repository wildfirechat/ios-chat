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
