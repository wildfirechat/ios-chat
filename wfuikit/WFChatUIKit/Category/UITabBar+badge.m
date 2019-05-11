//
//  UITabBar+badge.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/12.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "UITabBar+badge.h"
#import "TabbarButton.h"

#define TabbarItemNums 4



@implementation UITabBar (badge)

- (void)showBadgeOnItemIndex:(int)index{
    [self showBadgeOnItemIndex:index badgeValue:0];
}

- (void)showBadgeOnItemIndex:(int)index badgeValue:(int)badgeValue{
    //移除之前的小红点
    [self removeBadgeOnItemIndex:index];
    
    if (badgeValue > 0) {
        //新建小红点
        CGRect tabFrame = self.frame;
        //确定小红点的位置
        float percentX = (index + 0.5) / TabbarItemNums;
        CGFloat x = ceilf(percentX * tabFrame.size.width) + 8;
        CGFloat y = ceilf(0.07 * tabFrame.size.height) - 5;
        if (badgeValue <= 0) {
            [self initUnreadCountButton:CGRectMake(x, y, 10, 10) tag:888+index badgeValue:0];
        }
        if (badgeValue < 10 && badgeValue > 0) {
            [self initUnreadCountButton:CGRectMake(x, y, 18, 18) tag:888+index badgeValue:badgeValue];
        }
        if (badgeValue >= 10 && badgeValue < 100 ) {
            [self initUnreadCountButton:CGRectMake(x, y, 22, 18) tag:888+index badgeValue:badgeValue];
        }
        if (badgeValue >= 100) {
            TabbarButton *btn = [[TabbarButton alloc] initWithFrame:CGRectMake(x, y, 22, 18)];
            UIImage *image = [[UIImage imageNamed:@"more_unread"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [btn setImage:image forState:UIControlStateNormal];
            [self addSubview:btn];
            btn.tag = 888+index;
            // btn.layer.cornerRadius = 9;//圆形
        }
    }
}

//隐藏小红点
- (void)hideBadgeOnItemIndex:(int)index{
    //移除小红点
    [self removeBadgeOnItemIndex:index];
}

//移除小红点
- (void)removeBadgeOnItemIndex:(int)index{
    //按照tag值进行移除
    for (UIView *subView in self.subviews) {
        if (subView.tag == 888+index) {
            [((TabbarButton *)subView).shapeLayer removeFromSuperlayer];
            [subView removeFromSuperview];
        }
    }
}

-(void)initUnreadCountButton:(CGRect)frame tag:(NSUInteger)tag badgeValue:(int)badgeValue
{
    TabbarButton *btn = [[TabbarButton alloc] initWithFrame:frame];
    [self addSubview:btn];
    btn.tag = tag;
    btn.layer.cornerRadius = frame.size.height / 2.f;//圆形
    NSString *value = @"";
    if (badgeValue > 0) {
        value = [NSString stringWithFormat:@"%d",badgeValue];
    } else {
        btn.userInteractionEnabled = NO;
    }
    btn.unreadCount = value;
}

@end

