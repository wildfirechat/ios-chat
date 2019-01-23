//
//  TabbarButton.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/12.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
/** tabbar移除未读数红点儿时候发送的通知，object是当前选中的tabbar的index */
FOUNDATION_EXPORT NSString *const kTabBarClearBadgeNotification;

@interface TabbarButton : UIButton

/** 大圆脱离小圆的最大距离 */
@property (nonatomic, assign) CGFloat maxDistance;

/** 小圆 */
@property (nonatomic, strong) UIView *samllCircleView;

/** 按钮消失的动画图片组 */
@property (nonatomic, strong) NSMutableArray *images;

/** 未读数 */
@property (nonatomic, strong) NSString *unreadCount;

@property (nonatomic, strong) UIImage *unreadCountImage;

/** 绘制不规则图形 */
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@end
