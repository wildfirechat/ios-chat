//
//  WatermarkViewController.h
//  WFChatUIKit
//
//  Created by Rain on 16/11/2024.
//  Copyright © 2024 Tom Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WatermarkViewController : UIViewController
// 覆盖视图，用于显示水印
@property (nonatomic, strong) UIView *watermarkView;
@end

NS_ASSUME_NONNULL_END
