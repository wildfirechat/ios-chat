//
//  WFCUConferenceAudioCollectionViewCell.m
//  WFChatUIKit
//
//  Created by Rain on 2022/10/5.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUConferenceAudioCollectionViewCell.h"
#import "WFCUConferenceParticipantCollectionViewCell.h"
#import <WFAVEngineKit/WFAVEngineKit.h>

@interface WFCUConferenceAudioCollectionViewCell () <UICollectionViewDataSource, UICollectionViewDelegate>
@property(nonatomic, strong)UICollectionView *collectionView;

@property(nonatomic, strong)NSMutableArray<WFAVParticipantProfile *> *participants;
@property(nonatomic, assign)NSUInteger pages;
@end

@implementation WFCUConferenceAudioCollectionViewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setupView:frame];
    }
    return self;
}

- (void)setupView:(CGRect)frame {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWidth = ([UIScreen mainScreen].bounds.size.width - flowLayout.minimumInteritemSpacing*2)/3-5;
    flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
//    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerClass:[WFCUConferenceParticipantCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    [self addSubview:self.collectionView];
}

- (void)setProfiles:(NSMutableArray<WFAVParticipantProfile *> *)participants pages:(NSUInteger)pages {
    self.participants = participants;
    self.pages = pages;
    
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat minimumInteritemSpacing = flowLayout.minimumInteritemSpacing;
    CGFloat minimumLineSpacing = flowLayout.minimumLineSpacing;
    
    CGSize parentSize = self.bounds.size;
    int itemCount = MIN(12, self.participants.count - self.pages*12);
    CGFloat itemWidth = (MIN(parentSize.width, parentSize.height) - flowLayout.minimumInteritemSpacing*2)/3-5;
    
    
    CGFloat startX, startY, widht, height;

    if(parentSize.width > parentSize.height) {
        if(itemCount == 1) {
            startX = parentSize.width/2 - itemWidth/2;
            widht = itemWidth;
        } else if(itemCount == 2) {
            startX = parentSize.width/2 - itemWidth - minimumInteritemSpacing/2;
            widht = itemWidth*2 + minimumInteritemSpacing;
        } else if(itemCount == 3){
            startX = parentSize.width/2 - itemWidth - itemWidth/2 - minimumInteritemSpacing;
            widht = itemWidth*3 + minimumInteritemSpacing*2;
        } else /*if(itemCount >= 4)*/ {
            startX = parentSize.width/2 - itemWidth*2 - minimumInteritemSpacing - minimumInteritemSpacing/2;
            widht = itemWidth*4 + minimumInteritemSpacing*3;
        }
        
        if(itemCount <= 4) {
            startY = parentSize.height/2 - itemWidth/2 - minimumLineSpacing;
            height = itemWidth + minimumLineSpacing * 2;
        } else if(itemCount <= 8) {
            startY = parentSize.height/2 - itemWidth - minimumLineSpacing - minimumInteritemSpacing/2;
            height = itemWidth*2 + minimumLineSpacing*2 + minimumInteritemSpacing;
        } else /*if(itemCount <= 12)*/ {
            startY = 0;
            height = parentSize.height;
        }
    } else {
        if(itemCount == 1) {
            startX = parentSize.width/2 - itemWidth/2;
            widht = itemWidth;
        } else if(itemCount == 2 || itemCount == 4) {
            startX = itemWidth/2 - minimumInteritemSpacing/2;
            widht = itemWidth*2 + minimumInteritemSpacing;
        } else {
            startX = 0;
            widht = parentSize.width;
        }
        
        if(itemCount <= 3) {
            startY = parentSize.height/2 - itemWidth/2 - minimumLineSpacing;
            height = itemWidth + minimumLineSpacing * 2;
        } else if(itemCount <= 6) {
            startY = parentSize.height/2 - itemWidth - minimumLineSpacing - minimumInteritemSpacing/2;
            height = itemWidth*2 + minimumLineSpacing*2 + minimumInteritemSpacing;
        } else if(itemCount <= 9) {
            startY = parentSize.height/2 - itemWidth - itemWidth/2 - minimumLineSpacing - minimumInteritemSpacing - minimumInteritemSpacing/2;
            height = itemWidth*3 + minimumLineSpacing *2 + minimumInteritemSpacing + minimumInteritemSpacing/2;
        } else /*if(itemCount <= 12)*/ {
            startY = parentSize.height/2 - itemWidth - itemWidth - minimumLineSpacing - minimumInteritemSpacing*2;
            height = itemWidth*4 - minimumLineSpacing*2 - minimumInteritemSpacing*2;
        }
    }
    
    self.collectionView.frame = CGRectMake(startX, startY, widht, height);
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return MIN(12, self.participants.count - self.pages*12);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WFCUConferenceParticipantCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    WFAVParticipantProfile *profile = self.participants[self.pages*12 + indexPath.row];
    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:profile.userId refresh:NO];
    [cell setUserInfo:userInfo callProfile:profile];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}
@end
