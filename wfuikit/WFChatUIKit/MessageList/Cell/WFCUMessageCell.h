//
//  MessageCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WFCUMessageCellBase.h"

@interface WFCUMessageCell : WFCUMessageCellBase
+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width;
@property (nonatomic, strong)UIImageView *portraitView;
@property (nonatomic, strong)UILabel *nameLabel;
@property (nonatomic, strong)UIImageView *bubbleView;
@property (nonatomic, strong)UIView *contentArea;
@property (nonatomic, strong)UIView *quoteContainer;
@property (nonatomic, strong)UILabel *quoteLabel;
- (void)setMaskImage:(UIImage *)maskImage;
@end
