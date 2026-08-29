//
//  ConversationSettingMemberCollectionViewLayout.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUConversationSettingMemberCollectionViewLayout.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUPadUtility.h"

/// 单个头像格的最大宽度。取自 android 平板那份 `values-sw600dp/integers.xml`：
/// `wfc_member_grid_span` 手机 5、平板 8，平板右栏约 768dp 时每格正好 96dp。
/// iPad 上如果继续按「栏宽的 1/5」排，一个头像能有 140pt 宽，比列表行还高。
static const CGFloat kWFCUMemberItemMaxWidth = 96.f;

@interface WFCUConversationSettingMemberCollectionViewLayout()
@property(nonatomic, strong) NSMutableArray *attributesArray;
@property(nonatomic, assign, readonly) CGFloat itemAreaWidth;
@property(nonatomic, assign, readonly) CGFloat itemWidth;
@property(nonatomic, assign) CGFloat itemMargin;
@end

@implementation WFCUConversationSettingMemberCollectionViewLayout

- (instancetype)initWithItemMargin:(CGFloat)itemMargin {
    self = [super init];
    if (self) {
        self.itemMargin = itemMargin;
    }
    return self;
}

//排版基准宽度。layoutWidth 未设时退回屏幕宽 —— iPhone 上宫格本来就铺满整屏，取值与改之前相同。
//iPad 双栏下这张宫格在右栏里，按屏幕宽排会溢出栏外（缺陷 #7），由调用方把栏宽交给 layoutWidth。
//不再缓存：栏宽会随旋转/分屏变，缓存住就再也纠不回来了；这里就是一次除法。
- (CGFloat)layoutBaseWidth {
    return self.layoutWidth > 0 ? self.layoutWidth : [UIScreen mainScreen].bounds.size.width;
}

//每行几个。iPhone 恒为 5 —— 这里显式按机型分叉而不是只靠公式：最宽的 iPhone 竖屏 440pt
//算出来也还是 5，但横屏 926pt 会算成 10，那就不是「零变化」了。
//iPad 上按「每格不超过 kWFCUMemberItemMaxWidth」反推列数，下限仍是 5
//（iPad 收成 Slide Over 时栏很窄，再少就成了大头贴）。
//栏宽 704pt（12.9 寸横屏减去左栏）算出 8 列，与 android 平板那份 span=8 对上。
- (int)itemsPerLine {
    if (![WFCUPadUtility isPad]) {
        return 5;
    }
    CGFloat width = [self layoutBaseWidth];
    if (width <= 0) {
        return 5;
    }
    return MAX(5, (int)ceil(width / kWFCUMemberItemMaxWidth));
}

- (CGFloat)itemAreaWidth {
    return [self layoutBaseWidth] / self.itemsPerLine;
}
- (CGFloat)itemWidth {
    return self.itemAreaWidth - self.itemMargin - self.itemMargin;
}
- (void)prepareLayout {
    int itemCount = (int)[self.collectionView numberOfItemsInSection:0];
    if (itemCount == 0) {
        [super prepareLayout];
        return;
    }
    
    self.attributesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < itemCount; i++) {
        int row = i / self.itemsPerLine;
        int column = i % self.itemsPerLine;
        
        UICollectionViewLayoutAttributes *attributes =
        [UICollectionViewLayoutAttributes
         layoutAttributesForCellWithIndexPath:[NSIndexPath
                                               indexPathForItem:i
                                               inSection:0]];

        attributes.frame = CGRectMake(column * self.itemAreaWidth + self.itemMargin,
                                      row * self.itemAreaWidth + self.itemMargin,
                                      self.itemWidth,
                                      self.itemWidth);
        
        [self.attributesArray addObject:attributes];
    }
    self.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    [super prepareLayout];
}
- (CGFloat)getHeigthOfItemCount:(int)itemCount {
    if (itemCount == 0) {
        return 0;
    } else {
        int lines = (itemCount - 1) / self.itemsPerLine + 1;
        CGFloat height = self.itemAreaWidth * lines;
        height += 12;
        if([[WFCCIMService sharedWFCIMService] isMeshEnabled]) {
            height += 10;
        }
        return height;
    }
}
- (CGSize)collectionViewContentSize {
    return CGSizeMake([self collectionView].frame.size.width, [self getHeigthOfItemCount:(int)[self.collectionView numberOfItemsInSection:0]]);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:
(NSIndexPath *)path {
    UICollectionViewLayoutAttributes *attributes =
    [self.attributesArray objectAtIndex:[path row]];
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0];
         i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    return attributes;
}
@end
