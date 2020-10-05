//
//  CompositeTextTableViewCell.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUCompositeTextCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


@implementation WFCUCompositeTextCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForMessageContent:(WFCCMessage *)message {
    WFCCTextMessageContent *txtContent = (WFCCTextMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    CGSize size = [WFCUUtilities getTextDrawingSize:txtContent.text font:[UIFont systemFontOfSize:18] constrainedSize:CGSizeMake(frame.size.width, 8000)];
    return size.height;
}

- (void)setMessage:(WFCCMessage *)message {
    [super setMessage:message];
    WFCCTextMessageContent *txtCnt = (WFCCTextMessageContent *)message.content;
    CGRect frame = [self.class contentFrame];
    frame.size.height = [self.class heightForMessageContent:message];
    self.contentLabel.frame = frame;
    self.contentLabel.text = txtCnt.text;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _contentLabel.numberOfLines = 0;
        [self.contentView addSubview:_contentLabel];
    }
    return _contentLabel;
}
@end
