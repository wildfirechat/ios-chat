//
//  DNImageFlowViewController.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import "DNImageFlowViewController.h"
#import "DNImagePickerController.h"
#import "DNPhotoBrowser.h"
#import "UIView+DNImagePicker.h"
#import "UIColor+Hex.h"
#import "DNAssetsViewCell.h"
#import "DNSendButton.h"
#import "DNImagePickerHelper.h"
#import "DNAlbum.h"
#import "DNAsset.h"
#import "MBProgressHUD.h"
#import <Photos/Photos.h>
#import "UIView+Toast.h"

static NSUInteger const kDNImageFlowMaxSeletedNumber = 9;

@interface DNImageFlowViewController () <UICollectionViewDataSource, UICollectionViewDelegate, DNAssetsViewCellDelegate, DNPhotoBrowserDelegate>

@property (nonatomic, strong) DNAlbum *album;
@property (nonatomic, copy) NSString *albumIdentifier;

@property (nonatomic, strong) UICollectionView *imageFlowCollectionView;
@property (nonatomic, strong) DNSendButton *sendButton;

@property (nonatomic, strong) NSMutableArray *assetsArray;
@property (nonatomic, strong) NSMutableArray *selectedAssetsArray;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, assign) BOOL isFullImage;
@end

static NSString* const dnAssetsViewCellReuseIdentifier = @"DNAssetsViewCell";

@implementation DNImageFlowViewController

- (instancetype)initWithAlbumIdentifier:(NSString *)albumIdentifier {
    self = [super init];
    if (self) {
        _assetsArray = [NSMutableArray array];
        _selectedAssetsArray = [NSMutableArray array];
        _albumIdentifier = albumIdentifier;
    }
    return self;
}

- (instancetype)initWithAblum:(DNAlbum *)album {
    self = [super init];
    if (self) {
        _assetsArray = [NSMutableArray array];
        _selectedAssetsArray = [NSMutableArray array];
        _album = album;

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self setupData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:DNImagePickerPhotoLibraryChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupData {
    
    if (!self.album && self.albumIdentifier.length > 0) {
        __weak typeof(self) wSelf = self;
        [DNImagePickerHelper requestCurrentAblumWithCompleteHandler:^(DNAlbum *album) {
            __strong typeof(wSelf) sSelf = wSelf;
            sSelf.album = album;
            sSelf.title = sSelf.album.albumTitle;
            [sSelf loadData];
        }];
    } else {
        self.title = self.album.albumTitle;
        [self loadData];
    }
}

- (void)setupView {
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"cancel") style:UIBarButtonItemStyleDone target:self action:@selector(cancelAction)];
    
    [self imageFlowCollectionView];
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:WFCString(@"preview")
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(previewAction)];
    [item1 setTintColor:[UIColor blackColor]];
    item1.enabled = NO;
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc] initWithCustomView:self.sendButton];
    
    
    UIBarButtonItem *item4 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//    item4.width = -10;
    
    [self setToolbarItems:@[item1,item2,item3,item4] animated:NO];
}

- (void)loadData {
    if (!self.assetsArray.count) {
        [self.indicatorView startAnimating];
    }
    __weak typeof(self) wSelf = self;
    [DNImagePickerHelper fetchImageAssetsInAlbum:self.album completeHandler:^(NSArray<DNAsset *> * imageArray) {
        __strong typeof(wSelf) sSelf = wSelf;
        [sSelf.indicatorView stopAnimating];
        [sSelf.assetsArray removeAllObjects];
        [sSelf.assetsArray addObjectsFromArray:imageArray];
        [self.imageFlowCollectionView reloadData];
        [self scrollerToBottom:NO];
    }];
}

#pragma mark - helpmethods
- (void)scrollerToBottom:(BOOL)animated {
    NSInteger rows = [self.imageFlowCollectionView numberOfItemsInSection:0] - 1;
    [self.imageFlowCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:rows inSection:0]
                                         atScrollPosition:UICollectionViewScrollPositionBottom
                                                 animated:animated];
}

- (DNImagePickerController *)dnImagePickerController {
    if (!self.navigationController
        ||
        ![self.navigationController isKindOfClass:[DNImagePickerController class]])
    {
        NSAssert(false, @"check the navigation controller");
    }
    return (DNImagePickerController *)self.navigationController;
}

- (void)removeAssetsObject:(DNAsset *)asset {
    if ([self.selectedAssetsArray containsObject:asset]) {
        [self.selectedAssetsArray removeObject:asset];
    }
}

- (void)addAssetsObject:(DNAsset *)asset {
    [self.selectedAssetsArray addObject:asset];
}

#pragma mark - priviate methods
- (void)sendImages {
    [DNImagePickerHelper saveAblumIdentifier:self.album.identifier];
    
    DNImagePickerController *imagePicker = [self dnImagePickerController];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    if ([imagePicker.imagePickerDelegate respondsToSelector:@selector(dnImagePickerController:sendImages:isFullImage:)]) {
        [imagePicker.imagePickerDelegate dnImagePickerController:imagePicker sendImages:self.selectedAssetsArray isFullImage:self.isFullImage];
    }
}

- (void)browserPhotoAsstes:(NSArray *)assets pageIndex:(NSInteger)page {
    DNPhotoBrowser *browser = [[DNPhotoBrowser alloc] initWithPhotos:assets
                                                        currentIndex:page
                                                           fullImage:self.isFullImage];
    browser.delegate = self;
    browser.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:browser animated:YES];
}

