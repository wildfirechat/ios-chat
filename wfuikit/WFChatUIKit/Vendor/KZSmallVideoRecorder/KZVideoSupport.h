//
//  KZVideoSupport.h
//  KZWeChatSmallVideo_OC
//
//  Created by HouKangzhu on 16/7/19.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KZVideoConfig.h"
@class KZVideoModel;

//************* 录视频 顶部 状态 条 ****************
@interface KZStatusBar : UIView

- (instancetype)initWithFrame:(CGRect)frame style:(KZVideoViewShowType)style;

- (void)addCancelTarget:(id)target selector:(SEL)selector;

@property (nonatomic, assign) BOOL isRecoding;

@end


//************* 关闭的下箭头按钮 ****************
@interface KZCloseBtn : UIButton

@property (nonatomic,strong) NSArray *gradientColors; //CGColorRef


@end

//************* 点击录制的按钮 ****************
@interface KZRecordBtn : UIView

- (instancetype)initWithFrame:(CGRect)frame style:(KZVideoViewShowType)style;

@end


//************* 聚焦的方框 ****************
@interface KZFocusView : UIView

- (void)focusing;

@end

//************* 眼睛 ****************
@interface KZEyeView : UIView

@end

//************* 录视频下部的控制条 ****************
typedef NS_ENUM(NSUInteger, KZRecordCancelReason) {
    KZRecordCancelReasonDefault,
    KZRecordCancelReasonTimeShort,
    KZRecordCancelReasonUnknown,
};

@class KZControllerBar;
@protocol KZControllerBarDelegate <NSObject>

@optional
- (void)ctrollImageDidCapture:(KZControllerBar *)controllerBar;

- (void)ctrollVideoDidStart:(KZControllerBar *)controllerBar;

- (void)ctrollVideoDidEnd:(KZControllerBar *)controllerBar;

- (void)ctrollVideoDidCancel:(KZControllerBar *)controllerBar reason:(KZRecordCancelReason)reason;

- (void)ctrollVideoWillCancel:(KZControllerBar *)controllerBar;

- (void)ctrollVideoDidRecordSEC:(KZControllerBar *)controllerBar;

- (void)ctrollVideoDidClose:(KZControllerBar *)controllerBar;

- (void)ctrollVideoOpenVideoList:(KZControllerBar *)controllerBar;

@end
//************* 录视频下部的控制条 ****************
@interface KZControllerBar : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id<KZControllerBarDelegate> delegate;

- (void)setupSubViewsWithStyle:(KZVideoViewShowType)style;

@end

//************************* Video List 控件 **************************

//************* 删除视频的圆形叉叉 ****************
@interface KZCircleCloseBtn : UIButton

@end

//************* 视频列表 ****************
@interface KZVideoListCell:UICollectionViewCell

@property (nonatomic, strong) KZVideoModel *videoModel;

@property (nonatomic, strong) void(^deleteVideoBlock)(KZVideoModel *);

- (void)setEdit:(BOOL)canEdit;

@end

//************* 视频列表的添加 ****************
@interface KZAddNewVideoCell : UICollectionViewCell

@end
