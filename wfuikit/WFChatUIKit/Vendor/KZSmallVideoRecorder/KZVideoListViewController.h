//
//  KZVideoListViewController.h
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/21.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZVideoConfig.h"
@class KZVideoModel;
/*!
 *  视频列表
 */
@interface KZVideoListViewController : NSObject

@property (nonatomic, strong, readonly) UIView *actionView;

@property (nonatomic, copy) void(^selectBlock)(KZVideoModel *);

@property (nonatomic, copy) void(^didCloseBlock)(void);

- (void)showAnimationWithType:(KZVideoViewShowType)showType;

@end
