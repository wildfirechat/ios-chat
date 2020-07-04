//
//  DNBrowserCell.h
//  ImagePicker
//
//  Created by DingXiao on 15/2/28.
//  Copyright (c) 2015年 Dennis. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DNAsset;
@class DNPhotoBrowser;

@interface DNBrowserCell : UICollectionViewCell

@property (nonatomic, weak, nullable) DNPhotoBrowser *photoBrowser;

@property (nonatomic, strong, nullable) DNAsset *asset;

@end
