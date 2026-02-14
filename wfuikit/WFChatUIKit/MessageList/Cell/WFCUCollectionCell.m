//
//  WFCUCollectionCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCUCollectionCell.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"

#define TITLE_FONT_SIZE 16
#define DESC_FONT_SIZE 13
#define ENTRY_FONT_SIZE 14
#define COUNT_FONT_SIZE 12
#define PADDING 8
#define LINE_SPACING 4
#define MAX_ENTRIES_TO_SHOW 5

@interface WFCUCollectionCell ()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIView *entriesContainer;
@property (nonatomic, strong) NSMutableArray<UILabel *> *entryLabels;
@property (nonatomic, strong) UILabel *moreLabel;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, strong) UILabel *actionLabel;
@end

@implementation WFCUCollectionCell

+ (UIFont *)titleFont {
    return [UIFont boldSystemFontOfSize:TITLE_FONT_SIZE];
}

+ (UIFont *)descFont {
    return [UIFont systemFontOfSize:DESC_FONT_SIZE];
}

+ (UIFont *)entryFont {
    return [UIFont systemFontOfSize:ENTRY_FONT_SIZE];
}

+ (UIFont *)countFont {
    return [UIFont systemFontOfSize:COUNT_FONT_SIZE];
}

+ (CGSize)sizeForClientArea:(WFCUMessageModel *)msgModel withViewWidth:(CGFloat)width {
    WFCCCollectionMessageContent *content = (WFCCCollectionMessageContent *)msgModel.message.content;

    CGFloat height = 0;
    CGFloat contentWidth = width - PADDING * 2;

    // 标题区域高度
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.title
                                                    font:[self titleFont]
                                           constrainedSize:CGSizeMake(contentWidth - 24, 40)];
    height += MAX(titleSize.height, 20) + PADDING;

    // 描述区域高度（如果有）
    if (content.desc.length > 0) {
        CGSize descSize = [WFCUUtilities getTextDrawingSize:content.desc
                                                       font:[self descFont]
                                              constrainedSize:CGSizeMake(contentWidth, 60)];
        height += descSize.height + LINE_SPACING;
    }

    // 分隔线
    height += 1 + LINE_SPACING;

    // 参与列表高度（最多显示5条）
    int entriesToShow = (int)MIN(content.entries.count, MAX_ENTRIES_TO_SHOW);
    if (entriesToShow == 0) {
        // 显示"暂无参与"
        height += 20 + LINE_SPACING;
    } else {
        for (int i = 0; i < entriesToShow; i++) {
            WFCCCollectionEntry *entry = content.entries[i];
            NSString *entryText = [NSString stringWithFormat:@"%d. %@", i + 1, entry.content];
            CGSize entrySize = [WFCUUtilities getTextDrawingSize:entryText
                                                            font:[self entryFont]
                                                   constrainedSize:CGSizeMake(contentWidth, 30)];
            height += MAX(entrySize.height, 18) + LINE_SPACING;
        }
    }

    // 更多提示
    if (content.entries.count > MAX_ENTRIES_TO_SHOW) {
        height += 16 + LINE_SPACING;
    }

    // 分隔线
    height += 1 + LINE_SPACING;

    // 操作按钮区域
    height += 24 + PADDING;

    return CGSizeMake(width, height);
}

