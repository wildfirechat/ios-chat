//
//  WFCUMeetingMinutesCell.m
//  WFChatUIKit
//
//  Created by Kimi on 2026/5/18.
//  Copyright © 2026年 WildFireChat. All rights reserved.
//

#import "WFCUMeetingMinutesCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"

#define TEXT_TOP_PADDING 6
#define TEXT_BOTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8

@implementation WFCUMeetingMinutesCell

+ (UIFont *)titleFont {
    return [UIFont boldSystemFontOfSize:16];
}

+ (UIFont *)bodyFont {
    return [UIFont systemFontOfSize:14];
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCMeetingMinutesMessageContent *content = (WFCCMeetingMinutesMessageContent *)msgModel.message.content;
    NSString *title = content.title ?: @"";
    NSString *text = content.text ?: @"";
    
    NSString *displayText = @"";
    if (title.length) {
        displayText = [NSString stringWithFormat:@"%@\n\n%@", title, text];
    } else {
        displayText = text;
    }
    
    CGSize size = [WFCUUtilities getTextDrawingSize:displayText font:[self bodyFont] constrainedSize:CGSizeMake(width - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.width += TEXT_LEFT_PADDING + TEXT_RIGHT_PADDING;
    size.height += TEXT_TOP_PADDING + TEXT_BOTTOM_PADDING;
    
    if (size.width < 100) {
        size.width = 100;
    }
    if (size.height < 40) {
        size.height = 40;
    }
    
    return size;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCMeetingMinutesMessageContent *content = (WFCCMeetingMinutesMessageContent *)model.message.content;
    NSString *title = content.title ?: @"";
    NSString *text = content.text ?: @"";
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
    if (title.length) {
        NSAttributedString *titleAttr = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: [WFCUMeetingMinutesCell titleFont], NSForegroundColorAttributeName: [UIColor blackColor]}];
        [attrString appendAttributedString:titleAttr];
        if (text.length) {
            [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
        }
    }
    if (text.length) {
        NSAttributedString *textAttr = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [WFCUMeetingMinutesCell bodyFont], NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
        [attrString appendAttributedString:textAttr];
    }
    
    self.textLabel.attributedText = attrString;
    CGRect frame = self.contentArea.bounds;
    self.textLabel.frame = CGRectMake(TEXT_LEFT_PADDING, TEXT_TOP_PADDING, frame.size.width - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, frame.size.height - TEXT_TOP_PADDING - TEXT_BOTTOM_PADDING);
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.numberOfLines = 0;
        _textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentArea addSubview:_textLabel];
    }
    return _textLabel;
}

@end
