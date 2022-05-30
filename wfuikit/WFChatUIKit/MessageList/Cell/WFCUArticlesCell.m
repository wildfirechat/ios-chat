//
//  WFCUArticlesCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/1.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUArticlesCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"
#import "UILabel+YBAttributeTextTapAction.h"
#import <SDWebImage/SDWebImage.h>
#import "UIColor+YH.h"

@interface WFCUArticlesCell ()
@property(nonatomic, strong)UIView *containerView;
@property(nonatomic, strong)UIImageView *coverImageView;
@property(nonatomic, strong)UILabel *topTitleLabel;


@property(nonatomic, strong)NSMutableArray<UIView *> *itemViews;

@property(nonatomic, strong)UIView *subArticleViewContainer;

@end
//CELL左右的margin
#define CELL_MARGIN 32
//CELL上下的margin
#define CELL_MARGIN_TOP 8
#define CELL_MARGIN_BUTTOM 16
//Cell的左右padding
#define CELL_PADDING 16
//Cell的上部的padding
#define CELL_PADDING_TOP 8
//Cell的底部的padding
#define CELL_PADDING_BUTTOM 12
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

#define TOP_TITLE_FONT_SIZE 16
#define TITLE_FONT_SIZE 16
#define FONT_SIZE 14
#define EX_FONT_SIZE 14

#define EX_FW_WIDTH 28

#define SUB_COVER_SIZE 44
#define SUB_TITLE_FONT_SIZE 14

#define COVER_HW_RATE 0.35

@implementation WFCUArticlesCell
+ (CGSize)sizeForCell:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCArticlesMessageContent *content = (WFCCArticlesMessageContent *)msgModel.message.content;
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
    CGFloat coverHeight = containerWidth * COVER_HW_RATE;
    CGFloat labHeight = 0;
    if(content.subArticles.count) {
        labHeight = (SUB_COVER_SIZE + CELL_ITEM_PADDING) * content.subArticles.count;
    } else {
        CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.topArticle.title font:[UIFont systemFontOfSize:TOP_TITLE_FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, 50)];
        labHeight = CELL_ITEM_PADDING;
        labHeight += titleSize.height;
    }
    
    return CGSizeMake(width, CELL_MARGIN_TOP + CELL_PADDING_TOP + coverHeight + labHeight + CELL_PADDING_BUTTOM + CELL_MARGIN_BUTTOM);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];
    [self containerView];
    WFCCArticlesMessageContent *content = (WFCCArticlesMessageContent *)model.message.content;
    CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
    __block CGFloat offset = CELL_PADDING_TOP;
    [self removeAllItems];

    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:content.topArticle.cover]];
    offset += self.coverImageView.frame.size.height;
    offset += CELL_ITEM_PADDING;
    
    CGRect frame = self.topTitleLabel.frame;
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.topArticle.title font:[UIFont systemFontOfSize:TOP_TITLE_FONT_SIZE] constrainedSize:CGSizeMake(containerWidth-CELL_PADDING-CELL_PADDING, 50)];
    frame.size.height = titleSize.height;
    
    if(content.subArticles.count) {
        frame.origin.y = self.coverImageView.frame.size.height - titleSize.height - CELL_ITEM_PADDING;
        [content.subArticles enumerateObjectsUsingBlock:^(WFCCArticle * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGFloat height = [self addArticle:obj offset:offset containerWidth:containerWidth index:idx];
            offset += height;
            offset += CELL_ITEM_PADDING;
        }];
        offset -= CELL_ITEM_PADDING;
    } else {
        frame.origin.y = offset;
        offset += frame.size.height;
    }
    self.topTitleLabel.frame = frame;
    self.topTitleLabel.text = content.topArticle.title;
    
    
    offset += CELL_PADDING_BUTTOM;
    
    frame = self.containerView.frame;
    frame.size.height = offset;
    self.containerView.frame = frame;
}

- (CGFloat)addArticle:(WFCCArticle *)article offset:(CGFloat)offset containerWidth:(CGFloat)containerWidth index:(NSUInteger)index {
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, offset, containerWidth, SUB_COVER_SIZE)];
    container.tag = index;
    [self.itemViews addObject:container];
    [self.containerView addSubview:container];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, (SUB_COVER_SIZE - SUB_TITLE_FONT_SIZE - SUB_TITLE_FONT_SIZE)/2, containerWidth - CELL_PADDING*3 - SUB_COVER_SIZE, SUB_TITLE_FONT_SIZE * 2)];
    subTitle.numberOfLines = 2;
    subTitle.font = [UIFont systemFontOfSize:SUB_TITLE_FONT_SIZE];
    subTitle.text = article.title;
    [container addSubview:subTitle];
    
    UIImageView *subCover = [[UIImageView alloc] initWithFrame:CGRectMake(containerWidth - CELL_PADDING - SUB_COVER_SIZE, 0, SUB_COVER_SIZE, SUB_COVER_SIZE)];
    [subCover sd_setImageWithURL:[NSURL URLWithString:article.cover]];
    [container addSubview:subCover];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapArticle:)];
    [container addGestureRecognizer:tap];
    tap.cancelsTouchesInView = NO;
    [container setUserInteractionEnabled:YES];
    
    return SUB_COVER_SIZE;
}

- (void)didTapCell:(UITapGestureRecognizer *)tap {
    WFCCArticlesMessageContent *content = (WFCCArticlesMessageContent *)self.model.message.content;
    WFCCArticle *article = content.topArticle;
    if ([self.delegate respondsToSelector:@selector(didTapArticleCell:withModel:withArticle:)]) {
        [self.delegate didTapArticleCell:self withModel:self.model withArticle:article];
    }
}

- (void)didTapArticle:(UITapGestureRecognizer *)tap {
    WFCCArticlesMessageContent *content = (WFCCArticlesMessageContent *)self.model.message.content;
    WFCCArticle *article = content.subArticles[tap.view.tag];
    if ([self.delegate respondsToSelector:@selector(didTapArticleCell:withModel:withArticle:)]) {
        [self.delegate didTapArticleCell:self withModel:self.model withArticle:article];
    }
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
        CGFloat containerWidth = [UIScreen mainScreen].bounds.size.width - CELL_MARGIN - CELL_MARGIN;
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(CELL_MARGIN, CELL_MARGIN_TOP, containerWidth, 0)];
        _containerView.backgroundColor = [UIColor whiteColor];
        _containerView.layer.masksToBounds = YES;
        _containerView.layer.cornerRadius = 5.f;
        
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTaped:)];
        doubleTapGesture.numberOfTapsRequired = 2;
        doubleTapGesture.numberOfTouchesRequired = 1;
        [_containerView addGestureRecognizer:doubleTapGesture];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapCell:)];
        [_containerView addGestureRecognizer:tap];
        [tap requireGestureRecognizerToFail:doubleTapGesture];
        tap.cancelsTouchesInView = NO;
        [_containerView setUserInteractionEnabled:YES];
        
        _coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, containerWidth, containerWidth * COVER_HW_RATE)];
        [_containerView addSubview:_coverImageView];
        
        _topTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CELL_PADDING, 0, containerWidth - CELL_PADDING - CELL_PADDING, TOP_TITLE_FONT_SIZE * 2)];
        _topTitleLabel.numberOfLines = 2;
        _topTitleLabel.font = [UIFont systemFontOfSize:TOP_TITLE_FONT_SIZE];
        [_containerView addSubview:_topTitleLabel];
        
        [self.contentView addSubview:_containerView];
    }
    return _containerView;
}

@end
