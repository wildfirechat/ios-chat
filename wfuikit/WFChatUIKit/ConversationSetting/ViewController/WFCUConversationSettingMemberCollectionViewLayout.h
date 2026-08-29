//
//  ConversationSettingMemberCollectionViewLayout.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WFCUConversationSettingMemberCollectionViewLayout : UICollectionViewFlowLayout
- (instancetype)initWithItemMargin:(CGFloat)itemMargin;
/// 排版基准宽度。0（默认）表示按屏幕宽排，即 iPhone 上的原行为；
/// iPad 双栏下这张宫格在右栏里，调用方要把栏宽写进来，否则 5 列按整屏宽排会溢出栏外。
@property(nonatomic, assign) CGFloat layoutWidth;

/// 每行几个。iPhone 恒为 5；iPad 上按 layoutWidth 反推，保证单格不会大到离谱
/// （对应 android `values-sw600dp` 里 wfc_member_grid_span 由 5 改成 8 的那一条）。
/// 「最多显示几行」这类上限要按它算，别再写死 5。
@property(nonatomic, assign, readonly) int itemsPerLine;

- (CGFloat)getHeigthOfItemCount:(int)itemCount;
@end
