//
//  WFCUCompositeImageCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUCompositeImageCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


@implementation WFCUCompositeImageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForMessageContent:(WFCCMessage *)message {
    WFCCImageMessageContent *content = (WFCCImageMessageContent *)message.content;
    return content.thumbnail.size.height;
}

- (void)setMessage:(WFCCMessage *)message {
    [super setMessage:message];
    WFCCImageMessageContent *content = (WFCCImageMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    frame.size.height = content.thumbnail.size.height;
    frame.size.width = content.thumbnail.size.width;
    self.contentImageView.frame = frame;
    self.contentImageView.image = content.thumbnail;
}

- (UIImageView *)contentImageView {
    if (!_contentImageView) {
        _contentImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_contentImageView];
    }
    return _contentImageView;
}
@end
