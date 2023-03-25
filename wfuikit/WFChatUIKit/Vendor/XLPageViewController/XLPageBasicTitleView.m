//
//  XLPageBasicTitleView.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/8.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController

#import "XLPageBasicTitleView.h"
#import "XLPageViewControllerUtil.h"
#import "XLPageTitleCell.h"

#pragma mark -
#pragma mark CellModel类
@interface XLPageTitleCellModel : NSObject

@property (nonatomic, assign) CGRect frame;

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

@implementation XLPageTitleCellModel

@end

#pragma mark - 布局类
#pragma mark XLPageBasicTitleViewFolowLayout
@interface XLPageBasicTitleViewFolowLayout : UICollectionViewFlowLayout

@property (nonatomic, assign) XLPageTitleViewAlignment alignment;

@property (nonatomic, assign) UIEdgeInsets originSectionInset;

@property (nonatomic, assign) BOOL haveUpdateInset;

@end

@implementation XLPageBasicTitleViewFolowLayout

//设置标题居中、局左、居右方法
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    if (self.haveUpdateInset) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    CGRect targetRect = rect;
    targetRect.size = self.collectionView.bounds.size;
    //获取屏幕上所有布局文件
    NSArray *attributes = [super layoutAttributesForElementsInRect:targetRect];
    //获取所有item个数
    CGFloat totalItemCount = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    //如果屏幕未被item充满，执行以下布局，否则保持标准布局
    if (attributes.count < totalItemCount) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    self.haveUpdateInset = true;
    //获取第一个cell左边和最后一个cell右边之间的距离
    UICollectionViewLayoutAttributes *firstAttribute = attributes.firstObject;
    UICollectionViewLayoutAttributes *lastAttribute = attributes.lastObject;
    CGFloat attributesFullWidth = CGRectGetMaxX(lastAttribute.frame) - CGRectGetMinX(firstAttribute.frame);
    //计算留白宽度
    CGFloat emptyWidth = self.collectionView.bounds.size.width - attributesFullWidth;
    //设置左缩进
    CGFloat insetLeft = 0;
    if (self.alignment == XLPageTitleViewAlignmentLeft) {
        insetLeft = self.originSectionInset.left;
    }
    if (self.alignment == XLPageTitleViewAlignmentCenter) {
        insetLeft = emptyWidth/2.0f;
    }
    if (self.alignment == XLPageTitleViewAlignmentRight) {
        insetLeft = emptyWidth - self.originSectionInset.right;
    }
    //兼容防止出错，最小缩进设置为原始缩进
    insetLeft = insetLeft <= self.originSectionInset.left ? self.originSectionInset.left : insetLeft;
    //如果和当前缩进一直，则不需要更新缩进
    if (insetLeft == self.sectionInset.left) {
        return [super layoutAttributesForElementsInRect:rect];
    }
    //更新CollectionView缩进
    self.sectionInset = UIEdgeInsetsMake(self.sectionInset.top, insetLeft, self.sectionInset.bottom, self.sectionInset.right);
    //返回
    return [super layoutAttributesForElementsInRect:rect];
}

@end

#pragma mark - 标题类
#pragma mark XLPageBasicTitleView
@interface XLPageBasicTitleView ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

//布局
@property (nonatomic, strong) XLPageBasicTitleViewFolowLayout *layout;

//集合视图
@property (nonatomic, strong) UICollectionView *collectionView;

//配置信息
@property (nonatomic, strong) XLPageViewControllerConfig *config;

//阴影线条
@property (nonatomic, strong) UIView *shadowLine;

//底部分割线
@property (nonatomic, strong) UIView *separatorLine;

//cell的模型
@property (nonatomic, strong) NSMutableArray *cellModels;

@end

@implementation XLPageBasicTitleView

- (instancetype)initWithConfig:(XLPageViewControllerConfig *)config {
    if (self = [super init]) {
        [self initTitleViewWithConfig:config];
    }
    return self;
}

