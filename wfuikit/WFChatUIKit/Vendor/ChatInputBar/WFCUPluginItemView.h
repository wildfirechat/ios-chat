//
//  PluginItemView.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/29.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUPluginItemView : UIView
@property(nonatomic, strong)UIImageView *imageView;
@property(nonatomic, strong)UILabel *titleLabel;
@property (nonatomic,copy) void (^onItemClicked)(void);
// 置灰禁用：图片/标题变灰、点击不响应（AI 不在线时的 "AI 会话设置" 入口）
@property (nonatomic, assign) BOOL disabled;
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image frame:(CGRect)frame;
@end
