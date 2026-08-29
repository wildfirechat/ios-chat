//
//  WFCFavoriteBaseCell.h
//  WildFireChat
//
//  Created by Tom Lee on 2020/11/1.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatUIKit/WFChatUIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCFavoriteBaseCell : UITableViewCell
@property(nonatomic, strong)WFCUFavoriteItem *favoriteItem;
@property(nonatomic, strong)UIView *contentArea;

//子类实现，必须重新返回内容区高度
+ (CGFloat)contentHeight:(WFCUFavoriteItem *)favoriteItem;

//基类实现，不能重写
+ (CGFloat)heightOf:(WFCUFavoriteItem *)favoriteItem;

/// 排版基准宽度。收藏列表在算行高之前把表宽写进来 —— iPad 双栏下这张表在右栏里，
/// 继续按整屏宽量文字高度会量少，长文本被切掉一截。
/// 0（默认）表示按屏幕宽，即 iPhone 上的原行为。
+ (void)setLayoutWidth:(CGFloat)layoutWidth;
+ (CGFloat)layoutWidth;
@end

NS_ASSUME_NONNULL_END