- (void)initTitleViewWithConfig:(XLPageViewControllerConfig *)config {
    
    self.cellModels = [[NSMutableArray alloc] init];
    
    self.config = config;
    
    self.layout = [[XLPageBasicTitleViewFolowLayout alloc] init];
    self.layout.alignment = self.config.titleViewAlignment;
    self.layout.originSectionInset = self.config.titleViewInset;
    self.layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.layout.sectionInset = config.titleViewInset;
    self.layout.minimumInteritemSpacing = config.titleSpace;
    self.layout.minimumLineSpacing = config.titleSpace;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = config.titleViewBackgroundColor;
    [self.collectionView registerClass:[XLPageTitleCell class] forCellWithReuseIdentifier:@"XLPageTitleCell"];
    self.collectionView.showsHorizontalScrollIndicator = false;
    [self addSubview:self.collectionView];
    
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = config.separatorLineColor;
    self.separatorLine.hidden = config.separatorLineHidden;
    [self addSubview:self.separatorLine];
    
    self.shadowLine = [[UIView alloc] init];
    self.shadowLine.bounds = CGRectMake(0, 0, self.config.shadowLineWidth, self.config.shadowLineHeight);
    self.shadowLine.backgroundColor = config.shadowLineColor;
    self.shadowLine.layer.cornerRadius =  self.config.shadowLineHeight/2.0f;
    if (self.config.shadowLineCap == XLPageShadowLineCapSquare) {
        self.shadowLine.layer.cornerRadius = 0;
    }
    self.shadowLine.layer.masksToBounds = true;
    self.shadowLine.hidden = config.shadowLineHidden;
    [self.collectionView addSubview:self.shadowLine];
    
    self.stopAnimation = false;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat collectionW = self.bounds.size.width;
    if (self.rightButton) {
        CGFloat btnW = self.bounds.size.height;
        collectionW = self.bounds.size.width - btnW;
        self.rightButton.frame = CGRectMake(self.bounds.size.width - btnW, 0, btnW, btnW);
    }
    self.collectionView.frame = CGRectMake(0, 0, collectionW, self.bounds.size.height);
    
    self.separatorLine.frame = CGRectMake(0, self.bounds.size.height - self.config.separatorLineHeight, self.bounds.size.width, self.config.separatorLineHeight);
    
    [self fixShadowLineCenter];
    [self.collectionView sendSubviewToBack:self.shadowLine];
    [self bringSubviewToFront:self.separatorLine];
    if (!self.config.shadowLineHidden) {
        self.shadowLine.hidden = [self.dataSource pageTitleViewNumberOfTitle] == 0;
    }
}

#pragma mark -
#pragma mark CollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataSource pageTitleViewNumberOfTitle];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([self widthForItemAtIndexPath:indexPath], collectionView.bounds.size.height - self.config.titleViewInset.top - self.config.titleViewInset.bottom);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XLPageTitleCell *cell = [self.dataSource pageTitleViewCellForItemAtIndex:indexPath.row];
    if (!cell) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"XLPageTitleCell" forIndexPath:indexPath];
    }
    cell.config = self.config;
    cell.textLabel.text = [self.dataSource pageTitleViewTitleForIndex:indexPath.row];
    [cell configCellOfSelected:(indexPath.row == self.selectedIndex)];
    [self addCellModel:indexPath frame:cell.frame];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL switchSuccess = [self.delegate pageTitleViewDidSelectedAtIndex:indexPath.row];
    if (!switchSuccess) {return;}
    self.selectedIndex = indexPath.row;
}

#pragma mark -
#pragma mark 添加CellModel
- (void)addCellModel:(NSIndexPath *)indexPath frame:(CGRect)frame {
    XLPageTitleCellModel *newModel = [[XLPageTitleCellModel alloc] init];
    newModel.frame = frame;
    newModel.indexPath = indexPath;
    bool contain = NO;
    for (XLPageTitleCellModel *model in self.cellModels) {
        if (model.indexPath.row == indexPath.row) {
            contain = YES;
        }
    }
    if (!contain) {
        [self.cellModels addObject:newModel];
    }
}

#pragma mark -
#pragma mark Setter
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [self updateLayout];
}

- (void)setRightButton:(UIButton *)rightButton {
    _rightButton = rightButton;
    [self addSubview:rightButton];
}

- (void)updateLayout {
    
    if (_selectedIndex == _lastSelectedIndex) {return;}
    
    //更新cellUI
    NSIndexPath *currentIndexPath = [NSIndexPath indexPathForRow:_selectedIndex inSection:0];
    XLPageTitleCell *currentCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
    [currentCell configCellOfSelected:YES];
    //延时刷新
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView performWithoutAnimation:^{
            [self.collectionView reloadItemsAtIndexPaths:@[currentIndexPath]];
        }];
    });
    //如果上次选中的index已经不存在了，则无需刷新
    if (_lastSelectedIndex < [self.dataSource pageTitleViewNumberOfTitle]) {
        //更新UI
        NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:_lastSelectedIndex inSection:0];
        XLPageTitleCell *lastCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:lastIndexPath];
        [lastCell configCellOfSelected:NO];
        //延时刷新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView performWithoutAnimation:^{
                [self.collectionView reloadItemsAtIndexPaths:@[lastIndexPath]];
            }];
        });
    }
    
    //自动居中
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:true];
    
    //设置阴影位置
    CGPoint center = [self shadowLineCenterForIndex:_selectedIndex];
    if (center.x <= 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self fixShadowLineCenter];
        });
    }else {
        self.shadowLine.center = center;
    }
    //保存上次选中位置
    _lastSelectedIndex = _selectedIndex;
}

