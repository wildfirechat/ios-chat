//
//  DNPhotoBrowserViewController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/28.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNPhotoBrowser.h"
#import "UIView+DNImagePicker.h"
#import "DNSendButton.h"
#import "DNFullImageButton.h"
#import "DNBrowserCell.h"
#import "DNAsset.h"
#import "DNImagePickerHelper.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


@interface DNPhotoBrowser () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
{
    BOOL _statusBarShouldBeHidden;
    BOOL _didSavePreviousStateOfNavBar;
    BOOL _viewIsActive;
    BOOL _viewHasAppearedInitially;
    // Appearance
    BOOL _previousNavBarHidden;
    BOOL _previousNavBarTranslucent;
    UIBarStyle _previousNavBarStyle;
    UIColor *_previousNavBarTintColor;
    UIColor *_previousNavBarBarTintColor;
    UIBarButtonItem *_previousViewControllerBackButton;
    UIImage *_previousNavigationBarBackgroundImageDefault;
    UIImage *_previousNavigationBarBackgroundImageLandscapePhone;
}

@property (nonatomic, strong) UICollectionView *browserCollectionView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIButton *checkButton;
@property (nonatomic, strong) DNSendButton *sendButton;
@property (nonatomic, strong) DNFullImageButton *fullImageButton;

@property (nonatomic, strong) NSMutableArray *photoDataSources;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, getter=isFullImage) BOOL fullImage;

@end

@implementation DNPhotoBrowser

- (instancetype)initWithPhotos:(NSArray *)photosArray
                  currentIndex:(NSInteger)index
                     fullImage:(BOOL)isFullImage {
    self = [super init];
    if (self) {
        _photoDataSources = [[NSMutableArray alloc] initWithArray:photosArray];
        _currentIndex = index;
        _fullImage = isFullImage;
    }
    return self;
} 

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self updateSelestedNumber];
    [self updateNavigationBarAndToolBar];
}
- (void)viewWillAppear:(BOOL)animated {
    
    // Super
    [super viewWillAppear:animated];
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
//    [self setNavBarAppearance:animated];
    
    // Initial appearance
    if (!_viewHasAppearedInitially) {
        _viewHasAppearedInitially = YES;
    }
    
    //scroll to the current offset
    [self.browserCollectionView setContentOffset:CGPointMake(self.browserCollectionView.frame.size.width * self.currentIndex,0)];
}

- (void)viewWillDisappear:(BOOL)animated {
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        _viewIsActive = NO;
        [self restorePreviousNavBarAppearance:animated];
    }

    [self.navigationController.navigationBar.layer removeAllAnimations];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self setControlsHidden:NO animated:NO];
    
    // Super
    [super viewWillDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    _viewIsActive = NO;
    [super viewDidDisappear:animated];
}

#pragma mark - priviate
- (void)setupView {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.clipsToBounds = YES;
    [self browserCollectionView];
    [self toolbar];
    [self setupBarButtonItems];

    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.checkButton];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

- (void)setupData
{
    self.photoDataSources = [NSMutableArray new];
}

- (void)setupBarButtonItems
{
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithCustomView:self.fullImageButton];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton];
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    [self.toolbar setItems:@[item1,item2,item3,item4]];
}

- (void)updateNavigationBarAndToolBar {
    NSUInteger totalNumber = self.photoDataSources.count;
    self.title = [NSString stringWithFormat:@"%@/%@",@(self.currentIndex+1),@(totalNumber)];
    BOOL isSeleted = NO;
    if ([self.delegate respondsToSelector:@selector(photoBrowser:currentPhotoAssetIsSeleted:)]) {
        isSeleted = [self.delegate photoBrowser:self currentPhotoAssetIsSeleted:[self.photoDataSources objectAtIndex:self.currentIndex]];
    }
    self.checkButton.selected = isSeleted;
    self.fullImageButton.selected = self.isFullImage;
    
    if (self.isFullImage) {
        __weak typeof(self) wSelf = self;
        [DNImagePickerHelper fetchImageSizeWithAsset:self.photoDataSources[self.currentIndex] imageSizeResultHandler:^(CGFloat imageSize, NSString *sizeString) {
            __strong typeof(wSelf) sSelf = wSelf;
            sSelf.fullImageButton.text = sizeString;
        }];
    }
}

- (void)updateSelestedNumber
{
    NSUInteger selectedNumber = 0;
    if ([self.delegate respondsToSelector:@selector(seletedPhotosNumberInPhotoBrowser:)]) {
        selectedNumber = [self.delegate seletedPhotosNumberInPhotoBrowser:self];
    }
    self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(selectedNumber)];
}

#pragma mark - Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    if ([navBar respondsToSelector:@selector(setBarTintColor:)]) {
        navBar.barTintColor = nil;
        navBar.shadowImage = nil;
    }
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsCompact];;
    }
}


- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
        _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    }
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsCompact];
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        if ([UINavigationBar instancesRespondToSelector:@selector(barTintColor)]) {
            navBar.barTintColor = _previousNavBarBarTintColor;
        }
        navBar.barStyle = _previousNavBarStyle;
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
            [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsCompact];
        }
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}

#pragma mark - ui actions
- (void)checkButtonAction {
    if (self.checkButton.selected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowser:deseletedAsset:)]) {
            [self.delegate photoBrowser:self deseletedAsset:self.photoDataSources[self.currentIndex]];
            self.checkButton.selected = NO;
        }
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoBrowser:seletedAsset:)]) {
            self.checkButton.selected = [self.delegate photoBrowser:self seletedAsset:self.photoDataSources[self.currentIndex]];
        }
    }
    
    [self updateSelestedNumber];
}

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendButtonAction {
    if ([self.delegate respondsToSelector:@selector(sendImagesFromPhotobrowser:currentAsset:)]) {
        [self.delegate sendImagesFromPhotobrowser:self currentAsset:self.photoDataSources[self.currentIndex]];
    }
}

