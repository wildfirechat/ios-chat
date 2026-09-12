//
//  WFCUVoiceInputView.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUVoiceInputView.h"
#import "WFCUImage.h"
#import "UIColor+YH.h"

#define WFCU_VOICE_HIGHLIGHT_COLOR [UIColor colorWithHexString:@"0x3B62E0"]
#define WFCU_VOICE_DIM_COLOR [UIColor colorWithWhite:0.07 alpha:0.82]
#define WFCU_VOICE_PANEL_COLOR [UIColor colorWithWhite:0.27 alpha:1]
#define WFCU_VOICE_PILL_COLOR [UIColor colorWithWhite:0.34 alpha:1]
#define WFCU_VOICE_PILL_SELECTED_COLOR [UIColor colorWithWhite:0.60 alpha:1]
#define WFCU_VOICE_LABEL_COLOR [UIColor colorWithWhite:0.87 alpha:1]
#define WFCU_VOICE_RED_COLOR [UIColor colorWithRed:0xFA/255.f green:0x51/255.f blue:0x51/255.f alpha:1]

#pragma mark - 声波

@interface WFCUVoiceWaveView : UIView
@property (nonatomic, strong) UIColor *barColor;
- (void)setLevel:(CGFloat)level;
- (void)startAnimating;
- (void)stopAnimating;
@end

@interface WFCUVoiceWaveView ()
@property (nonatomic, strong) NSArray<UIView *> *bars;
@property (nonatomic, assign) CGFloat level;
@end

@implementation WFCUVoiceWaveView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _barColor = [UIColor whiteColor];
        NSMutableArray *bars = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) {
            UIView *bar = [[UIView alloc] init];
            bar.backgroundColor = _barColor;
            bar.layer.cornerRadius = 1.5;
            bar.layer.masksToBounds = YES;
            [bars addObject:bar];
            [self addSubview:bar];
        }
        _bars = bars;
    }
    return self;
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor;
    for (UIView *bar in self.bars) {
        bar.backgroundColor = barColor;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat barWidth = 3;
    CGFloat gap = 3;
    CGFloat totalWidth = self.bars.count * barWidth + (self.bars.count - 1) * gap;
    CGFloat x = (self.bounds.size.width - totalWidth) / 2;
    CGFloat height = MAX(4, self.bounds.size.height * (0.35 + 0.65 * self.level));
    for (UIView *bar in self.bars) {
        bar.frame = CGRectMake(x, (self.bounds.size.height - height) / 2, barWidth, height);
        x += barWidth + gap;
    }
}

- (void)setLevel:(CGFloat)level {
    _level = MAX(0, MIN(1, level));
    [self setNeedsLayout];
}

- (void)startAnimating {
    for (NSInteger i = 0; i < self.bars.count; i++) {
        UIView *bar = self.bars[i];
        bar.transform = CGAffineTransformMakeScale(1, 0.4);
        [UIView animateWithDuration:0.42
                              delay:i * 0.07
                            options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            bar.transform = CGAffineTransformMakeScale(1, 1.0);
        } completion:nil];
    }
}

- (void)stopAnimating {
    for (UIView *bar in self.bars) {
        [bar.layer removeAllAnimations];
        bar.transform = CGAffineTransformIdentity;
    }
}

@end

#pragma mark - 语音输入浮层

@interface WFCUVoiceInputView () <UITextViewDelegate>
@property (nonatomic, assign) CGRect recordButtonFrame;

@property (nonatomic, strong) UIView *recordingContainer;
@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) CAGradientLayer *panelGradient;
@property (nonatomic, strong) UIView *hintPill;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) WFCUVoiceWaveView *waveView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *bubbleLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UILabel *cancelLabel;
@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) UIView *editingContainer;
@property (nonatomic, strong) UIView *editBubbleView;
@property (nonatomic, strong) UITextView *editTextView;
@property (nonatomic, strong) UIButton *editCancelButton;
@property (nonatomic, strong) UIButton *editSendVoiceButton;
@property (nonatomic, strong) UIButton *editSendTextButton;

