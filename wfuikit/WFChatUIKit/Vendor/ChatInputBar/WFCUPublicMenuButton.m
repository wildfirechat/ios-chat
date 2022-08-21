//
//  WFCUPublicMenuButton.m
//  WFChatUIKit
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 WildFireChat. All rights reserved.
//

#import "WFCUPublicMenuButton.h"
#import "WFCUImage.h"
#import "WFCUConfigManager.h"

@interface WFCUPublicMenuButton ()
@property(nonatomic, strong)NSMutableArray *subMenuViews;
@property(nonatomic, assign)BOOL isSubMenu;
@property(nonatomic, strong)UIView *subMenuContainer;
@end

@implementation WFCUPublicMenuButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(onclicked:) forControlEvents:UIControlEventTouchUpInside];
        self.expended = NO;
        self.isSubMenu = NO;
        self.subMenuViews = [[NSMutableArray alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:16];
    }
    return self;
}

- (void)onclicked:(id)sender {
    self.expended = !self.expended;
    if ([self.delegate respondsToSelector:@selector(didTapButton:menu:)]) {
        [self.delegate didTapButton:self menu:self.channelMenu];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    if (self.isSubMenu) {
        return view;
    }
    if (view == nil){
        for(WFCUPublicMenuButton *subMenuView in self.subMenuViews) {
        //转换坐标
            CGPoint tempPoint = [subMenuView convertPoint:point fromView:self];
           //判断点击的点是否在按钮区域内
            if (CGRectContainsPoint(subMenuView.bounds, tempPoint)){
                //返回按钮
                return subMenuView;
            }
        }
    }
    return view;
}

- (void)setExpended:(BOOL)expended {
    _expended = expended;
    if (!self.channelMenu.subMenus.count) {
        return;
    }
    
    if (expended) {
        CGRect parentRect = self.bounds;
        
        CGPoint temPoint = [self convertPoint:CGPointMake(parentRect.size.width, 0) toView:self.superview.superview];
        BOOL rightEdge = temPoint.x >= [UIScreen mainScreen].bounds.size.width - 3;
        self.subMenuContainer = [[UIView alloc] initWithFrame:CGRectMake(rightEdge ? -16 : -8, -1 * (self.channelMenu.subMenus.count * parentRect.size.height) - self.channelMenu.subMenus.count + 1, parentRect.size.width+8, self.channelMenu.subMenus.count*parentRect.size.height+self.channelMenu.subMenus.count-1)];
        self.backgroundColor = [UIColor whiteColor];
        self.subMenuContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.subMenuContainer.layer.shadowOpacity = 0.8f;
        [self addSubview:self.subMenuContainer];
        for (int i = 0; i < self.channelMenu.subMenus.count; i++) {
            WFCCChannelMenu *subMenu = self.channelMenu.subMenus[i];
            WFCUPublicMenuButton *menuBtn = [[WFCUPublicMenuButton alloc] initWithFrame:CGRectMake(0, i * parentRect.size.height + i - 1, parentRect.size.width+16, parentRect.size.height)];
            [menuBtn setChannelMenu:subMenu isSubMenu:YES];
            menuBtn.delegate = self.delegate;
            [self.subMenuContainer addSubview:menuBtn];
            [self.subMenuViews addObject:menuBtn];
            if (i != self.channelMenu.subMenus.count - 1) {
                UIView *splitbg = [[UIView alloc] initWithFrame:CGRectMake(0, (i+1) * parentRect.size.height + i - 1, parentRect.size.width+16, 1)];
                splitbg.backgroundColor = self.backgroundColor;
                [self.subMenuContainer addSubview:splitbg];
                
                UIView *split = [[UIView alloc] initWithFrame:CGRectMake(8, (i+1) * parentRect.size.height + i - 1, parentRect.size.width, 1)];
                split.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.9];
                [self.subMenuContainer addSubview:split];
            }
        }
    } else {
        [self.subMenuContainer removeFromSuperview];
        self.subMenuContainer = nil;
    }
}

- (void)setChannelMenu:(WFCCChannelMenu *)channelMenu isSubMenu:(BOOL)isSubMenu {
    self.channelMenu = channelMenu;
    self.isSubMenu = isSubMenu;
    [self setTitle:channelMenu.name forState:UIControlStateNormal];
    [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    if (!isSubMenu && channelMenu.subMenus.count) {
        [self setImage:[WFCUImage imageNamed:@"sub_menu"] forState:UIControlStateNormal];
    }
    if (isSubMenu) {
        self.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
//        self.backgroundColor = [UIColor whiteColor];
    }
}
@end
