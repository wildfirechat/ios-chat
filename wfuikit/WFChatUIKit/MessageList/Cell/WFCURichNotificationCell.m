//
//  WFCURichNotificationCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCURichNotificationCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"

@interface WFCURichNotificationCell ()
@property(nonatomic, strong)UIView *containerView;
@property(nonatomic, strong)UILabel *titleLabel;
@property(nonatomic, strong)UILabel *descLabel;
@property(nonatomic, strong)NSMutableArray<UIView *> *itemViews;
@property(nonatomic, strong)UILabel *remarkLabel;

@property(nonatomic, strong)UIView *exView;
@property(nonatomic, strong)UIView *exLine;
@property(nonatomic, strong)UILabel *exName;
@property(nonatomic, strong)UIImageView *exFWView;
@property(nonatomic, strong)UIImageView *exPortraitView;
@end
//CELL左右的margin
#define CELL_MARGIN 32
//CELL上下的margin
#define CELL_MARGIN_TOP_BUTTOM 8
//Cell的左右padding
#define CELL_PADDING 16
//Cell的上部的padding
#define CELL_PADDING_TOP 8
//Cell的底部的padding
#define CELL_PADDING_BUTTOM 8
//描述和Item的padding
#define CELL_DESC_ITEM_PADDING 16
//Item之间的padding
#define CELL_ITEM_PADDING 8
//Item和下部line的padding
#define CELL_ITEM_LINE_PADDING 4
//Key Label的宽度
#define KEY_WIDTH 80
//Value Label距离左边侧的Padding（包括KEY_WIDTH）
#define VALUE_BOARD_PADDING_LEFT 86
//Value Label距离右边侧的Padding
#define VALUE_BOARD_PADDING_RIGHT CELL_PADDING

#define EX_LINE_WIDTH 0.5

#define TITLE_FONT_SIZE 16
#define FONT_SIZE 14
#define EX_FONT_SIZE 14

#define EX_FW_WIDTH 28

