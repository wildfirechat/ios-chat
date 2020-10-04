//
//  MessageCellBase.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUMessageCellBase.h"
#import "WFCUUtilities.h"
#import "UIFont+YH.h"
#import "UIColor+YH.h"
@implementation WFCUMessageCellBase
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
  return CGSizeMake(width, 80);
}
+ (CGFloat)hightForTimeLabel:(WFCUMessageModel *)msgModel {
  if (msgModel.showTimeLabel) {
    return 27;
  }
  return 5;
}
+ (CGFloat)hightForLastReadLabel:(WFCUMessageModel *)msgModel {
    if (msgModel.lastReadMessage) {
        return 30;
    }
    return 0;
}
- (void)onTaped:(id)sender {
    [self.delegate didTapMessageCell:self withModel:self.model];
}

- (void)onDoubleTaped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didDoubleTapMessageCell:withModel:)]) {
        [self.delegate didDoubleTapMessageCell:self withModel:self.model];
    }
}

- (void)onLongPressed:(id)sender {
    if ([sender isKindOfClass:[UILongPressGestureRecognizer class]]) {
        UILongPressGestureRecognizer *recognizer = (UILongPressGestureRecognizer *)sender;
        if(recognizer.state == UIGestureRecognizerStateBegan) {
            [self.delegate didLongPressMessageCell:self withModel:self.model];
        }
    }
}

- (void)setModel:(WFCUMessageModel *)model {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
  _model = model;
    CGFloat offset = 5;
    if (model.lastReadMessage) {
        if (!self.lastReadContainerView) {
            self.lastReadContainerView = [[UIView alloc] initWithFrame:CGRectMake(8, offset, screenWidth-16, 20)];
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 10, screenWidth-16, 1)];
            line.backgroundColor = [UIColor grayColor];
            [self.lastReadContainerView addSubview:line];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.text = WFCString(@"last_read_here");
            label.font = [UIFont systemFontOfSize:16];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor grayColor];
            CGSize size = [WFCUUtilities getTextDrawingSize:label.text font:label.font constrainedSize:CGSizeMake(screenWidth-16, 8000)];
            size.width += 16;
            label.frame = CGRectMake((screenWidth - 16 - size.width)/2, offset, size.width, 20);
            [self.lastReadContainerView addSubview:label];
        }
        offset += 20;
    } else {
        [self.lastReadContainerView removeFromSuperview];
        self.lastReadContainerView = nil;
    }
    
  if (model.showTimeLabel) {
    if (self.timeLabel == nil) {
      self.timeLabel = [[UILabel alloc] init];
      _timeLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:14];
        _timeLabel.textColor = [UIColor colorWithHexString:@"0xb3b3b3"];
      
      [self.contentView addSubview:self.timeLabel];
    }
    _timeLabel.hidden = NO;
    _timeLabel.text = [WFCUUtilities formatTimeDetailLabel:model.message.serverTime];

    
    CGSize size = [WFCUUtilities getTextDrawingSize:_timeLabel.text font:_timeLabel.font constrainedSize:CGSizeMake(screenWidth, 8000)];
    CGRect rect = CGRectMake((screenWidth - size.width)/2, offset + 7, size.width, size.height);
    _timeLabel.frame = rect;
  } else {
    _timeLabel.hidden = YES;
  }
}


@end
