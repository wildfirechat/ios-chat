//
//  WFCURecentImagesFloatView.m
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/05.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "WFCURecentImagesFloatView.h"
#import "WFCUUtilities.h"
#import <Photos/Photos.h>

#define IMAGE_SIZE 100
#define PADDING 12
#define CLOSE_BUTTON_SIZE 26
#define SHOWN_ASSETS_KEY @"WFCUShownRecentImageAssets"

@interface WFCURecentImagesFloatView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) PHImageRequestOptions *imageRequestOptions;
@property (nonatomic, strong) NSString *currentAssetId; // 当前显示的图片 asset ID
@property (nonatomic, strong) UIView *parentView; // 保存父视图引用

@end

@implementation WFCURecentImagesFloatView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
    self.layer.cornerRadius = 16;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, -2);
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowRadius = 10;

    // 主图片
    self.imageView = [[UIImageView alloc] init];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = 12;
    self.imageView.layer.borderWidth = 2;
    self.imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.imageView.userInteractionEnabled = YES;
    [self addSubview:self.imageView];

    // 点击图片发送手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.imageView addGestureRecognizer:tap];

    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.closeButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.closeButton.titleLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.closeButton.contentEdgeInsets = UIEdgeInsetsMake(-4, 0, 0, 0);
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.closeButton.layer.cornerRadius = CLOSE_BUTTON_SIZE/2;
    self.closeButton.clipsToBounds = YES;
    [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];

    // 初始化图片请求选项
    self.imageRequestOptions = [[PHImageRequestOptions alloc] init];
    self.imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    self.imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    self.imageRequestOptions.synchronous = NO;
}

- (void)showInView:(UIView *)parentView {
    self.parentView = parentView;

    // 计算大小：减少空白
    CGFloat viewSize = IMAGE_SIZE + PADDING * 2;
    CGFloat margin = 12;

    CGFloat x = parentView.bounds.size.width - viewSize - margin;
    CGFloat y = (parentView.bounds.size.height - viewSize) / 2 + viewSize / 4;

    self.frame = CGRectMake(x, y, viewSize, viewSize);
    self.alpha = 0;
    self.transform = CGAffineTransformMakeScale(0.5, 0.5);

    [parentView addSubview:self];

    // 布局子视图 - 减少边距
    self.imageView.frame = CGRectMake(PADDING, PADDING, IMAGE_SIZE, IMAGE_SIZE);
    self.closeButton.frame = CGRectMake(viewSize - CLOSE_BUTTON_SIZE - 6, 6, CLOSE_BUTTON_SIZE, CLOSE_BUTTON_SIZE);

    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        // 通知 delegate 已关闭
        if ([self.delegate respondsToSelector:@selector(recentImagesFloatViewDidDismiss:)]) {
            [self.delegate recentImagesFloatViewDidDismiss:self];
        }
    }];
}

- (void)closeButtonTapped:(UIButton *)sender {
    // 记录已显示的图片
    if (self.currentAssetId) {
        [self markAssetAsShown:self.currentAssetId];
    }
    [self dismiss];
}

- (void)imageTapped:(UITapGestureRecognizer *)gesture {
    // 点击图片直接发送
    if (self.currentImage && [self.delegate respondsToSelector:@selector(recentImagesFloatView:didSelectImage:)]) {
        [self.delegate recentImagesFloatView:self didSelectImage:self.currentImage];
        // 记录已显示的图片
        if (self.currentAssetId) {
            [self markAssetAsShown:self.currentAssetId];
        }
    }
    [self dismiss];
}

#pragma mark - Asset ID 管理

// 标记图片为已显示
- (void)markAssetAsShown:(NSString *)assetId {
    if (!assetId) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *shownAssets = [NSMutableArray arrayWithArray:[defaults arrayForKey:SHOWN_ASSETS_KEY]];

    if (![shownAssets containsObject:assetId]) {
        [shownAssets addObject:assetId];
        // 只保留最近50个记录
        if (shownAssets.count > 50) {
            [shownAssets removeObjectsInRange:NSMakeRange(0, shownAssets.count - 50)];
        }
        [defaults setObject:shownAssets forKey:SHOWN_ASSETS_KEY];
        [defaults synchronize];
    }
}

#pragma mark - Load and Show

- (void)loadAndShowRecentImageWithCompletion:(void (^)(BOOL hasImage))completion {
    // 先获取 window
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        if (completion) {
            completion(NO);
        }
        return;
    }

    // 保存 parentView 引用
    self.parentView = window;

    // 获取相册权限并检查最近图片
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO);
                }
            });
            return;
        }

        // 获取最近1分钟的图片
        NSDate *now = [NSDate date];
        NSDate *oneMinuteAgo = [now dateByAddingTimeInterval:-60];

        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        options.predicate = [NSPredicate predicateWithFormat:@"creationDate >= %@", oneMinuteAgo];
        options.fetchLimit = 1; // 只获取最新的1张

        PHFetchResult *assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (assets.count == 0) {
                // 没有最近图片
                if (completion) {
                    completion(NO);
                }
                return;
            }

            PHAsset *asset = assets.firstObject;
            NSString *assetId = asset.localIdentifier;

            // 检查是否应该显示
            if ([self hasShownAsset:assetId]) {
                // 已经显示过，不再显示
                if (completion) {
                    completion(NO);
                }
                return;
            }

            // 有新图片，加载并显示
            self.currentAssetId = assetId;

            // 请求图片 - 提高图片质量
            CGFloat scale = [UIScreen mainScreen].scale * 3;
            CGSize targetSize = CGSizeMake(IMAGE_SIZE * scale, IMAGE_SIZE * scale);

            __weak typeof(self)ws = self;
            [[PHImageManager defaultManager] requestImageForAsset:asset
                                                           targetSize:targetSize
                                                          contentMode:PHImageContentModeAspectFill
                                                              options:self.imageRequestOptions
                                                    resultHandler:^(UIImage *result, NSDictionary *info) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (result) {
                                                                ws.currentImage = result;
                                                                ws.imageView.image = result;
                                                                // 显示视图
                                                                [ws showInView:ws.parentView];
                                                                if (completion) {
                                                                    completion(YES);
                                                                }
                                                            } else {
                                                                if (completion) {
                                                                    completion(NO);
                                                                }
                                                            }
                                                        });
                                                    }];
        });
    }];
}

// 检查图片是否已显示过
- (BOOL)hasShownAsset:(NSString *)assetId {
    if (!assetId) {
        return NO;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *shownAssets = [defaults mutableArrayValueForKey:SHOWN_ASSETS_KEY];

    return [shownAssets containsObject:assetId];
}

@end
