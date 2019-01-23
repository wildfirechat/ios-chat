//
//  KZVideoListViewController.m
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/21.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import "KZVideoListViewController.h"
#import "KZVideoSupport.h"
#import "KZVideoConfig.h"
@interface KZVideoListViewController ()<UICollectionViewDelegate, UICollectionViewDataSource> {

    UILabel *_titleLabel;
    
    KZCloseBtn *_leftBtn;
    UIButton *_rightBtn;

}

@property (nonatomic, weak)  UICollectionView *collectionView;

@property (nonatomic, strong)  NSMutableArray *dataArr;

@property (nonatomic, assign) KZVideoViewShowType showType;

@end

static KZVideoListViewController *__currentListVC = nil;

@implementation KZVideoListViewController

- (void)showAnimationWithType:(KZVideoViewShowType)showType {
    _showType = showType;
    [self setupSubViews];
    __currentListVC = self;
    UIWindow *keyWindow = [UIApplication sharedApplication].delegate.window;
//    _actionView.transform = _showType == KZVideoViewShowTypeSmall ? CGAffineTransformScale(CGAffineTransformIdentity, 1.6, 1.6): CGAffineTransformMakeTranslation(0, CGRectGetHeight([KZVideoConfig viewFrameWithType:showType]));
    _actionView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.6, 1.6);
    _actionView.alpha = 0.0;
    [keyWindow addSubview:_actionView];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _actionView.transform = CGAffineTransformIdentity;
        _actionView.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    [self setupCollectionView];
}

- (void)closeAnimation {
    __weak typeof (self) blockSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _actionView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, _actionView.bounds.size.width);
        _actionView.alpha = .0;
    } completion:^(BOOL finished) {
        if (self.didCloseBlock) {
            self.didCloseBlock();
        }
        [blockSelf closeView];
    }];
}

- (void)closeView {
    [_collectionView removeFromSuperview];
    _collectionView = nil;
    [_actionView removeFromSuperview];
    _actionView = nil;
    [_dataArr removeAllObjects];
    _dataArr = nil;
    __currentListVC = nil;
}
- (void)dealloc {
//    NSLog(@"dalloc listView");
}

- (void)setupSubViews {
    CGFloat btnTopEdge = _showType == KZVideoViewShowTypeSingle ? 20:0;
    CGFloat topBarHeight = _showType == KZVideoViewShowTypeSingle ? 44 : 40;
    
    _actionView = [[UIView alloc] initWithFrame:[KZVideoConfig viewFrameWithType:_showType]];
    _actionView.backgroundColor = [UIColor clearColor];
    [KZVideoConfig motionBlurView:_actionView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, btnTopEdge, _actionView.frame.size.width, topBarHeight)];
    _titleLabel.textColor = kzThemeGraryColor;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.font = [UIFont systemFontOfSize:16];
    _titleLabel.text = @"小视频";
    [_actionView addSubview:_titleLabel];
    
    _leftBtn = [[KZCloseBtn alloc] initWithFrame:CGRectMake(0, btnTopEdge, 60, topBarHeight)];
    _leftBtn.backgroundColor = [UIColor clearColor];
    [_leftBtn addTarget:self action:@selector(closeViewAction) forControlEvents:UIControlEventTouchUpInside];
    _leftBtn.gradientColors = [KZVideoConfig gradualColors];
    [_actionView addSubview:_leftBtn];
    
    
    _rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(_actionView.frame.size.width - 60, btnTopEdge, 60, topBarHeight)];
    [_rightBtn setTitle:@"编辑" forState: UIControlStateNormal];
    [_rightBtn setTitle:@"完成" forState: UIControlStateSelected];
    [_rightBtn setTitleColor:kzThemeTineColor forState:UIControlStateNormal];
    [_rightBtn setTitleColor:kzThemeTineColor forState:UIControlStateSelected];
    [_rightBtn addTarget:self action:@selector(editVideosAction) forControlEvents:UIControlEventTouchUpInside];
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame = _rightBtn.bounds;
    gradLayer.colors = [KZVideoConfig gradualColors];
    [_rightBtn.layer addSublayer:gradLayer];
    gradLayer.mask = _rightBtn.titleLabel.layer;

    [_actionView addSubview:_rightBtn];
}

static NSString *cellId = @"Cell";
static NSString *addCellId = @"AddCell";
static NSString *footerId = @"footer";

- (void)setupCollectionView {
    self.dataArr = [NSMutableArray arrayWithArray:[KZVideoUtil getSortVideoList]];
    CGFloat itemWidth = (_actionView.frame.size.width - 40)/3;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 8;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth/kzVideo_w_h);
    layout.sectionInset = UIEdgeInsetsMake(10, 8, 10, 8);
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_titleLabel.frame), _actionView.frame.size.width, _actionView.frame.size.height - _titleLabel.frame.size.height) collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    [collectionView registerClass:[KZVideoListCell class] forCellWithReuseIdentifier:cellId];
    [collectionView registerClass:[KZAddNewVideoCell class] forCellWithReuseIdentifier:addCellId];
    [collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerId];
    collectionView.backgroundColor = [UIColor clearColor];
    [self.actionView addSubview:collectionView];
    self.collectionView = collectionView;
}

#pragma mark - Actions --
- (void)closeViewAction {
    [self closeAnimation];
}
- (void)editVideosAction {
    _rightBtn.selected = !_rightBtn.selected;
    [_collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_rightBtn.selected) {
        return self.dataArr.count;
    }
    else {
        return self.dataArr.count+1;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.dataArr.count) {
        KZAddNewVideoCell *addCell = [collectionView dequeueReusableCellWithReuseIdentifier:addCellId forIndexPath:indexPath];
        return addCell;
    }
    
    KZVideoListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    KZVideoModel *model = self.dataArr[indexPath.item];
    cell.videoModel = model;
    [cell setEdit:_rightBtn.selected];
    __weak typeof(self) blockSelf = self;
    __weak typeof(collectionView) blockCollection = collectionView;
    cell.deleteVideoBlock = ^(KZVideoModel *cellModel){
        
        NSInteger index = [blockSelf.dataArr indexOfObject:cellModel];
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:index inSection:0];
        [blockSelf.dataArr removeObject:cellModel];
        [blockCollection deleteItemsAtIndexPaths:@[cellIndexPath]];
        [KZVideoUtil deleteVideo:cellModel.videoAbsolutePath];
        
    };
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:footerId forIndexPath:indexPath];
        if (footerView.subviews.count < 1) {
            KZVideoModel *lastVideo = _dataArr.lastObject;
            NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:lastVideo.recordTime];
            if (time < 0) {
                time = 0;
            }
            NSInteger day = time/60/60/24 + 1;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_actionView.frame), 20)];
            label.textColor = kzThemeGraryColor;
            label.font = [UIFont systemFontOfSize:14];
            label.textAlignment = NSTextAlignmentCenter;
            label.text = [NSString stringWithFormat:@"最近 %ld 天拍摄的小视频",(long)day];
            label.alpha = 0.6;
            [footerView addSubview:label];
        }
        return footerView;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(_actionView.frame), 20);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.dataArr.count) {
        [self closeAnimation];
    }
    else {
        if (self.selectBlock) {
            self.selectBlock(self.dataArr[indexPath.item]);
        }
        [self closeAnimation];
    }
}

@end
