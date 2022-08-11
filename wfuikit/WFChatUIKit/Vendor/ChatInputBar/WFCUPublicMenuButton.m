//
//  WFCUPublicMenuButton.m
//  WFChatUIKit
//
//  Created by Rain on 2022/8/11.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUPublicMenuButton.h"
#import "WFCUImage.h"
#import "WFCUConfigManager.h"

@interface WFCUPublicMenuButton ()
@property(nonatomic, strong)NSMutableArray *subMenuViews;
@property(nonatomic, assign)BOOL isSubMenu;
@end

@implementation WFCUPublicMenuButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(onclicked:) forControlEvents:UIControlEventTouchUpInside];
        self.expended = NO;
        self.isSubMenu = NO;
        self.subMenuViews = [[NSMutableArray alloc] init];
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
        for (int i = 0; i < self.channelMenu.subMenus.count; i++) {
            WFCCChannelMenu *subMenu = self.channelMenu.subMenus[i];
            WFCUPublicMenuButton *menuBtn = [[WFCUPublicMenuButton alloc] initWithFrame:CGRectMake(0, -(i+1) * parentRect.size.height, parentRect.size.width, parentRect.size.height)];
            [menuBtn setChannelMenu:subMenu isSubMenu:YES];
            menuBtn.delegate = self.delegate;
            [self addSubview:menuBtn];
            [self.subMenuViews addObject:menuBtn];
        }
    } else {
        [self.subMenuViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [obj removeFromSuperview];
        }];
        [self.subMenuViews removeAllObjects];
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
        
    }
}
@end