- (void)setModel:(WFCUMessageModel *)model {
    [super setModel:model];

    WFCCCollectionMessageContent *content = (WFCCCollectionMessageContent *)model.message.content;
    CGFloat width = self.contentArea.bounds.size.width;
    CGFloat contentWidth = width - PADDING * 2;
    CGFloat currentY = PADDING;

    // 设置图标
    self.iconImageView.frame = CGRectMake(PADDING, currentY, 18, 18);

    // 设置标题
    CGSize titleSize = [WFCUUtilities getTextDrawingSize:content.title
                                                    font:[[self class] titleFont]
                                           constrainedSize:CGSizeMake(contentWidth - 24 - 60, 40)];
    self.titleLabel.frame = CGRectMake(PADDING + 22, currentY, titleSize.width, MAX(titleSize.height, 20));
    self.titleLabel.text = content.title;

    // 设置人数
    NSString *countText = [NSString stringWithFormat:WFCString(@"CollectionParticipantCount"), content.participantCount];
    self.countLabel.text = countText;
    CGSize countSize = [WFCUUtilities getTextDrawingSize:countText
                                                    font:[[self class] countFont]
                                           constrainedSize:CGSizeMake(60, 20)];
    self.countLabel.frame = CGRectMake(width - PADDING - countSize.width, currentY + 3, countSize.width, countSize.height);

    currentY += MAX(titleSize.height, 20) + LINE_SPACING;

    // 设置描述（如果有）
    if (content.desc.length > 0) {
        CGSize descSize = [WFCUUtilities getTextDrawingSize:content.desc
                                                       font:[[self class] descFont]
                                              constrainedSize:CGSizeMake(contentWidth, 60)];
        self.descLabel.frame = CGRectMake(PADDING, currentY, contentWidth, descSize.height);
        self.descLabel.text = content.desc;
        self.descLabel.hidden = NO;
        currentY += descSize.height + LINE_SPACING;
    } else {
        self.descLabel.hidden = YES;
    }

    // 分隔线1
    self.separatorLine.frame = CGRectMake(PADDING, currentY, contentWidth, 0.5);
    currentY += 1 + LINE_SPACING;

    // 清空旧的 entry labels
    for (UILabel *label in self.entryLabels) {
        [label removeFromSuperview];
    }
    [self.entryLabels removeAllObjects];

    // 设置参与列表
    int entriesToShow = (int)MIN(content.entries.count, MAX_ENTRIES_TO_SHOW);
    if (entriesToShow == 0) {
        UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, currentY, contentWidth, 20)];
        emptyLabel.font = [[self class] entryFont];
        emptyLabel.textColor = [UIColor grayColor];
        emptyLabel.text = WFCString(@"CollectionEmptyHint");
        [self.contentArea addSubview:emptyLabel];
        [self.entryLabels addObject:emptyLabel];
        currentY += 20 + LINE_SPACING;
    } else {
        for (int i = 0; i < entriesToShow; i++) {
            WFCCCollectionEntry *entry = content.entries[i];
            NSString *entryText = [NSString stringWithFormat:@"%d. %@", i + 1, entry.content];
            CGSize entrySize = [WFCUUtilities getTextDrawingSize:entryText
                                                            font:[[self class] entryFont]
                                                   constrainedSize:CGSizeMake(contentWidth, 30)];
            UILabel *entryLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, currentY, contentWidth, MAX(entrySize.height, 18))];
            entryLabel.font = [[self class] entryFont];
            entryLabel.text = entryText;
            entryLabel.numberOfLines = 0;
            [self.contentArea addSubview:entryLabel];
            [self.entryLabels addObject:entryLabel];
            currentY += MAX(entrySize.height, 18) + LINE_SPACING;
        }
    }

    // 更多提示
    if (content.entries.count > MAX_ENTRIES_TO_SHOW) {
        int moreCount = (int)(content.entries.count - MAX_ENTRIES_TO_SHOW);
        self.moreLabel.text = [NSString stringWithFormat:WFCString(@"CollectionMoreParticipants"), moreCount];
        self.moreLabel.frame = CGRectMake(PADDING, currentY, contentWidth, 16);
        self.moreLabel.hidden = NO;
        currentY += 16 + LINE_SPACING;
    } else {
        self.moreLabel.hidden = YES;
    }

    // 分隔线2
    currentY += 1;

    // 操作按钮
    NSString *actionText;
    if (content.status == 1) {
        actionText = WFCString(@"CollectionStatusEnded");
    } else if (content.status == 2) {
        actionText = WFCString(@"CollectionStatusCancelled");
    } else {
        // 统一显示"参与接龙"
        actionText = WFCString(@"CollectionJoinAction");
    }
    self.actionLabel.text = actionText;
    self.actionLabel.frame = CGRectMake(PADDING, currentY, contentWidth, 24);

    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.contentArea addGestureRecognizer:tapGesture];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(didTapMessageCell:withModel:)]) {
        [self.delegate didTapMessageCell:self withModel:self.model];
    }
}

#pragma mark - Lazy Loading

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.image = [UIImage systemImageNamed:@"list.bullet.clipboard"] ?: [UIImage imageNamed:@"collection_icon"];
        _iconImageView.tintColor = [UIColor systemBlueColor];
        [self.contentArea addSubview:_iconImageView];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [[self class] titleFont];
        _titleLabel.numberOfLines = 0;
        [self.contentArea addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [[self class] countFont];
        _countLabel.textColor = [UIColor grayColor];
        _countLabel.textAlignment = NSTextAlignmentRight;
        [self.contentArea addSubview:_countLabel];
    }
    return _countLabel;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.font = [[self class] descFont];
        _descLabel.textColor = [UIColor grayColor];
        _descLabel.numberOfLines = 0;
        [self.contentArea addSubview:_descLabel];
    }
    return _descLabel;
}

- (UIView *)separatorLine {
    if (!_separatorLine) {
        _separatorLine = [[UIView alloc] init];
        _separatorLine.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [self.contentArea addSubview:_separatorLine];
    }
    return _separatorLine;
}

- (NSMutableArray<UILabel *> *)entryLabels {
    if (!_entryLabels) {
        _entryLabels = [NSMutableArray array];
    }
    return _entryLabels;
}

- (UILabel *)moreLabel {
    if (!_moreLabel) {
        _moreLabel = [[UILabel alloc] init];
        _moreLabel.font = [[self class] countFont];
        _moreLabel.textColor = [UIColor lightGrayColor];
        [self.contentArea addSubview:_moreLabel];
    }
    return _moreLabel;
}

- (UILabel *)actionLabel {
    if (!_actionLabel) {
        _actionLabel = [[UILabel alloc] init];
        _actionLabel.font = [UIFont systemFontOfSize:14];
        _actionLabel.textColor = [UIColor systemBlueColor];
        _actionLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentArea addSubview:_actionLabel];
    }
    return _actionLabel;
}

@end