- (BOOL)seletedAssets:(DNAsset *)asset {
    if ([self.selectedAssetsArray containsObject:asset]) {
        return NO;
    }
    UIBarButtonItem *firstItem = self.toolbarItems.firstObject;
    firstItem.enabled = YES;
    if (self.selectedAssetsArray.count >= kDNImageFlowMaxSeletedNumber) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:WFCString(@"alertTitle")
                                                        message:WFCString(@"alertContent")
                                                       delegate:self
                                              cancelButtonTitle:WFCString(@"alertButton")
                                              otherButtonTitles:nil, nil];
        [alert show];
        return NO;
    } else {
        [self addAssetsObject:asset];
        self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(self.selectedAssetsArray.count)];
        return YES;
    }
}

- (void)deseletedAssets:(DNAsset *)asset {
    [self removeAssetsObject:asset];
    self.sendButton.badgeValue = [NSString stringWithFormat:@"%@",@(self.selectedAssetsArray.count)];
    if (self.selectedAssetsArray.count < 1) {
        UIBarButtonItem *firstItem = self.toolbarItems.firstObject;
        firstItem.enabled = NO;
    }
}

#pragma mark - getter/setter

- (UICollectionView *)imageFlowCollectionView {
    if (!_imageFlowCollectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 2.0;
        layout.minimumInteritemSpacing = 2.0;
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        _imageFlowCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:layout];
        _imageFlowCollectionView.backgroundColor = [UIColor clearColor];
        [_imageFlowCollectionView registerClass:[DNAssetsViewCell class] forCellWithReuseIdentifier:dnAssetsViewCellReuseIdentifier];
        _imageFlowCollectionView.alwaysBounceVertical = YES;
        _imageFlowCollectionView.delegate = self;
        _imageFlowCollectionView.dataSource = self;
        _imageFlowCollectionView.showsHorizontalScrollIndicator = YES;
        [self.view addSubview:_imageFlowCollectionView];
    }
    
    return _imageFlowCollectionView;
}

- (DNSendButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[DNSendButton alloc] initWithFrame:CGRectZero];
        [_sendButton addTaget:self action:@selector(sendButtonAction:)];
    }
    return  _sendButton;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
        _indicatorView.centerX = CGRectGetWidth(self.view.bounds)/2;
        _indicatorView.centerY = CGRectGetHeight(self.view.bounds)/2;
        [self.view addSubview:_indicatorView];
    }
    return _indicatorView;
}

#pragma mark - ui action
- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)sendButtonAction:(id)sender {
    if (self.selectedAssetsArray.count > 0) {
        [self sendImages];
    }
}

- (void)previewAction {
    [self browserPhotoAsstes:self.selectedAssetsArray pageIndex:0];
}

- (void)cancelAction {
    DNImagePickerController *navController = [self dnImagePickerController];
    if (navController && [navController.imagePickerDelegate respondsToSelector:@selector(dnImagePickerControllerDidCancel:)]) {
        [navController.imagePickerDelegate dnImagePickerControllerDidCancel:navController];
    }
}

#pragma mark - DNAssetsViewCellDelegate
- (void)didSelectItemAssetsViewCell:(DNAssetsViewCell *)assetsCell {
    assetsCell.isSelected = [self seletedAssets:assetsCell.asset];
}

- (void)didDeselectItemAssetsViewCell:(DNAssetsViewCell *)assetsCell {
    assetsCell.isSelected = NO;
    [self deseletedAssets:assetsCell.asset];
}

#pragma mark - UICollectionView delegate and Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.assetsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DNAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:dnAssetsViewCellReuseIdentifier forIndexPath:indexPath];
    DNAsset *asset = self.assetsArray[indexPath.row];
    cell.delegate = self;
    [cell fillWithAsset:asset isSelected:[self.selectedAssetsArray containsObject:asset]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self browserPhotoAsstes:self.assetsArray pageIndex:indexPath.row];
}

#define kSizeThumbnailCollectionView  ([UIScreen mainScreen].bounds.size.width-10)/4
#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(kSizeThumbnailCollectionView, kSizeThumbnailCollectionView);
    return size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(2, 2, 2, 2);
}

#pragma mark - DNPhotoBrowserDelegate
- (void)sendImagesFromPhotobrowser:(DNPhotoBrowser *)photoBrowser currentAsset:(DNAsset *)asset {
    if (self.selectedAssetsArray.count <= 0) {
        [self seletedAssets:asset];
        [self.imageFlowCollectionView reloadData];
    }
    [self sendImages];
}

- (NSUInteger)seletedPhotosNumberInPhotoBrowser:(DNPhotoBrowser *)photoBrowser {
    return self.selectedAssetsArray.count;
}

- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser currentPhotoAssetIsSeleted:(DNAsset *)asset{
    return [self.selectedAssetsArray containsObject:asset];
}

- (BOOL)photoBrowser:(DNPhotoBrowser *)photoBrowser seletedAsset:(DNAsset *)asset {
    BOOL seleted = [self seletedAssets:asset];
    [self.imageFlowCollectionView reloadData];
    return seleted;
}

- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser deseletedAsset:(DNAsset *)asset {
    [self deseletedAssets:asset];
    [self.imageFlowCollectionView reloadData];
}

- (void)photoBrowser:(DNPhotoBrowser *)photoBrowser seleteFullImage:(BOOL)fullImage {
    self.isFullImage = fullImage;
}

@end
