//
//  ConversationCell.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ConversationCell.h"
#import <SDWebImage/SDWebImage.h>
#import "ShareUtility.h"

@implementation ConversationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

- (void)setConversation:(SharedConversation *)sc {
    _conversation = sc;
    
    self.nameLabel.text = sc.title;
    if (sc.type == 0) { //Single_Type
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    } else if(sc.type == 1) {  //Group_Type
        if (sc.portraitUrl) {
            [self.portraitView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
        } else {
            [self.portraitView sd_setImageWithURL:[ShareUtility getSavedGroupGridPortrait:sc.target] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
        }
    } else if(sc.type == 3) { //Channel_Type
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:sc.portraitUrl] placeholderImage:[UIImage imageNamed:@"ChannelChat"]];
    }
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 40, 40)];
        _portraitView.layer.cornerRadius = 3.f;
        _portraitView.layer.masksToBounds = YES;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 18, self.bounds.size.width - 56 - 16, 20)];
        _nameLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}
@end