- (void)fullImageButtonAction {
    self.fullImageButton.selected = !self.fullImageButton.selected;
    self.fullImage = self.fullImageButton.selected;
    if ([self.delegate respondsToSelector:@selector(photoBrowser:seleteFullImage:)]) {
        [self.delegate photoBrowser:self seleteFullImage:self.isFullImage];
    }
    if (self.fullImageButton.selected) {
        [self updateNavigationBarAndToolBar];
        BOOL success = [self.delegate photoBrowser:self seletedAsset:self.photoDataSources[self.currentIndex]];
        if (success) {
            [self updateSelestedNumber];
            [self updateNavigationBarAndToolBar];
        }
    }
}

#pragma mark - get/set
- (UIButton *)checkButton {
    if (!_checkButton) {
        _checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _checkButton.frame = CGRectMake(0, 0, 25, 25);
        [_checkButton setBackgroundImage:[UIImage imageNamed:@"multi_selected"] forState:UIControlStateSelected];
        [_checkButton setBackgroundImage:[UIImage imageNamed:@"multi_unselected"] forState:UIControlStateNormal];
        [_checkButton addTarget:self action:@selector(checkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _checkButton;
}

- (DNFullImageButton *)fullImageButton {
    if (!_fullImageButton) {
        _fullImageButton = [[DNFullImageButton alloc] initWithFrame:CGRectZero];
        [_fullImageButton addTarget:self action:@selector(fullImageButtonAction)];
        _fullImageButton.selected = self.isFullImage;
    }
    return _fullImageButton;
}

- (DNSendButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[DNSendButton alloc] initWithFrame:CGRectZero];
        [_sendButton addTaget:self action:@selector(sendButtonAction)];
    }
    return  _sendButton;
}

- (UIToolbar *)toolbar {
    if (!_toolbar) {
        CGFloat height = 44;
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height)];
        if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
            [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
            [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsCompact];
        }
        _toolbar.barStyle = UIBarStyleBlackTranslucent;
        _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_toolbar];
    }
    return _toolbar;
}

- (UICollectionView *)browserCollectionView {
    if (!_browserCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _browserCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, 0, self.view.bounds.size.width+20, self.view.bounds.size.height+1) collectionViewLayout:layout];
        _browserCollectionView.backgroundColor = [UIColor blackColor];
        [_browserCollectionView registerClass:[DNBrowserCell class] forCellWithReuseIdentifier:NSStringFromClass([DNBrowserCell class])];
        _browserCollectionView.delegate = self;
        _browserCollectionView.dataSource = self;
        _browserCollectionView.pagingEnabled = YES;
        _browserCollectionView.showsHorizontalScrollIndicator = NO;
        _browserCollectionView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:_browserCollectionView];
    }
    return _browserCollectionView;
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.photoDataSources count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DNBrowserCell *cell = (DNBrowserCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([DNBrowserCell class]) forIndexPath:indexPath];
    cell.asset = [self.photoDataSources objectAtIndex:indexPath.row];
    cell.photoBrowser = self;
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.view.bounds.size.width+20, self.view.bounds.size.height);
}

#pragma mark - scrollerViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat itemWidth = CGRectGetWidth(self.browserCollectionView.frame);
    CGFloat currentPageOffset = itemWidth * self.currentIndex;
    CGFloat deltaOffset = offsetX - currentPageOffset;
    if (fabs(deltaOffset) >= itemWidth/2 ) {
        [self.fullImageButton shouldAnimating:YES];
    } else {
        [self.fullImageButton shouldAnimating:NO];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat itemWidth = CGRectGetWidth(self.browserCollectionView.frame);
    if (offsetX >= 0){
        NSInteger page = offsetX / itemWidth;
        [self didScrollToPage:page];
    }

    [self.fullImageButton shouldAnimating:NO];
}

- (void)didScrollToPage:(NSInteger)page {
    self.currentIndex = page;
    [self updateNavigationBarAndToolBar];
}

#pragma mark - Control Hiding / Showing
// Fades all controls slide and fade
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated{
    // Force visible
    if (!self.photoDataSources || !self.photoDataSources.count)
        hidden = NO;
    // Animations & positions
    CGFloat animatonOffset = 20;
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        // Hide status bar
        _statusBarShouldBeHidden = hidden;
        [UIView animateWithDuration:animationDuration animations:^(void) {
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {}];
    }
    
    CGRect frame = CGRectIntegral(CGRectMake(0, self.view.bounds.size.height - 44, self.view.bounds.size.width, 44));
    
    // Pre-appear animation positions for iOS 7 sliding
    if ([self areControlsHidden] && !hidden && animated) {
        // Toolbar
        self.toolbar.frame = CGRectOffset(frame, 0, animatonOffset);
    }
    
    [UIView animateWithDuration:animationDuration animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        // Nav bar slides up on it's own on iOS 7
        [self.navigationController.navigationBar setAlpha:alpha];
        // Toolbar
        self.toolbar.frame = frame;
        if (hidden) self.toolbar.frame = CGRectOffset(self.toolbar.frame, 0, animatonOffset);
        self.toolbar.alpha = alpha;
        
    } completion:^(BOOL finished) {}];
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarShouldBeHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); }
- (void)hideControls { [self setControlsHidden:YES animated:YES]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES]; }
@end
#pragma clang diagnostic pop
