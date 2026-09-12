//
//  WFCUVoiceInputView.h
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, WFCUVoiceInputZone) {
    // 松开发送语音
    WFCUVoiceInputZoneSend = 0,
    // 松手取消
    WFCUVoiceInputZoneCancel = 1,
    // 滑到这里转文字
    WFCUVoiceInputZoneText = 2
};

@class WFCUVoiceInputView;

@protocol WFCUVoiceInputViewDelegate <NSObject>

@optional
/**
 * 手指所在的区域发生变化
 */
- (void)voiceInputView:(WFCUVoiceInputView *)view didChangeZone:(WFCUVoiceInputZone)zone;

/**
 * 编辑文字时点击取消
 */
- (void)voiceInputViewDidCancel:(WFCUVoiceInputView *)view;

/**
 * 编辑文字时点击发送原语音
 */
- (void)voiceInputViewDidSendVoice:(WFCUVoiceInputView *)view;

/**
 * 编辑文字时点击发送文字
 */
- (void)voiceInputView:(WFCUVoiceInputView *)view didSendText:(NSString *)text;

@end

/**
 * 按住说话时的全屏浮层，交互参考微信：
 * 按住录音，滑到左上方"取消"后松手不发送，滑到右上方"转文字"边说边显示识别出的文字，
 * 松手后可以编辑文字再发送，也可以发送原语音。
 */
@interface WFCUVoiceInputView : UIView

@property (nonatomic, weak, nullable) id<WFCUVoiceInputViewDelegate> delegate;

/**
 * 当前手指所在的区域
 */
@property (nonatomic, assign, readonly) WFCUVoiceInputZone zone;

/**
 * 是否可以滑动到"转文字"
 */
@property (nonatomic, assign) BOOL speechToTextEnabled;

- (instancetype)initWithFrame:(CGRect)frame recordButtonFrame:(CGRect)recordButtonFrame;

/**
 * 显示浮层（淡入）
 */
- (void)show;

/**
 * 隐藏浮层并移除
 */
- (void)dismiss;

/**
 * 是否处于编辑文字状态
 */
@property (nonatomic, assign, readonly) BOOL editing;

/**
 * 根据手指位置更新区域，point 为本视图坐标
 */
- (void)updateZoneWithPoint:(CGPoint)point;

/**
 * 设置录音音量，0~1
 */
- (void)setVoiceLevel:(CGFloat)level;

/**
 * 设置正在识别的文字
 */
- (void)setRecognizedText:(NSString *)text;

/**
 * 提示说话时间太短
 */
- (void)showTooShortTip;

/**
 * 进入编辑文字状态
 */
- (void)enterEditing:(NSString *)text;

/**
 * 识别结束，更新编辑框里的文字（用户已经手动编辑过时不覆盖）
 * @param finished 识别是否已经结束，结束前显示"识别中"的声波
 */
- (void)updateEditingText:(NSString *)text finished:(BOOL)finished;

/**
 * 编辑框中的文字
 */
- (NSString *)editingText;

@end

NS_ASSUME_NONNULL_END
