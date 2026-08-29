//
//  WFCUCompositeBaseCell.h
//  WFChatUIKit
//
//  Created by Tom Lee on 2020/10/4.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WFCCMessage;
NS_ASSUME_NONNULL_BEGIN

#define COMPOSITE_CELL_PORTRAIT_WIDTH 48
#define COMPOSITE_CELL_PORTRAIT_PADDING 16

#define COMPOSITE_CELL_TOP_PADDING 12
#define COMPOSITE_CELL_BUTTOM_PADDING 8
#define COMPOSITE_CELL_RIGHT_PADDING 12

#define COMPOSITE_CELL_NAME_LABEL_HEIGHT 20
#define COMPOSITE_CELL_NAME_LABEL_FONT 14

#define COMPOSITE_CELL_TIME_LABEL_WIDTH 80
#define COMPOSITE_CELL_TIME_LABEL_HEIGHT 20
#define COMPOSITE_CELL_TIME_LABEL_FONT 12

#define COMPOSITE_CELL_NAME_CONTENT_PADDING 8

#define COMPOSITE_CELL_LINE_HEIGHT 1

@interface WFCUCompositeBaseCell : UITableViewCell
+ (instancetype)cellOfMessage:(WFCCMessage *)message;
+ (CGFloat)heightForMessage:(WFCCMessage *)message;

//子类需要实现这个方法来计算内容区大小
+ (CGFloat)heightForMessageContent:(WFCCMessage *)message;

@property(nonatomic, strong)WFCCMessage *message;
@property(nonatomic, assign)BOOL hiddenPortrait;
@property(nonatomic, assign)BOOL lastMessage;

+ (CGRect)contentFrame;

/// 这一屏（合并消息详情）的可用宽度。cell 里全是手写 frame，宽度只能从外面给。
/// 默认 0 表示按屏幕宽算，即 iPhone 上的原行为；iPad 双栏下这一页在右栏里，
/// 由 WFCUCompositeMessageViewController 在布局时写进来。
+ (void)setListWidth:(CGFloat)width;
+ (CGFloat)listWidth;
@end

NS_ASSUME_NONNULL_END
