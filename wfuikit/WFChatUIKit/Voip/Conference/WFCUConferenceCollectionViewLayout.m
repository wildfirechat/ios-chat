//
//  WFCUConferenceCollectionViewLayout.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/21.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUConferenceCollectionViewLayout.h"

@interface WFCUConferenceCollectionViewLayout ()
@property (strong, nonatomic) NSMutableArray * attrubutesArray;
@end

@implementation WFCUConferenceCollectionViewLayout
- (void)prepareLayout {
    [super prepareLayout];
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    self.attrubutesArray = [NSMutableArray array];
    CGRect rect = CGRectZero;
    rect.size = self.collectionView.bounds.size;

    if(self.audioOnly) {
        for (int i = 0; i < count; i ++) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            attributes.frame = CGRectMake(i * rect.size.width, 0, rect.size.width, rect.size.height);
            [self.attrubutesArray addObject:attributes];
        }
    } else {
        CGFloat width = rect.size.width/2;
        CGFloat height = rect.size.height/2;
        
        int lastPageCount = (count - 1)%4;
        int lastPageFirstIndex = (int)count - lastPageCount;
        for (int i = 0; i < count; i ++) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            
            CGRect frame;
            if(i == 0) {
                frame = rect;
            } else {
                int page = [self pageByRow:i];
                CGFloat startX = page * rect.size.width;
                int index = (i -1)%4;
                CGFloat x = startX;
                CGFloat y = 0;
//                if(i < lastPageFirstIndex) {
                    if(index == 1 || index == 3) {
                        x += width;
                    }
                    if(index == 2 || index == 3) {
                        y += height;
                    }
//                } else {
//                    if(lastPageCount == 1) {
//                        x += width/2;
//                        y += height/2;
//                    } else if(lastPageCount == 2) {
//                        x += index * width;
//                        y += height/2;
//                    } else {
//                        if(index == 2) {
//                            x += width/2;
//                            y += height;
//                        } else if(index == 1) {
//                            x += width;
//                        }
//                    }
//                }
                frame = CGRectMake(x , y, width, height);
            }
            attributes.frame = frame;
            [self.attrubutesArray addObject:attributes];
        }
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.attrubutesArray[indexPath.row];
}

- (CGSize)collectionViewContentSize {
    if(self.audioOnly) {
        return CGSizeMake(self.attrubutesArray.count * self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    } else {
        if(self.attrubutesArray.count == 1 || self.attrubutesArray.count == 2) {
            return self.collectionView.bounds.size;
        }
        int page = [self pageByRow:self.attrubutesArray.count - 1];
        
        return CGSizeMake((page + 1) * self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return _attrubutesArray;
}

- (int)pageByRow:(int)row {
    if(self.audioOnly) {
        return (row-1)/12;
    }
    if(row == 0){
        return 0;
    }
    return (row -1)/4 + 1;
}

- (NSMutableArray<NSIndexPath *> *)itemsInPage:(int)page {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    if(page == 0) {
        [arr addObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    } else {
        for (int i = (page-1)*4 +1; i <= MIN(page*4, count-1); i++) {
            [arr addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    
    return arr;
}

- (CGPoint)getOffsetOfItems:(NSArray<NSIndexPath *> *)items {
    if(!items.count) {
        return CGPointMake(0, 0);
    }
    
    int minRow = 0x1FFFFFFF;
    int maxRow = 0;
    for (NSIndexPath *indexPath in items) {
        if(indexPath.row < minRow) {
            minRow = (int)indexPath.row;
        }
        if(indexPath.row > maxRow) {
            maxRow = (int)indexPath.row;
        }
    }
    
    CGFloat width = self.collectionView.bounds.size.width;
    
    float start;
    
    int pageRight = [self pageByRow:maxRow];
    float end = pageRight * width;
    
    int pageLeft = 0;
    if(minRow == 0) {
        start = 0;
    } else {
        pageLeft = [self pageByRow:minRow];
        start = pageLeft * width;
    }
    
    return CGPointMake(start, end);
}
@end