- (void)fixShadowLineCenter {
    if (self.config.titleViewStyle == XLPageTitleViewStyleSegmented) {return;}
    //避免找不到Cell,先滚动到指定位置
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    //避免cell不在屏幕上显示，延时0.01秒加载
    CGPoint shadowCenter = [self shadowLineCenterForIndex:_selectedIndex];
    if (shadowCenter.x > 0) {
        self.shadowLine.center = shadowCenter;
    }else {
        if (self.shadowLine.center.x <= 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                self.shadowLine.center = [self shadowLineCenterForIndex:self.selectedIndex];
            });
        }
    }
}

- (void)setAnimationProgress:(CGFloat)animationProgress {
    if (self.stopAnimation) {return;}
    if (animationProgress == 0) {return;}
    
    //获取下一个index
    NSInteger targetIndex = animationProgress < 0 ? _selectedIndex - 1 : _selectedIndex + 1;
    if (targetIndex < 0 || targetIndex >= [self.dataSource pageTitleViewNumberOfTitle]) {return;}
    
    //获取cell
    XLPageTitleCell *currentCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedIndex inSection:0]];
    XLPageTitleCell *targetCell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:targetIndex inSection:0]];
    
    //标题颜色过渡
    if (self.config.titleColorTransition) {
        
        [currentCell showAnimationOfProgress:fabs(animationProgress) type:XLPageTitleCellAnimationTypeSelected];
        
        [targetCell showAnimationOfProgress:fabs(animationProgress) type:XLPageTitleCellAnimationTypeWillSelected];
    }
    
    //给阴影添加动画
    [XLPageViewControllerUtil showAnimationToShadow:self.shadowLine shadowWidth:self.config.shadowLineWidth fromItemRect:currentCell.frame toItemRect:targetCell.frame type:self.config.shadowLineAnimationType progress:animationProgress];
}

//刷新方法
- (void)reloadData {
    self.layout.haveUpdateInset = false;
    [self.collectionView reloadData];
    if (!self.config.shadowLineHidden) {
        self.shadowLine.hidden = [self.dataSource pageTitleViewNumberOfTitle] == 0;
    }
    [self fixShadowLineCenter];
}

#pragma mark -
#pragma mark 阴影位置
- (CGPoint)shadowLineCenterForIndex:(NSInteger)index {
    XLPageTitleCell *cell = (XLPageTitleCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGRect cellFrame = cell.frame;
    if (!cell) {
        for (XLPageTitleCellModel *model  in self.cellModels) {
            if (model.indexPath.row == index) {
                cellFrame = model.frame;
            }
        }
    }
    CGFloat centerX = CGRectGetMidX(cellFrame);
    CGFloat separatorLineHeight = self.config.separatorLineHidden ? 0 : self.config.separatorLineHeight;
    CGFloat centerY = self.bounds.size.height - self.config.shadowLineHeight/2.0f - separatorLineHeight;
    if (self.config.shadowLineAlignment == XLPageShadowLineAlignmentTop) {
        centerY = self.config.shadowLineHeight/2.0f;
    }
    if (self.config.shadowLineAlignment == XLPageShadowLineAlignmentCenter) {
        centerY = CGRectGetMidY(cellFrame);
    }
    return CGPointMake(centerX, centerY);
}

#pragma mark -
#pragma mark 辅助方法
- (CGFloat)widthForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.config.titleWidth > 0) {
        return self.config.titleWidth;
    }
    
   CGFloat normalTitleWidth = [XLPageViewControllerUtil widthForText:[self.dataSource pageTitleViewTitleForIndex:indexPath.row] font:self.config.titleNormalFont size:self.bounds.size];
    
    CGFloat selectedTitleWidth = [XLPageViewControllerUtil widthForText:[self.dataSource pageTitleViewTitleForIndex:indexPath.row] font:self.config.titleSelectedFont size:self.bounds.size];
    
    return selectedTitleWidth > normalTitleWidth ? selectedTitleWidth : normalTitleWidth;
}

#pragma mark -
#pragma mark 自定cell方法
- (void)registerClass:(Class)cellClass forTitleViewCellWithReuseIdentifier:(NSString *)identifier {
    if (!identifier.length) {
        [NSException raise:@"This identifier must not be nil and must not be an empty string." format:@""];
    }
    if ([identifier isEqualToString:NSStringFromClass(XLPageTitleCell.class)]) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    if (![cellClass isSubclassOfClass:[XLPageTitleCell class]]) {
        [NSException raise:@"The cell class must be a subclass of XLPageTitleCell." format:@""];
    }
    [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
}

- (__kindof XLPageTitleCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    if (!identifier.length) {
        [NSException raise:@"This identifier must not be nil and must not be an empty string." format:@""];
    }
    if ([identifier isEqualToString:NSStringFromClass(XLPageTitleCell.class)]) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (!indexPath) {
        [NSException raise:@"please change an identifier" format:@""];
    }
    XLPageTitleCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    return cell;
}

@end
