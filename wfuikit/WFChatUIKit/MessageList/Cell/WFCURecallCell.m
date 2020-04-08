//
//  InformationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCURecallCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"

#define TEXT_TOP_PADDING 6
#define TEXT_BUTTOM_PADDING 6
#define TEXT_LEFT_PADDING 8
#define TEXT_RIGHT_PADDING 8


#define TEXT_LABEL_TOP_PADDING TEXT_TOP_PADDING + 4
#define TEXT_LABEL_BUTTOM_PADDING TEXT_BUTTOM_PADDING + 4
#define TEXT_LABEL_LEFT_PADDING 30
#define TEXT_LABEL_RIGHT_PADDING 30

@implementation WFCURecallCell

+ (NSString *)recallMsg:(WFCCRecallMessageContent *)content {
    NSString *digest = [content digest:nil];
    if (content.originalContentType == MESSAGE_CONTENT_TYPE_TEXT && [content.originalSender isEqualToString:[WFCCNetworkService sharedInstance].userId] && content.originalSearchableContent.length > 0) {
        return [digest stringByAppendingString:@" 重新编辑"];
    }
    return digest;
}
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGFloat height = [super hightForTimeLabel:msgModel];
    NSString *infoText = [WFCURecallCell recallMsg:(WFCCRecallMessageContent *)msgModel.message.content];
    
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING;
    size.height += height;
    return CGSizeMake(width, size.height);
    
    return CGSizeZero;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    NSString *infoText = [WFCURecallCell recallMsg:(WFCCRecallMessageContent *)model.message.content];
    
    CGFloat width = self.contentView.bounds.size.width;
    
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    
    
    WFCCRecallMessageContent *content = (WFCCRecallMessageContent *)model.message.content;
    [self.infoLabel yb_removeAttributeTapActions];
    if (content.originalContentType == MESSAGE_CONTENT_TYPE_TEXT && [content.originalSender isEqualToString:[WFCCNetworkService sharedInstance].userId] && content.originalSearchableContent.length > 0) {
        NSString *digest = [content digest:nil];
        NSString *info = [digest stringByAppendingString:@" 重新编辑 "];
        NSMutableAttributedString *astr = [[NSMutableAttributedString alloc] initWithString:info];
        [astr setAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14],NSForegroundColorAttributeName : [UIColor blueColor]} range:NSMakeRange(digest.length+1, 4)];
        self.infoLabel.attributedText = astr;
        
        
        __weak typeof(self)ws = self;
        [self.infoLabel yb_addAttributeTapActionWithStrings:@[@" 重新编辑 "] tapClicked:^(UILabel *label, NSString *string, NSRange range, NSInteger index) {
            [ws.delegate reeditRecalledMessage:ws withModel:ws.model];
        }];
    } else {
        self.infoLabel.text = infoText;
    }
    
    
    self.infoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    CGFloat timeLableEnd = 0;
    if (!self.timeLabel.hidden) {
        timeLableEnd = self.timeLabel.frame.size.height + self.timeLabel.frame.origin.y;
    }
    self.infoLabel.frame = CGRectMake((width - size.width)/2 - 8, timeLableEnd + TEXT_LABEL_TOP_PADDING, size.width + 16, size.height + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING);
//    self.infoLabel.textAlignment = NSTextAlignmentCenter;

}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.numberOfLines = 0;
        _infoLabel.font = [UIFont systemFontOfSize:14];
        
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.numberOfLines = 0;
        _infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.font = [UIFont systemFontOfSize:14.f];
        _infoLabel.layer.masksToBounds = YES;
        _infoLabel.layer.cornerRadius = 5.f;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.backgroundColor = [UIColor colorWithRed:201/255.f green:201/255.f blue:201/255.f alpha:1.f];
        
        [self.contentView addSubview:_infoLabel];
    }
    return _infoLabel; 
}
@end