@property (nonatomic, assign) WFCUVoiceInputZone zone;
@property (nonatomic, assign, readwrite) BOOL editing;
@property (nonatomic, assign) CGFloat keyboardOffset;
@property (nonatomic, assign) BOOL userEdited;
@property (nonatomic, assign) BOOL editingFinished;
@end

@implementation WFCUVoiceInputView

- (instancetype)initWithFrame:(CGRect)frame recordButtonFrame:(CGRect)recordButtonFrame {
    self = [super initWithFrame:frame];
    if (self) {
        _recordButtonFrame = recordButtonFrame;
        _zone = WFCUVoiceInputZoneSend;
        self.backgroundColor = WFCU_VOICE_DIM_COLOR;
        [self setupSubviews];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupSubviews {
    self.recordingContainer = [[UIView alloc] initWithFrame:self.bounds];
    self.recordingContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.recordingContainer];

    self.panelView = [[UIView alloc] initWithFrame:CGRectZero];
    self.panelView.backgroundColor = [UIColor clearColor];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[(__bridge id)[WFCU_VOICE_PANEL_COLOR colorWithAlphaComponent:0].CGColor,
                        (__bridge id)WFCU_VOICE_PANEL_COLOR.CGColor];
    gradient.locations = @[@0.0, @0.25];
    self.panelGradient = gradient;
    [self.panelView.layer addSublayer:gradient];
    // 深灰背景在录音和编辑文字时都在，放在最底层
    [self insertSubview:self.panelView atIndex:0];

    self.bubbleView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bubbleView.backgroundColor = WFCU_VOICE_HIGHLIGHT_COLOR;
    self.bubbleView.layer.cornerRadius = 8;
    self.bubbleView.layer.masksToBounds = YES;
    self.bubbleView.alpha = 0;
    [self.recordingContainer addSubview:self.bubbleView];

    self.bubbleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bubbleLabel.textColor = [UIColor whiteColor];
    self.bubbleLabel.font = [UIFont systemFontOfSize:20];
    self.bubbleLabel.numberOfLines = 6;
    [self.bubbleView addSubview:self.bubbleLabel];

    self.waveView = [[WFCUVoiceWaveView alloc] initWithFrame:CGRectZero];
    self.waveView.barColor = [UIColor whiteColor];
    [self.recordingContainer addSubview:self.waveView];

    self.hintPill = [[UIView alloc] initWithFrame:CGRectZero];
    self.hintPill.backgroundColor = WFCU_VOICE_PILL_COLOR;
    self.hintPill.layer.cornerRadius = 18;
    self.hintPill.layer.masksToBounds = YES;
    [self.recordingContainer addSubview:self.hintPill];

    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.textColor = [UIColor whiteColor];
    self.hintLabel.font = [UIFont systemFontOfSize:16];
    self.hintLabel.text = WFCString(@"VoiceInputReleaseToSend");
    [self.hintPill addSubview:self.hintLabel];

    self.cancelButton = [self roundButtonWithImage:[WFCUImage imageNamed:@"close"]];
    [self.cancelButton addTarget:self action:@selector(onEditCancelClick) forControlEvents:UIControlEventTouchUpInside];
    [self.recordingContainer addSubview:self.cancelButton];

    self.textButton = [self roundButtonWithImage:nil];
    [self.textButton setTitle:WFCString(@"VoiceInputVoice") forState:UIControlStateNormal];
    [self.textButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [self.textButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.textButton addTarget:self action:@selector(onEditSendTextClick) forControlEvents:UIControlEventTouchUpInside];
    [self.recordingContainer addSubview:self.textButton];

    self.cancelLabel = [self roundButtonLabel];
    self.cancelLabel.text = WFCString(@"Cancel");
    [self.recordingContainer addSubview:self.cancelLabel];

    self.textLabel = [self roundButtonLabel];
    self.textLabel.text = WFCString(@"VoiceInputSlideToText");
    [self.recordingContainer addSubview:self.textLabel];

    // 编辑文字界面
    self.editingContainer = [[UIView alloc] initWithFrame:self.bounds];
    self.editingContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.editingContainer.hidden = YES;
    [self addSubview:self.editingContainer];

    self.editBubbleView = [[UIView alloc] initWithFrame:CGRectZero];
    self.editBubbleView.backgroundColor = WFCU_VOICE_HIGHLIGHT_COLOR;
    self.editBubbleView.layer.cornerRadius = 8;
    self.editBubbleView.layer.masksToBounds = YES;
    [self.editingContainer addSubview:self.editBubbleView];

    self.editTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.editTextView.backgroundColor = [UIColor clearColor];
    self.editTextView.textColor = [UIColor whiteColor];
    self.editTextView.font = [UIFont systemFontOfSize:20];
    self.editTextView.delegate = self;
    self.editTextView.scrollEnabled = YES;
    [self.editBubbleView addSubview:self.editTextView];

    self.editCancelButton = [self roundButtonWithImage:[WFCUImage imageNamed:@"close"]];
    [self.editCancelButton addTarget:self action:@selector(onEditCancelClick) forControlEvents:UIControlEventTouchUpInside];
    [self.editingContainer addSubview:self.editCancelButton];

    self.editSendVoiceButton = [self roundButtonWithImage:[WFCUImage imageNamed:@"sound_icon"]];
    [self.editSendVoiceButton addTarget:self action:@selector(onEditSendVoiceClick) forControlEvents:UIControlEventTouchUpInside];
    [self.editingContainer addSubview:self.editSendVoiceButton];

    self.editSendTextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    self.editSendTextButton.backgroundColor = WFCU_VOICE_HIGHLIGHT_COLOR;
    [self.editSendTextButton setTitle:WFCString(@"Send") forState:UIControlStateNormal];
    [self.editSendTextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.editSendTextButton.titleLabel.font = [UIFont systemFontOfSize:18];
    self.editSendTextButton.layer.cornerRadius = 22;
    self.editSendTextButton.layer.masksToBounds = YES;
    [self.editSendTextButton addTarget:self action:@selector(onEditSendTextClick) forControlEvents:UIControlEventTouchUpInside];
    [self.editingContainer addSubview:self.editSendTextButton];
}

- (UIButton *)roundButtonWithImage:(UIImage *)image {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
    button.backgroundColor = WFCU_VOICE_PILL_COLOR;
    button.layer.cornerRadius = 28;
    button.layer.masksToBounds = YES;
    button.tintColor = [UIColor whiteColor];
    if (image) {
        [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    return button;
}

- (UILabel *)roundButtonLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = WFCU_VOICE_LABEL_COLOR;
    label.font = [UIFont systemFontOfSize:13];
    return label;
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    self.recordingContainer.frame = self.bounds;
    self.editingContainer.frame = self.bounds;

    CGRect bounds = self.bounds;
    CGFloat buttonTop = self.recordButtonFrame.origin.y;
    CGFloat buttonMidY = CGRectGetMidY(self.recordButtonFrame);

    CGFloat panelTop = MAX(0, buttonTop - 60);
    self.panelView.frame = CGRectMake(0, panelTop, bounds.size.width, bounds.size.height - panelTop);
    self.panelGradient.frame = self.panelView.bounds;

    // 提示条和声波紧贴在按钮上方
    CGFloat hintWidth = MIN(260, bounds.size.width - 48);
    CGFloat hintHeight = 36;
    self.hintPill.frame = CGRectMake((bounds.size.width - hintWidth) / 2, buttonTop - 12 - hintHeight, hintWidth, hintHeight);
    self.hintLabel.frame = self.hintPill.bounds;

    self.waveView.frame = CGRectMake((bounds.size.width - 60) / 2, CGRectGetMinY(self.hintPill.frame) - 34, 60, 24);

    // 左右两个圆形按钮
    CGFloat circleSize = 56;
    CGFloat circleY = MAX(80, buttonTop - 220);
    self.cancelButton.frame = CGRectMake(24, circleY, circleSize, circleSize);
    self.textButton.frame = CGRectMake(bounds.size.width - 24 - circleSize, circleY, circleSize, circleSize);
    self.cancelLabel.frame = CGRectMake(12, CGRectGetMaxY(self.cancelButton.frame) + 8, 80, 18);
    self.textLabel.frame = CGRectMake(bounds.size.width - 12 - 110, CGRectGetMaxY(self.textButton.frame) + 8, 110, 18);

    // 识别文字气泡，高度按内容计算，向上生长
    CGFloat bubbleWidth = bounds.size.width - 32;
    CGFloat bubbleBottom = CGRectGetMinY(self.hintPill.frame) - 16;
    CGFloat bubbleHeight = [self bubbleHeightForText:self.bubbleLabel.text width:bubbleWidth - 32];
    self.bubbleView.frame = CGRectMake(16, bubbleBottom - bubbleHeight, bubbleWidth, bubbleHeight);
    self.bubbleLabel.frame = CGRectMake(16, 12, bubbleWidth - 32, bubbleHeight - 24);

    // 编辑文字界面
    CGFloat editBubbleWidth = bounds.size.width - 32;
    CGFloat actionRowHeight = 56;
    CGFloat actionRowY = MAX(buttonTop - 8, buttonMidY - actionRowHeight / 2);
    CGFloat editBubbleBottom = actionRowY - 20 - self.keyboardOffset + 0;
    CGFloat editBubbleHeight = MAX(64, [self bubbleHeightForText:self.editTextView.text width:editBubbleWidth - 32]);
    self.editBubbleView.frame = CGRectMake(16, editBubbleBottom - editBubbleHeight, editBubbleWidth, editBubbleHeight);
    self.editTextView.frame = CGRectMake(12, 8, editBubbleWidth - 24, editBubbleHeight - 16);

    CGFloat offsetY = -self.keyboardOffset;
    self.editCancelButton.frame = CGRectMake(20, actionRowY + offsetY, circleSize, circleSize);
    self.editSendVoiceButton.frame = CGRectMake(20 + circleSize + 12, actionRowY + offsetY, circleSize, circleSize);
    CGFloat sendWidth = 96;
    self.editSendTextButton.frame = CGRectMake(bounds.size.width - 20 - sendWidth, actionRowY + offsetY + 6, sendWidth, 44);
}

- (CGFloat)bubbleHeightForText:(NSString *)text width:(CGFloat)width {
    if (!text.length) {
        return 64;
    }
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, 200)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20]}
                                     context:nil];
    return MAX(64, ceil(rect.size.height) + 24);
}

