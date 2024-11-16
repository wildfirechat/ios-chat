//
//  WatermarkViewController.m
//  WFChatUIKit
//
//  Created by Rain on 16/11/2024.
//  Copyright © 2024 Tom Lee. All rights reserved.
//

#import "WatermarkViewController.h"

@interface WatermarkViewController ()

@end

@implementation WatermarkViewController
 
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化水印视图
    self.watermarkView = [[UIView alloc] init];
    
//    // 设置水印视图的背景颜色为半透明（你可以根据需要调整颜色和透明度）
//    self.watermarkView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
//    
//    // 添加水印标签
//    UILabel *watermarkLabel = [[UILabel alloc] init];
//    watermarkLabel.text = @"Watermark";
//    watermarkLabel.textColor = [UIColor whiteColor];
//    watermarkLabel.font = [UIFont systemFontOfSize:24];
//    watermarkLabel.textAlignment = NSTextAlignmentCenter;
//    
//    // 将水印标签添加到水印视图中
//    [self.watermarkView addSubview:watermarkLabel];
//    
//    // 设置水印标签的位置（这里我们将其放置在覆盖视图的中心）
//    watermarkLabel.translatesAutoresizingMaskIntoConstraints = NO;
//    [NSLayoutConstraint activateConstraints:@[
//        [watermarkLabel.centerXAnchor constraintEqualToAnchor:self.watermarkView.centerXAnchor],
//        [watermarkLabel.centerYAnchor constraintEqualToAnchor:self.watermarkView.centerYAnchor]
//    ]];
    
    // 将覆盖视图添加到当前视图控制器的视图中
    [self.view addSubview:self.watermarkView];
    
//    // 设置覆盖视图的位置和大小（这里我们将其设置为与父视图相同）
//    self.watermarkView.translatesAutoresizingMaskIntoConstraints = NO;
//    [NSLayoutConstraint activateConstraints:@[
//        [self.watermarkView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
//        [self.watermarkView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
//        [self.watermarkView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
//        [self.watermarkView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
//    ]];
}
 
@end
