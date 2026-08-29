//
//  FaceBoard.h
//
//  Created by blue on 12-9-26.
//  Copyright (c) 2012年 blue. All rights reserved.
//  Email - 360511404@qq.com
//  http://github.com/bluemood


#import <UIKit/UIKit.h>


#define FACE_NAME_HEAD  @"/s"

// 表情转义字符的长度（ /s占2个长度，xxx占3个长度，共5个长度 ）
#define FACE_NAME_LEN   5


@protocol WFCUFaceBoardDelegate <NSObject>

@optional
- (void)didTouchEmoj:(NSString *)emojString;
- (void)didTouchBackEmoj;
- (void)didTouchSendEmoj;

- (void)didSelectedSticker:(NSString *)stickerPath;
- (void)didEmojSettingBtn;
@end


@interface WFCUFaceBoard : UIView<UIScrollViewDelegate>
+ (NSString *)getStickerCachePath;
+ (NSString *)getStickerBundleName;

@property (nonatomic, weak) id<WFCUFaceBoardDelegate> delegate;

@property (nonatomic, assign) BOOL disableSticker;

/// 面板高度（不含底部安全区）。
+ (CGFloat)boardHeight;

/// YES 表示面板不是当作键盘（inputView）弹出，而是内联在会话页里 —— iPad 双栏下走这条路。
/// 内联时页面本身已经避开了底部安全区，面板不再自己留那一档。
@property (nonatomic, assign) BOOL inlineHosted;
@end
