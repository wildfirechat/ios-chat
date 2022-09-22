//
//  WFCUConferenceCollectionViewLayout.m
//  WFChatUIKit
//
//  Created by Rain on 2022/9/21.
//  Copyright © 2022 Tom Lee. All rights reserved.
//

#import "WFCUConferenceCollectionViewLayout.h"

@interface WFCUConferenceCollectionViewLayout ()
@property (strong, nonatomic) NSMutableArray * attrubutesArray;
@end

@implementation WFCUConferenceCollectionViewLayout
- (void)prepareLayout {
    [super prepareLayout];
    NSInteger count = [self.collectionView numberOfItemsInSection:0];

    CGRect rect = CGRectZero;
    rect.size = self.collectionView.bounds.size;
    
    const CGFloat width = rect.size.width/2;
    const CGFloat height = rect.size.height/2;
    
    self.attrubutesArray = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i ++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes * attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

        CGRect frame;
        if(i == 0) {
            frame = rect;
        } else {
            int page = (int)(i - 1)/4 + 1;
            CGFloat startX = page * rect.size.width;
            int index = (i -1)%4;
            CGFloat x = startX;
            CGFloat y = 0;
            if(index == 1 || index == 3) {
                x += width;
            }
            if(index == 2 || index == 3) {
                y += height;
            }
            frame = CGRectMake(x , y, width, height);
        }
        attributes.frame = frame;
        
        
        [self.attrubutesArray addObject:attributes];
    }
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.attrubutesArray[indexPath.row];
}

- (CGSize)collectionViewContentSize {
    UICollectionViewLayoutAttributes * attributes = [self.attrubutesArray lastObject];
    CGFloat width = attributes.frame.origin.x + attributes.frame.size.width;
    if((self.attrubutesArray.count-1)%4 == 1 || (self.attrubutesArray.count-1)%4 == 3) {
        width += self.collectionView.frame.size.width/2;
    }
    
    return CGSizeMake(width, self.collectionView.bounds.size.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return _attrubutesArray;
}
    
@end
