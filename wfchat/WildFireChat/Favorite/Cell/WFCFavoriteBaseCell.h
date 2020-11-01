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
@end

NS_ASSUME_NONNULL_END
