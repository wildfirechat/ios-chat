//
//  DNAssetsViewCell.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/11.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DNAssetsViewCell;
@class DNAsset;

@protocol DNAssetsViewCellDelegate <NSObject>
@optional

- (void)didSelectItemAssetsViewCell:(nonnull DNAssetsViewCell *)assetsCell;
- (void)didDeselectItemAssetsViewCell:(nonnull DNAssetsViewCell *)assetsCell;
@end

@interface DNAssetsViewCell : UICollectionViewCell

@property (nonatomic, readonly, nonnull) UIImageView *imageView;
@property (nonatomic, strong, nonnull) DNAsset *asset;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, weak, nullable) id<DNAssetsViewCellDelegate> delegate;

- (void)fillWithAsset:(nonnull DNAsset *)asset isSelected:(BOOL)seleted;

@end
