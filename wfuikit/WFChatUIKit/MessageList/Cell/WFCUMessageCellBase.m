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
#import "WFCUUtilities.h"

@implementation WFCUMessageCellBase
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
  return CGSizeMake(width, 80);
}

+ (CGFloat)hightForHeaderArea:(WFCUMessageModel *)msgModel {
    CGFloat offset;
    if (msgModel.showTimeLabel) {
        offset = 30;
    } else {
        offset = 5;
    }

    if (msgModel.lastReadMessage) {
        offset += 30;
    }
    return offset;
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
            self.lastReadContainerView = [[UIView alloc] initWithFrame:CGRectMake(16, offset, screenWidth-32, 20)];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.text = WFCString(@"last_read_here");
            label.font = [UIFont systemFontOfSize:16];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor grayColor];
            label.layer.cornerRadius = 5.f;
            label.layer.masksToBounds = YES;
            CGSize size = [WFCUUtilities getTextDrawingSize:label.text font:label.font constrainedSize:CGSizeMake(screenWidth-16, 8000)];
            size.width += 16;
            label.frame = CGRectMake((screenWidth - 32 - size.width)/2,  (20-size.height)/2, size.width, size.height);
            [self.lastReadContainerView addSubview:label];
            
            
            UIView *leftline = [[UIView alloc] initWithFrame:CGRectMake(0, 10, (screenWidth-32-size.width)/2-8, 1)];
            leftline.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.f];
            [self.lastReadContainerView addSubview:leftline];
            
            UIView *rightline = [[UIView alloc] initWithFrame:CGRectMake((screenWidth-32 + size.width)/2 + 8, 10, (screenWidth-32-size.width)/2-8, 1)];
            rightline.backgroundColor = leftline.backgroundColor;
            [self.lastReadContainerView addSubview:rightline];
            
            [self.contentView addSubview:self.lastReadContainerView];
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
    CGRect rect = CGRectMake((screenWidth - size.width)/2, offset + 5, size.width, size.height);
    _timeLabel.frame = rect;
  } else {
    _timeLabel.hidden = YES;
  }
}


@end
