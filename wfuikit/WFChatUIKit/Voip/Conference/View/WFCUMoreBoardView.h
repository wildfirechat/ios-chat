//
//  WFCUMoreBoardView.h
//  WFChatUIKit
//
//  Created by Rain on 2022/9/28.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MoreItem : NSObject
@property(nonatomic, strong)UIImage *image;
@property(nonatomic, strong)NSString *title;
@property(nonatomic, strong)MoreItem *(^onClicked)(void);
- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image callback:(MoreItem *(^)(void))onClicked;
@end

@interface WFCUMoreBoardView : UIView
- (instancetype)initWithItems:(NSArray<MoreItem *> *)items cancel:(void(^)(WFCUMoreBoardView *boardView))cancelBlock;
@end

NS_ASSUME_NONNULL_END
