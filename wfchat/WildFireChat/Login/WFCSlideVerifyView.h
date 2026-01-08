//
//  WFCSlideVerifyView.h
//  WildFireChat
//
//  Created by Claude on 2026-01-07.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WFCSlideVerifyViewDelegate <NSObject>

@optional
- (void)slideVerifyViewDidVerifySuccess:(NSString *)token;
- (void)slideVerifyViewDidVerifyFailed; // 验证失败（滑动位置不对），不关闭窗口
- (void)slideVerifyViewDidLoadFailed; // 加载验证码失败，需要关闭窗口

@end

@interface WFCSlideVerifyView : UIView

@property (nonatomic, weak) id<WFCSlideVerifyViewDelegate> delegate;

// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame;

// 刷新验证码
- (void)refreshVerify;

// 重置验证状态
- (void)reset;

@end

NS_ASSUME_NONNULL_END