#pragma mark - 对外接口

- (void)show {
    self.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
    }];
    [self.waveView startAnimating];
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)updateZoneWithPoint:(CGPoint)point {
    if (self.editing) {
        return;
    }
    WFCUVoiceInputZone zone;
    CGFloat boundaryY = self.recordButtonFrame.origin.y - 20;
    if (point.y >= boundaryY) {
        zone = WFCUVoiceInputZoneSend;
    } else if (point.x < self.bounds.size.width / 2) {
        zone = WFCUVoiceInputZoneCancel;
    } else {
        zone = self.speechToTextEnabled ? WFCUVoiceInputZoneText : WFCUVoiceInputZoneCancel;
    }
    [self setZone:zone];
}

- (void)setZone:(WFCUVoiceInputZone)zone {
    if (_zone == zone) {
        return;
    }
    _zone = zone;
    switch (zone) {
        case WFCUVoiceInputZoneCancel:
            self.hintLabel.text = WFCString(@"VoiceInputReleaseToCancel");
            self.hintPill.backgroundColor = WFCU_VOICE_RED_COLOR;
            self.bubbleView.alpha = 0;
            self.waveView.hidden = NO;
            self.cancelButton.backgroundColor = WFCU_VOICE_PILL_SELECTED_COLOR;
            self.cancelLabel.textColor = [UIColor whiteColor];
            self.textButton.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.textLabel.textColor = WFCU_VOICE_LABEL_COLOR;
            break;
        case WFCUVoiceInputZoneText:
            self.hintLabel.text = WFCString(@"VoiceInputReleaseToEdit");
            self.hintPill.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.bubbleView.alpha = 1;
            self.waveView.hidden = NO;
            self.cancelButton.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.cancelLabel.textColor = WFCU_VOICE_LABEL_COLOR;
            self.textButton.backgroundColor = WFCU_VOICE_PILL_SELECTED_COLOR;
            self.textLabel.textColor = [UIColor whiteColor];
            break;
        default:
            self.hintLabel.text = WFCString(@"VoiceInputReleaseToSend");
            self.hintPill.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.bubbleView.alpha = 0;
            self.waveView.hidden = NO;
            self.cancelButton.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.cancelLabel.textColor = WFCU_VOICE_LABEL_COLOR;
            self.textButton.backgroundColor = WFCU_VOICE_PILL_COLOR;
            self.textLabel.textColor = WFCU_VOICE_LABEL_COLOR;
            break;
    }
    if ([self.delegate respondsToSelector:@selector(voiceInputView:didChangeZone:)]) {
        [self.delegate voiceInputView:self didChangeZone:zone];
    }
}

