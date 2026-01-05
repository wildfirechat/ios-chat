//
//  WFCURecentImagesFloatView.h
//  WFChat UIKit
//
//  Created by WildFire Chat on 2025/01/05.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WFCURecentImagesFloatView;

@protocol WFCURecentImagesFloatViewDelegate <NSObject>
- (void)recentImagesFloatView:(WFCURecentImagesFloatView *)floatView didSelectImage:(UIImage *)image;
- (void)recentImagesFloatViewDidDismiss:(WFCURecentImagesFloatView *)floatView;
@end

@interface WFCURecentImagesFloatView : UIView

@property (nonatomic, weak) id<WFCURecentImagesFloatViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)showInView:(UIView *)parentView;
- (void)dismiss;
- (void)loadAndShowRecentImageWithCompletion:(void (^)(BOOL hasImage))completion;
- (void)markAssetAsShown:(NSString *)assetId;

@end