@implementation WFCURichNotificationCell
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCRichNotificationMessageContent *content = (WFCCRichNotificationMessageContent *)msgModel.message.content;
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.title font:[UIFont systemFontOfSize:TITLE_FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, 50)];
    
    
    CGSize descSize = [WFCUUtilities getTextDrawingSize:content.desc font:[UIFont systemFontOfSize:FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, 50)];
    
    CGFloat itemsHeight = 0;
    for (NSDictionary<NSString*, NSString*> *data in content.datas) {
        NSString *value = data[@"value"];
        CGSize itemSize = [WFCUUtilities getTextDrawingSize:value font:[UIFont systemFontOfSize:FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING-VALUE_BOARD_PADDING_LEFT, 50)];
        itemsHeight += itemSize.height;
        itemsHeight += CELL_ITEM_PADDING;
    }
    if(content.datas.count) {
        itemsHeight -= CELL_ITEM_PADDING;
    }
    itemsHeight += CELL_ITEM_LINE_PADDING;
    
    
    CGSize remarkSize = [WFCUUtilities getTextDrawingSize:content.remark font:[UIFont systemFontOfSize:FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, 50)];
    
    
    CGSize exSize = CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, content.exName.length ? EX_FONT_SIZE + CELL_ITEM_PADDING + CELL_PADDING_BUTTOM + EX_LINE_WIDTH : 0);
    
    CGFloat height = CELL_MARGIN_TOP_BUTTOM + CELL_PADDING_TOP + titleSize.height + CELL_ITEM_PADDING + descSize.height + CELL_DESC_ITEM_PADDING + itemsHeight + (remarkSize.height > 0 ? remarkSize.height + CELL_ITEM_PADDING : 0) + exSize.height + CELL_PADDING_BUTTOM + CELL_MARGIN_TOP_BUTTOM;
    
    return CGSizeMake(width, height);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    [self removeAllItems];
    WFCCRichNotificationMessageContent *content = (WFCCRichNotificationMessageContent *)model.message.content;
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
    CGFloat offset = CELL_PADDING_TOP;
    
    CGFloat height = [self setLabel:self.titleLabel widht:containerWidth-CELL_PADDING-CELL_PADDING text:content.title offset:offset fontSize:TITLE_FONT_SIZE];
    offset += height;
    offset += CELL_ITEM_PADDING;
    
    height = [self setLabel:self.descLabel widht:containerWidth-CELL_PADDING-CELL_PADDING text:content.desc offset:offset fontSize:FONT_SIZE];
    offset += height;
    offset += CELL_DESC_ITEM_PADDING;
    
    for (NSDictionary<NSString*, NSString*> *data in content.datas) {
        NSString *key = data[@"key"];
        NSString *value = data[@"value"];
        NSString *colorStr = data[@"color"];
        [self addKeyLabel:offset text:key];
        
        height = [self addValueLabel:offset text:value color:colorStr];
        
        offset += height;
        offset += CELL_ITEM_PADDING;
    }
    
    if(content.remark.length) {
        height = [self setLabel:self.remarkLabel widht:containerWidth-CELL_PADDING-CELL_PADDING text:content.remark offset:offset fontSize:FONT_SIZE];
        offset += height;
        offset += CELL_DESC_ITEM_PADDING;
        self.remarkLabel.hidden = NO;
    } else {
        self.remarkLabel.hidden = YES;
    }
    
    if(content.datas.count) {
        offset -= CELL_ITEM_PADDING;
    }
    offset += CELL_ITEM_LINE_PADDING;
    
    if(content.exName.length) {
        self.exView.hidden = NO;
        self.exName.text = content.exName;
        CGRect frame = self.exView.frame;
        frame.origin.y = offset;
        self.exView.frame = frame;
        
        [self.exPortraitView sd_setImageWithURL:[NSURL URLWithString:content.exPortrait] placeholderImage:[UIImage imageNamed:@"default_app_icon"]];
        
        offset += self.exView.frame.size.height;
    } else {
        self.exView.hidden = YES;
    }
    CGRect frame = self.containerView.frame;
    frame.size.height = offset;
    self.containerView.frame = frame;
}

- (void)addKeyLabel:(CGFloat)offset text:(NSString *)text {
    UILabel *keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, offset, KEY_WIDTH, FONT_SIZE)];
    keyLabel.text = [NSString stringWithFormat:@"%@:", text];
    keyLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    keyLabel.textColor = [UIColor grayColor];
    [self.containerView addSubview:keyLabel];
    [self.itemViews addObject:keyLabel];
}

- (CGFloat)addValueLabel:(CGFloat)offset text:(NSString *)text color:(NSString *)colorStr {
    UIColor *color = colorStr.length ? [UIColor colorWithHexString:colorStr] : [UIColor grayColor];
    if(color == [UIColor clearColor]) {
        color = [UIColor grayColor];
    }
    
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
    CGSize itemSize = [WFCUUtilities getTextDrawingSize:text font:[UIFont systemFontOfSize:FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING-VALUE_BOARD_PADDING_LEFT, 50)];
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING+VALUE_BOARD_PADDING_LEFT, offset, containerWidth-CELL_PADDING-CELL_PADDING-VALUE_BOARD_PADDING_LEFT, itemSize.height)];
    valueLabel.text = text;
    valueLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    valueLabel.numberOfLines = 0;
    valueLabel.textColor = color;
    [self.containerView addSubview:valueLabel];
    [self.itemViews addObject:valueLabel];
    return itemSize.height;
}