- (void)setSpeechToTextEnabled:(BOOL)speechToTextEnabled {
    _speechToTextEnabled = speechToTextEnabled;
    self.textButton.hidden = !speechToTextEnabled;
    self.textLabel.hidden = !speechToTextEnabled;
}

- (void)setVoiceLevel:(CGFloat)level {
    [self.waveView setLevel:level];
}

- (void)setRecognizedText:(NSString *)text {
    if (!text.length) {
        return;
    }
    self.bubbleLabel.text = text;
    [self setNeedsLayout];
}

- (void)showTooShortTip {
    self.bubbleView.backgroundColor = WFCU_VOICE_RED_COLOR;
    self.bubbleLabel.text = WFCString(@"RecordingTooShort");
    self.bubbleView.alpha = 1;
    [self setNeedsLayout];
}

- (void)enterEditing:(NSString *)text {
    if (self.editing) {
        return;
    }
    self.editing = YES;
    self.userEdited = NO;
    self.editingFinished = NO;
    self.editTextView.text = text;
    self.recordingContainer.hidden = YES;
    self.editingContainer.hidden = NO;
    self.userInteractionEnabled = YES;
    [self setNeedsLayout];
    [self.editTextView becomeFirstResponder];
}

- (void)updateEditingText:(NSString *)text finished:(BOOL)finished {
    self.editingFinished = finished;
    if (!self.userEdited) {
        self.editTextView.text = text;
        [self setNeedsLayout];
    }
    self.editSendVoiceButton.hidden = NO;
}

- (NSString *)editingText {
    return self.editTextView.text ?: @"";
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    self.userEdited = YES;
    [self setNeedsLayout];
}

#pragma mark - 按钮事件

- (void)onEditCancelClick {
    if ([self.delegate respondsToSelector:@selector(voiceInputViewDidCancel:)]) {
        [self.delegate voiceInputViewDidCancel:self];
    }
}

- (void)onEditSendVoiceClick {
    if ([self.delegate respondsToSelector:@selector(voiceInputViewDidSendVoice:)]) {
        [self.delegate voiceInputViewDidSendVoice:self];
    }
}

- (void)onEditSendTextClick {
    if ([self.delegate respondsToSelector:@selector(voiceInputView:didSendText:)]) {
        [self.delegate voiceInputView:self didSendText:self.editTextView.text ?: @""];
    }
}

#pragma mark - 键盘

- (void)keyboardWillChangeFrame:(NSNotification *)note {
    if (!self.editing) {
        return;
    }
    CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardInSelf = [self convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.bounds) - CGRectGetMinY(keyboardInSelf));
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.keyboardOffset = overlap;
    [UIView animateWithDuration:duration animations:^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }];
}

@end
