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
    return digest;
}
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    CGFloat height = [super hightForHeaderArea:msgModel];
    NSString *infoText = [WFCURecallCell recallMsg:(WFCCRecallMessageContent *)msgModel.message.content];
    
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    size.height += TEXT_LABEL_TOP_PADDING + TEXT_LABEL_BUTTOM_PADDING + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING;
    size.height += height;
    return CGSizeMake(width, size.height);
    
    return CGSizeZero;
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    
    WFCCRecallMessageContent *content = (WFCCRecallMessageContent *)model.message.content;
    NSString *infoText = [WFCURecallCell recallMsg:(WFCCRecallMessageContent *)model.message.content];
    CGFloat width = self.contentView.bounds.size.width;
    
    
    CGFloat reeditBtnWidth = 0;
    
    if (content.originalContentType == MESSAGE_CONTENT_TYPE_TEXT && [content.originalSender isEqualToString:[WFCCNetworkService sharedInstance].userId] && content.originalSearchableContent.length > 0) {
        CGSize btnsize = [WFCUUtilities getTextDrawingSize:self.reeditButton.titleLabel.text font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
        
        reeditBtnWidth = btnsize.width + 4;
    }
    
    
    CGSize size = [WFCUUtilities getTextDrawingSize:infoText font:[UIFont systemFontOfSize:14] constrainedSize:CGSizeMake(width - TEXT_LABEL_LEFT_PADDING - TEXT_LABEL_RIGHT_PADDING - TEXT_LEFT_PADDING - TEXT_RIGHT_PADDING, 8000)];
    
    
    self.infoLabel.text = infoText;
    
    self.infoLabel.layoutMargins = UIEdgeInsetsMake(TEXT_TOP_PADDING, TEXT_LEFT_PADDING, TEXT_BUTTOM_PADDING, TEXT_RIGHT_PADDING);
    CGFloat timeLableEnd = 0;
    if (!self.timeLabel.hidden) {
        timeLableEnd = self.timeLabel.frame.size.height + self.timeLabel.frame.origin.y;
    }
    self.recallContainer.frame = CGRectMake((width - size.width - reeditBtnWidth)/2 - 8, timeLableEnd + TEXT_LABEL_TOP_PADDING, size.width + reeditBtnWidth + 16, size.height + TEXT_TOP_PADDING + TEXT_BUTTOM_PADDING);
    
    self.infoLabel.frame = CGRectMake(8, TEXT_BUTTOM_PADDING, size.width, size.height);
    if (reeditBtnWidth) {
        self.reeditButton.frame = CGRectMake(size.width + 8, TEXT_BUTTOM_PADDING, reeditBtnWidth, size.height);
    }
    
}

- (void)onReeditBtn:(id)sender {
    [self.delegate reeditRecalledMessage:self withModel:self.model];
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
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.backgroundColor = [UIColor clearColor];
        
        [self.recallContainer addSubview:_infoLabel];
    }
    return _infoLabel;
}

- (UIButton *)reeditButton {
    if (!_reeditButton) {
        _reeditButton = [[UIButton alloc] init];
        [_reeditButton setTitle:WFCString(@"重新编辑") forState:UIControlStateNormal];
        [_reeditButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_reeditButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [_reeditButton addTarget:self action:@selector(onReeditBtn:) forControlEvents:UIControlEventTouchDown];
        [_reeditButton setBackgroundColor:[UIColor clearColor]];
        _reeditButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [self.recallContainer addSubview:_reeditButton];
    }
    return _reeditButton;
}

- (UIView *)recallContainer {
    if (!_recallContainer) {
        _recallContainer = [[UIView alloc] init];
        _recallContainer.backgroundColor = [UIColor colorWithRed:201/255.f green:201/255.f blue:201/255.f alpha:1.f];
        _recallContainer.layer.masksToBounds = YES;
        _recallContainer.layer.cornerRadius = 5.f;
        [self.contentView addSubview:_recallContainer];
    }
    return _recallContainer;
}
@end
