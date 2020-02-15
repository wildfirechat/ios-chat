//
//  WFCUParticipantCollectionViewLayout.m
//  WFChatUIKit
//
//  Created by dali on 2020/1/21.
//  Copyright © 2020 Tom Lee. All rights reserved.
//
#if WFCU_SUPPORT_VOIP
#import "WFCUParticipantCollectionViewLayout.h"

@interface WFCUParticipantCollectionViewLayout ()
@property (assign, nonatomic) UIEdgeInsets sectionInsets;

@property (strong, nonatomic) NSMutableArray * attrubutesArray;   //所有元素的布局信
@end

@implementation WFCUParticipantCollectionViewLayout
- (void)prepareLayout {
    [super prepareLayout];
    NSInteger count = [self.collectionView numberOfItemsInSection:0];

    int column = 0;
    int line = 0;
    if (count == 1) {
        column = 1;
        line = 1;
    } else if(count <= 4) {
        column = 2;
        if (count <= 2) {
            line = 1;
        } else {
            line = 2;
        }
    } else {
        column = 3;
        if (count <= 6) {
            line = 2;
        } else {
            line = 3;
        }
    }
    
    CGRect collectionViewRect = self.collectionView.bounds;
    
    CGPoint line1Start;
    int line1Number = (int)count - (line - 1) * column;
    line1Start.x = (collectionViewRect.size.width - (line1Number * (self.itemWidth + self.itemSpace) - self.itemSpace))/2;
    line1Start.y = (collectionViewRect.size.height - (line *(self.itemHeight + self.lineSpace) - self.lineSpace))/2;
    
    int line2Number = line1Number + column;
    int line3Number = line2Number + column;
    
    CGPoint line2Start = CGPointZero;
    CGPoint line3Start = CGPointZero;
    self.attrubutesArray = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i ++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

        
        CGRect frame = CGRectMake(0, 0, self.itemWidth, self.itemHeight);
        if (i < line1Number) {
            frame.origin.x = line1Start.x + (self.itemWidth + self.itemSpace)*i;
            frame.origin.y = line1Start.y;
        } else if(i < line2Number) {
            if (line2Start.y == 0) {
                line2Start.x = (collectionViewRect.size.width - (line * (self.itemWidth + self.itemSpace) - self.itemSpace))/2;
                line2Start.y = line1Start.y + self.itemHeight + self.lineSpace;
            }
            frame.origin.x = line2Start.x + (self.itemWidth + self.itemSpace)*(i-line1Number);
            frame.origin.y = line2Start.y;
        } else if(i < line3Number) {
            if (line3Start.y == 0) {
                line3Start.x = line2Start.x;
                line3Start.y = line2Start.y + self.itemHeight + self.lineSpace;
            }
            frame.origin.x = line3Start.x + (self.itemWidth + self.itemSpace)*(i-line2Number);
            frame.origin.y = line3Start.y;
        }
        
        attributes.frame = frame;
        
        
        [self.attrubutesArray addObject:attributes];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.attrubutesArray[indexPath.row];
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.bounds.size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return _attrubutesArray;
}
@end
#endif
