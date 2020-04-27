//
//  BubbleTipView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/12.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BubbleTipView : UIView

@property(nonatomic, copy) NSString *bubbleTipText;

@property(nonatomic, assign) CGSize bubbleTipTextShadowOffset;

@property(nonatomic, strong) UIColor *bubbleTipTextShadowColor;

@property(nonatomic, strong) UIFont *bubbleTipTextFont;

@property(nonatomic, strong) UIColor *bubbleTipBackgroundColor;
@property(nonatomic, assign) CGPoint bubbleTipPositionAdjustment;

@property(nonatomic, assign) CGRect frameToPositionInRelationWith;

@property(nonatomic) BOOL isShowNotificationNumber;

- (instancetype)initWithSuperView:(UIView *)parentView;

- (void)setBubbleTipNumber:(int)msgCount;
@end