- (void)removeAllItems {
    [self.itemViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    [self.itemViews removeAllObjects];
}

- (CGFloat)setLabel:(UILabel *)label widht:(CGFloat)width text:(NSString *)text offset:(CGFloat)offset fontSize:(int)fontSize {
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:text font:[UIFont systemFontOfSize:fontSize] constrainedSize:CGSizeMake(width, 50)];
    label.text = text;
    CGRect frame = label.frame;
    frame.origin.y = offset;
    frame.size.height = titleSize.height;
    label.frame = frame;
    label.numberOfLines = 0;
    return titleSize.height;
}
-(NSMutableArray<UIView *> *)itemViews {
    if(!_itemViews) {
        _itemViews = [[NSMutableArray alloc] init];
    }
    return _itemViews;
}

- (UIView *)containerView {
    if(!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(CELL_MARGIN, CELL_MARGIN_TOP_BUTTOM, [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN, 0)];
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.layer.masksToBounds = YES;
        _containerView.layer.cornerRadius = 5.f;
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTaped:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [_containerView addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTaped:)];
        [_containerView addGestureRecognizer:tap];
        [tap requireGestureRecognizerToFail:doubleTapGesture];
        tap.cancelsTouchesInView = NO;
        [_containerView setUserInteractionEnabled:YES];
        
        [self.contentView addSubview:_containerView];
    }
    return _containerView;
}

- (UILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, CELL_PADDING_TOP, [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN - CELL_PADDING - CELL_PADDING, TITLE_FONT_SIZE)];
        [_titleLabel setFont:[UIFont systemFontOfSize:TITLE_FONT_SIZE]];
        [_titleLabel setTextColor:[UIColor blackColor]];
        [self.containerView addSubview:_titleLabel];
    }
    return _titleLabel;
}

-(UILabel *)descLabel {
    if(!_descLabel) {
        _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, CELL_PADDING_TOP, [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN - CELL_PADDING - CELL_PADDING, FONT_SIZE)];
        [_descLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
        [_descLabel setTextColor:[UIColor grayColor]];
        [self.containerView addSubview:_descLabel];
    }
    return _descLabel;
}

-(UILabel *)remarkLabel {
    if(!_remarkLabel) {
        _remarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, CELL_PADDING_TOP, [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN - CELL_PADDING - CELL_PADDING, FONT_SIZE)];
        [_remarkLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
        [_remarkLabel setTextColor:[UIColor grayColor]];
        [self.containerView addSubview:_remarkLabel];
    }
    return _remarkLabel;
}

- (UIView *)exView {
    if(!_exView) {
        _exView = [[UILabel alloc] initWithFrame:CGRectMake(0, CELL_PADDING_TOP, [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN, EX_FONT_SIZE + CELL_ITEM_PADDING + CELL_PADDING_BUTTOM + EX_LINE_WIDTH)];
        
        _exLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _exView.frame.size.width, 0.5)];
        _exLine.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.9];
        [_exView addSubview:_exLine];
        
        _exFWView = [[UIImageView alloc] initWithFrame:CGRectMake(_exView.frame.size.width - CELL_PADDING - EX_FW_WIDTH, EX_LINE_WIDTH, EX_FW_WIDTH, EX_FW_WIDTH)];
        _exFWView.image = [UIImage imageNamed:@"forward_normal"];
        [_exView addSubview:_exFWView];
        
        _exPortraitView = [[UIImageView alloc] initWithFrame:CGRectMake(CELL_PADDING, EX_LINE_WIDTH + (EX_FW_WIDTH - EX_FONT_SIZE)/2, EX_FONT_SIZE, EX_FONT_SIZE)];
        [_exView addSubview:_exPortraitView];
        
        [self.containerView addSubview:_exView];
    }
    return _exView;
}

-(UILabel *)exName {
    if(!_exName) {
        _exName = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING + EX_FW_WIDTH, EX_LINE_WIDTH+CELL_ITEM_PADDING, self.exView.frame.size.width - CELL_PADDING - CELL_PADDING - EX_FW_WIDTH - EX_FW_WIDTH, EX_FONT_SIZE)];
        _exName.font = [UIFont systemFontOfSize:EX_FONT_SIZE];
        [self.exView addSubview:_exName];
    }
    return _exName;
}
@end
