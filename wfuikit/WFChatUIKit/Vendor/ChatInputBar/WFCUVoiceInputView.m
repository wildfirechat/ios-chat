//
//  WFCUVoiceInputView.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUVoiceInputView.h"
#import "WFCUImage.h"
#import "WFCUConfigManager.h"
#import "UIImage+ERCategory.h"
#import <AudioToolbox/AudioToolbox.h>

#define WFCU_VOICE_RED_COLOR         [UIColor colorWithRed:0xFA/255.f green:0x51/255.f blue:0x51/255.f alpha:1.f]
#define WFCU_VOICE_DIM_MASK          [UIColor colorWithRed:0x11/255.f green:0x11/255.f blue:0x11/255.f alpha:0.8f]
#define WFCU_VOICE_PANEL_COLOR       [UIColor colorWithRed:0x44/255.f green:0x44/255.f blue:0x44/255.f alpha:1.f]
#define WFCU_VOICE_ARC_COLOR         [UIColor colorWithRed:0x57/255.f green:0x57/255.f blue:0x57/255.f alpha:1.f]
#define WFCU_VOICE_ARC_TOP_COLOR     [UIColor colorWithRed:0x63/255.f green:0x63/255.f blue:0x63/255.f alpha:1.f]
#define WFCU_VOICE_ARC_BOTTOM_COLOR  [UIColor colorWithRed:0x80/255.f green:0x80/255.f blue:0x80/255.f alpha:1.f]
#define WFCU_VOICE_ARC_RIM_COLOR     [UIColor colorWithRed:0x76/255.f green:0x76/255.f blue:0x76/255.f alpha:1.f]
#define WFCU_VOICE_PILL_COLOR        [UIColor colorWithRed:0x57/255.f green:0x57/255.f blue:0x57/255.f alpha:1.f]
#define WFCU_VOICE_PILL_SELECTED     [UIColor colorWithRed:0x9A/255.f green:0x9A/255.f blue:0x9A/255.f alpha:1.f]
#define WFCU_VOICE_PILL_LABEL        [UIColor colorWithRed:0xE6/255.f green:0xE6/255.f blue:0xE6/255.f alpha:1.f]
#define WFCU_VOICE_LABEL_SELECTED    [UIColor colorWithRed:0x11/255.f green:0x11/255.f blue:0x11/255.f alpha:1.f]
#define WFCU_VOICE_HINT_COLOR        [UIColor colorWithRed:0xD0/255.f green:0xD0/255.f blue:0xD0/255.f alpha:1.f]
#define WFCU_VOICE_ACTION_TEXT       [UIColor colorWithRed:0xBD/255.f green:0xBD/255.f blue:0xBD/255.f alpha:1.f]
#define WFCU_VOICE_SEND_BUTTON       [UIColor colorWithRed:0xDA/255.f green:0xDA/255.f blue:0xDA/255.f alpha:1.f]
#define WFCU_VOICE_SEND_PRESSED      [UIColor colorWithRed:0xBD/255.f green:0xBD/255.f blue:0xBD/255.f alpha:1.f]
// 发送按钮禁用态，与 Android 的 voice_input_send_button_bg.xml / voice_input_send_text.xml 一致
#define WFCU_VOICE_SEND_DISABLED      [UIColor colorWithRed:0x4E/255.f green:0x4E/255.f blue:0x4E/255.f alpha:1.f]
#define WFCU_VOICE_SEND_DISABLED_TEXT [UIColor colorWithRed:0x73/255.f green:0x73/255.f blue:0x73/255.f alpha:1.f]

// App 主色调，与 Android 的 colorPrimary 一致
static UIColor *WFCUAppPrimaryColor(void) {
    return [WFCUConfigManager globalManager].primaryColor;
}

// 与 Android 的 ColorUtils.calculateLuminance 一致，先把 sRGB 分量转成线性值再计算亮度
static CGFloat WFCULinearColorComponent(CGFloat component) {
    return component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4);
}

static UIColor *WFCUContentColorForPrimaryColor(UIColor *primaryColor) {
    if (!primaryColor) return [UIColor colorWithRed:0x19/255.f green:0x19/255.f blue:0x19/255.f alpha:1.f];
    CGFloat r = 0, g = 0, b = 0, a = 0;
    if (![primaryColor getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:0x19/255.f green:0x19/255.f blue:0x19/255.f alpha:1.f];
    }
    double luminance = 0.2126 * WFCULinearColorComponent(r) + 0.7152 * WFCULinearColorComponent(g) + 0.0722 * WFCULinearColorComponent(b);
    if (luminance > 0.3) {
        return [UIColor colorWithRed:0x19/255.f green:0x19/255.f blue:0x19/255.f alpha:1.f];
    } else {
        return [UIColor whiteColor];
    }
}

static UIColor *WFCUColorBlend(UIColor *from, UIColor *to, CGFloat fraction) {
    if (!from) return to ?: [UIColor clearColor];
    if (!to) return from;
    fraction = MAX(0, MIN(1, fraction));
    CGFloat r1 = 0, g1 = 0, b1 = 0, a1 = 0;
    CGFloat r2 = 0, g2 = 0, b2 = 0, a2 = 0;
    if (![from getRed:&r1 green:&g1 blue:&b1 alpha:&a1]) return to;
    if (![to getRed:&r2 green:&g2 blue:&b2 alpha:&a2]) return from;
    return [UIColor colorWithRed:r1 + (r2 - r1) * fraction
                           green:g1 + (g2 - g1) * fraction
                            blue:b1 + (b2 - b1) * fraction
                           alpha:a1 + (a2 - a1) * fraction];
}

#pragma mark - 1. 浮层背景 (VoiceInputBackground)

@interface WFCUVoiceInputBackgroundView : UIView
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat panelTop;
@property (nonatomic, assign) CGFloat stageLeft;
@property (nonatomic, assign) CGFloat stageRight;
@property (nonatomic, assign) CGFloat fadeHeight;
- (void)animatePanelTop:(CGFloat)panelTop duration:(CGFloat)duration;
@end

@interface WFCUVoiceInputBackgroundView ()
@property (nonatomic, strong) CADisplayLink *panelDisplayLink;
@property (nonatomic, assign) CFTimeInterval panelAnimStartTime;
@property (nonatomic, assign) CGFloat panelAnimDuration;
@property (nonatomic, assign) CGFloat fromPanelTop;
@property (nonatomic, assign) CGFloat toPanelTop;
@end

@implementation WFCUVoiceInputBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _fadeHeight = 130.0;
        _stageLeft = 0;
        _stageRight = frame.size.width > 0 ? frame.size.width : [UIScreen mainScreen].bounds.size.width;
        _panelTop = frame.size.height > 0 ? frame.size.height * 0.7 : [UIScreen mainScreen].bounds.size.height * 0.7;
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setPanelTop:(CGFloat)panelTop {
    _panelTop = panelTop;
    [self setNeedsDisplay];
}

/**
 * 深灰背景的上边缘平滑移动到指定位置，drawRect 绘制的背景不能用 UIView 动画
 */
- (void)animatePanelTop:(CGFloat)panelTop duration:(CGFloat)duration {
    self.fromPanelTop = self.panelTop;
    self.toPanelTop = panelTop;
    self.panelAnimDuration = MAX(0.01, duration);
    self.panelAnimStartTime = CACurrentMediaTime();
    if (!self.panelDisplayLink) {
        self.panelDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onPanelAnimTick:)];
        [self.panelDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)onPanelAnimTick:(CADisplayLink *)link {
    CGFloat progress = MIN(1.0, (CACurrentMediaTime() - self.panelAnimStartTime) / self.panelAnimDuration);
    CGFloat t = 1.0 - pow(1.0 - progress, 3.0);
    self.panelTop = self.fromPanelTop + (self.toPanelTop - self.fromPanelTop) * t;
    if (progress >= 1.0) {
        // CADisplayLink 会强引用 target，动画结束就释放
        [self.panelDisplayLink invalidate];
        self.panelDisplayLink = nil;
    }
}

- (void)drawRect:(CGRect)rect {
    if (self.progress <= 0) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat right = self.stageRight > self.stageLeft ? self.stageRight : rect.size.width;
    CGFloat width = right - self.stageLeft;
    if (width <= 0) return;

    // 1. 全屏半透明遮罩
    UIColor *dimColor = [WFCU_VOICE_DIM_MASK colorWithAlphaComponent:CGColorGetAlpha(WFCU_VOICE_DIM_MASK.CGColor) * self.progress];
    [dimColor setFill];
    CGContextFillRect(ctx, rect);

    // 2. 底部深灰背景 + 顶部渐变
    CGFloat fadeTop = self.panelTop - self.fadeHeight;
    CGFloat bottomLimit = MAX(rect.size.height + 500.0, self.panelTop + 500.0);
    CGRect stageRect = CGRectMake(self.stageLeft, MAX(rect.origin.y, fadeTop), width, bottomLimit - MAX(rect.origin.y, fadeTop));

    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, stageRect);

    // 渐变部分 (fadeTop -> panelTop)
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat panelR, panelG, panelB, panelA;
    [WFCU_VOICE_PANEL_COLOR getRed:&panelR green:&panelG blue:&panelB alpha:&panelA];
    
    CGFloat colors[] = {
        panelR, panelG, panelB, 0.0 * self.progress,
        panelR, panelG, panelB, 1.0 * self.progress
    };
    CGFloat locations[] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 2);

    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(self.stageLeft, fadeTop), CGPointMake(self.stageLeft, self.panelTop), kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    // 纯色部分 (panelTop -> bottomLimit)
    UIColor *panelColor = [WFCU_VOICE_PANEL_COLOR colorWithAlphaComponent:1.0 * self.progress];
    [panelColor setFill];
    CGContextFillRect(ctx, CGRectMake(self.stageLeft, self.panelTop, width, bottomLimit - self.panelTop));

    CGContextRestoreGState(ctx);
}

@end

#pragma mark - 2. 实时声波 view (VoiceWaveView)

@interface WFCUVoiceWaveView : UIView
@property (nonatomic, strong) UIColor *barColor;
@property (nonatomic, assign) BOOL loading;
- (void)setLevel:(CGFloat)level;
- (void)startAnimation;
- (void)stopAnimation;
@end

@interface WFCUVoiceWaveView () {
    CGFloat _heights[30];
    CGFloat _targets[30];
    NSInteger _barCount;
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastFrameTime;
@property (nonatomic, assign) CGFloat level;
@property (nonatomic, assign) CGFloat loadingProgress;
@end

@implementation WFCUVoiceWaveView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _barColor = [UIColor whiteColor];
        _barCount = 0;
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor;
    [self setNeedsDisplay];
}

- (void)setLoading:(BOOL)loading {
    if (_loading != loading) {
        _loading = loading;
        [self setNeedsDisplay];
    }
}

- (void)setLevel:(CGFloat)level {
    _level = MAX(0, MIN(1, level));
    [self updateTargets];
}

- (void)updateTargets {
    if (_barCount <= 0) return;
    for (NSInteger i = 0; i < _barCount; i++) {
        CGFloat x = _barCount == 1 ? 0 : (CGFloat)i / (_barCount - 1) * 2.0 - 1.0;
        CGFloat envelope = 0.3 + 0.7 * exp(-x * x * 2.5);
        CGFloat jitter = 0.5 + 0.5 * ((CGFloat)arc4random() / UINT32_MAX);
        CGFloat idle = 0.06 + 0.1 * ((CGFloat)arc4random() / UINT32_MAX) * envelope;
        _targets[i] = MIN(1.0, idle + _level * envelope * jitter * 1.2);
    }
    [self setNeedsDisplay];
}

- (void)ensureBars {
    CGFloat barWidth = 2.0;
    CGFloat barGap = 2.2;
    NSInteger count = MAX(1, (NSInteger)((self.bounds.size.width + barGap) / (barWidth + barGap)));
    count = MIN(30, count);
    if (count == _barCount) return;
    _barCount = count;
    [self updateTargets];
}

- (void)startAnimation {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
    self.lastFrameTime = CACurrentMediaTime();
}

- (void)stopAnimation {
    self.displayLink.paused = YES;
    self.lastFrameTime = 0;
}

- (void)onTick:(CADisplayLink *)link {
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval dt = self.lastFrameTime == 0 ? 0.016 : MIN(0.064, now - self.lastFrameTime);
    self.lastFrameTime = now;

    // loading 动画淡入淡出
    CGFloat targetLoading = self.loading ? 1.0 : 0.0;
    self.loadingProgress += (targetLoading - self.loadingProgress) * (1.0 - exp(-dt / 0.1));

    for (NSInteger i = 0; i < _barCount; i++) {
        CGFloat target = self.loading ? 0.0 : _targets[i];
        CGFloat timeConstant = target > _heights[i] ? 0.05 : 0.14;
        _heights[i] += (target - _heights[i]) * (1.0 - exp(-dt / timeConstant));
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (rect.size.width <= 0 || rect.size.height <= 0) return;
    [self ensureBars];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx || _barCount <= 0) return;

    CGFloat barWidth = 2.0;
    CGFloat barGap = 2.2;
    CGFloat minBarHeight = 3.0;
    CGFloat totalWidth = _barCount * barWidth + (_barCount - 1) * barGap;
    CGFloat left = (rect.size.width - totalWidth) / 2.0;
    CGFloat centerY = rect.size.height / 2.0;
    CGFloat range = MAX(0, rect.size.height - minBarHeight);

    CGFloat barAlpha = 1.0 - self.loadingProgress;
    CGFloat baseAlpha = CGColorGetAlpha(self.barColor.CGColor);

    if (barAlpha > 0.01) {
        UIColor *currentColor = [self.barColor colorWithAlphaComponent:baseAlpha * barAlpha];
        [currentColor setFill];
        for (NSInteger i = 0; i < _barCount; i++) {
            CGFloat h = minBarHeight + range * _heights[i];
            CGRect barRect = CGRectMake(left, centerY - h / 2.0, barWidth, h);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:barWidth / 2.0];
            [path fill];
            left += barWidth + barGap;
        }
    }

    if (self.loadingProgress > 0.01) {
        // 3 个圆点跳动等待
        CGFloat dotRadius = 2.6;
        CGFloat dotSpacing = 9.0;
        CFTimeInterval now = CACurrentMediaTime();
        double phase = now * M_PI * 2.0 * 1.2;
        CGFloat centerX = rect.size.width / 2.0;

        for (NSInteger i = 0; i < 3; i++) {
            CGFloat pulse = 0.5 + 0.5 * sin(phase - i * 0.9);
            CGFloat r = dotRadius * (0.7 + 0.3 * pulse) * (0.5 + 0.5 * self.loadingProgress);
            UIColor *dotColor = [self.barColor colorWithAlphaComponent:baseAlpha * self.loadingProgress * (0.4 + 0.6 * pulse)];
            [dotColor setFill];

            CGFloat cx = centerX + (i - 1) * dotSpacing;
            UIBezierPath *dotPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx, centerY) radius:r startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            [dotPath fill];
        }
    }
}

@end

#pragma mark - 3. 底部操作区 (VoiceRecordBottomView)

@interface WFCUVoiceRecordBottomView : UIView
@property (nonatomic, assign) BOOL speechToTextEnabled;
@property (nonatomic, assign) BOOL hasStage;
@property (nonatomic, assign) CGFloat stageLeft;
@property (nonatomic, assign) CGFloat stageRight;
@property (nonatomic, assign) CGFloat stageWidth;
@property (nonatomic, assign) CGFloat centerX;

@property (nonatomic, assign) CGFloat arcTop;
@property (nonatomic, assign) CGFloat arcRadius;
@property (nonatomic, assign) CGFloat arcCenterY;

@property (nonatomic, assign) CGFloat pillThickness;
@property (nonatomic, assign) CGFloat pillGap;
@property (nonatomic, assign) CGFloat pillRadius;
@property (nonatomic, assign) CGFloat pillCenterY;
@property (nonatomic, assign) CGFloat labelOffsetX;
@property (nonatomic, assign) CGFloat maxLabelWidth;

@property (nonatomic, assign) WFCUVoiceInputZone zone;
@property (nonatomic, assign) CGFloat appear;
@end

@interface WFCUVoiceRecordBottomView () {
    CGFloat _selection[3];
    CGFloat _fromSelection[3];
}
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval selectionAnimStartTime;
@property (nonatomic, assign) WFCUVoiceInputZone targetZone;

@property (nonatomic, assign) CFTimeInterval appearAnimStartTime;
@property (nonatomic, assign) CGFloat fromAppear;
@property (nonatomic, assign) CGFloat targetAppear;
@property (nonatomic, assign) CGFloat appearDuration;
@property (nonatomic, copy) void (^appearCompletion)(void);
@end

@implementation WFCUVoiceRecordBottomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _zone = WFCUVoiceInputZoneSend;
        _selection[WFCUVoiceInputZoneSend] = 1.0;
        _selection[WFCUVoiceInputZoneCancel] = 0.0;
        _selection[WFCUVoiceInputZoneText] = 0.0;
        _appear = 0.0;
    }
    return self;
}

- (void)dealloc {
    [self.displayLink invalidate];
}

- (void)setStageLeft:(CGFloat)left right:(CGFloat)right arcTop:(CGFloat)arcTop {
    _stageLeft = left;
    _stageRight = right;
    _stageWidth = right - left;
    _centerX = left + _stageWidth / 2.0;
    _arcTop = arcTop;
    _arcRadius = _stageWidth * 1.68;
    _arcCenterY = arcTop + _arcRadius;

    _pillThickness = MAX(56.0, MIN(72.0, _stageWidth * 0.17));
    _pillGap = 22.0;
    _pillRadius = _stageWidth * 1.72;
    _pillCenterY = arcTop - 16.0 - _pillThickness / 2.0 + _pillRadius;
    _labelOffsetX = MIN(_stageWidth * 0.29, 170.0);
    _maxLabelWidth = MAX(48.0, 2 * MIN(_labelOffsetX - _pillGap / 2.0 - 12.0, _stageWidth / 2.0 - 8.0 - _labelOffsetX));
    _hasStage = YES;
    [self setNeedsDisplay];
}

- (CGFloat)pillTop {
    return _pillCenterY - _pillRadius - _pillThickness / 2.0;
}

- (CGFloat)cancelCenterX {
    return _centerX - _labelOffsetX;
}

- (CGFloat)textCenterX {
    return _centerX + _labelOffsetX;
}

- (WFCUVoiceInputZone)zoneAtPoint:(CGPoint)pt {
    if (!self.hasStage) return WFCUVoiceInputZoneSend;
    CGFloat dx = pt.x - self.centerX;
    if (fabs(dx) < self.arcRadius) {
        CGFloat arcY = self.arcCenterY - sqrt(self.arcRadius * self.arcRadius - dx * dx);
        if (pt.y >= arcY) {
            return WFCUVoiceInputZoneSend;
        }
    }
    return (self.speechToTextEnabled && pt.x >= self.centerX) ? WFCUVoiceInputZoneText : WFCUVoiceInputZoneCancel;
}

- (void)setZone:(WFCUVoiceInputZone)zone {
    if (_zone == zone) return;
    _zone = zone;
    self.targetZone = zone;
    for (int i = 0; i < 3; i++) {
        _fromSelection[i] = _selection[i];
    }
    self.selectionAnimStartTime = CACurrentMediaTime();
    [self startDisplayLink];
}

- (void)showWithDuration:(CGFloat)duration {
    [self animateAppearTo:1.0 duration:duration completion:nil];
}

- (void)hideWithDuration:(CGFloat)duration completion:(void(^)(void))completion {
    [self animateAppearTo:0.0 duration:duration completion:completion];
}

- (void)animateAppearTo:(CGFloat)target duration:(CGFloat)duration completion:(void(^)(void))completion {
    self.fromAppear = self.appear;
    self.targetAppear = target;
    self.appearDuration = duration;
    self.appearCompletion = completion;
    self.appearAnimStartTime = CACurrentMediaTime();
    [self startDisplayLink];
}

- (void)startDisplayLink {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onAnimTick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
}

- (void)onAnimTick:(CADisplayLink *)link {
    CFTimeInterval now = CACurrentMediaTime();
    BOOL animating = NO;

    // Selection 动画 (220ms)
    if (self.selectionAnimStartTime > 0) {
        CGFloat elapsed = now - self.selectionAnimStartTime;
        CGFloat progress = MIN(1.0, elapsed / 0.22);
        CGFloat t = 1.0 - pow(1.0 - progress, 1.5); // Decelerate
        for (int i = 0; i < 3; i++) {
            CGFloat targetVal = (i == self.targetZone) ? 1.0 : 0.0;
            _selection[i] = _fromSelection[i] + (targetVal - _fromSelection[i]) * t;
        }
        if (progress >= 1.0) {
            self.selectionAnimStartTime = 0;
        } else {
            animating = YES;
        }
    }

    // Appear 动画
    if (self.appearAnimStartTime > 0) {
        CGFloat elapsed = now - self.appearAnimStartTime;
        CGFloat progress = MIN(1.0, elapsed / MAX(0.01, self.appearDuration));
        CGFloat t = (self.targetAppear > self.fromAppear) ? (1.0 - pow(1.0 - progress, 2.0)) : pow(progress, 1.5);
        _appear = self.fromAppear + (self.targetAppear - self.fromAppear) * t;
        if (progress >= 1.0) {
            self.appearAnimStartTime = 0;
            if (self.appearCompletion) {
                void (^block)(void) = self.appearCompletion;
                self.appearCompletion = nil;
                block();
            }
        } else {
            animating = YES;
        }
    }

    [self setNeedsDisplay];

    if (!animating && self.selectionAnimStartTime == 0 && self.appearAnimStartTime == 0) {
        self.displayLink.paused = YES;
    }
}

- (void)reset {
    _zone = WFCUVoiceInputZoneSend;
    _selection[WFCUVoiceInputZoneSend] = 1.0;
    _selection[WFCUVoiceInputZoneCancel] = 0.0;
    _selection[WFCUVoiceInputZoneText] = 0.0;
    _appear = 0.0;
    self.selectionAnimStartTime = 0;
    self.appearAnimStartTime = 0;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    if (!self.hasStage || self.appear <= 0) return;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, CGRectMake(self.stageLeft, 0, self.stageWidth, rect.size.height));

    // 绘制底部弧形区域
    [self drawArcAreaInContext:ctx rect:rect];

    // 按钮延迟升起
    CGFloat pillAppear = MAX(0.0, MIN(1.0, (self.appear - 0.15) / 0.85));
    if (pillAppear > 0) {
        CGContextSaveGState(ctx);
        CGFloat translateY = (1.0 - pillAppear) * (rect.size.height - [self pillTop]);
        CGContextTranslateCTM(ctx, 0, translateY);

        [self drawPillInContext:ctx isLeft:YES selected:_selection[WFCUVoiceInputZoneCancel] label:WFCString(@"Cancel") hint:WFCString(@"VoiceInputReleaseToCancel") alpha:pillAppear];
        if (self.speechToTextEnabled) {
            [self drawPillInContext:ctx isLeft:NO selected:_selection[WFCUVoiceInputZoneText] label:WFCString(@"VoiceInputSlideToText") hint:WFCString(@"VoiceInputReleaseToEdit") alpha:pillAppear];
        }
        CGContextRestoreGState(ctx);
    }

    CGContextRestoreGState(ctx);
}

- (void)drawArcAreaInContext:(CGContextRef)ctx rect:(CGRect)rect {
    CGFloat selected = _selection[WFCUVoiceInputZoneSend];
    CGContextSaveGState(ctx);
    CGFloat translateY = (1.0 - self.appear) * (rect.size.height - self.arcTop);
    CGContextTranslateCTM(ctx, 0, translateY);

    // 大圆底色
    CGRect circleBounds = CGRectMake(self.centerX - self.arcRadius, self.arcCenterY - self.arcRadius, self.arcRadius * 2, self.arcRadius * 2);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:circleBounds];
    [WFCU_VOICE_ARC_COLOR setFill];
    [circlePath fill];

    if (selected > 0) {
        // 高亮渐变
        CGContextSaveGState(ctx);
        [circlePath addClip];

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
        [WFCU_VOICE_ARC_TOP_COLOR getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
        [WFCU_VOICE_ARC_BOTTOM_COLOR getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
        CGFloat colors[] = {
            r1, g1, b1, a1 * selected,
            r2, g2, b2, a2 * selected
        };
        CGFloat locations[] = {0.0, 1.0};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, 2);
        CGContextDrawLinearGradient(ctx, gradient, CGPointMake(self.centerX, self.arcTop), CGPointMake(self.centerX, rect.size.height), 0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        CGContextRestoreGState(ctx);

        // 边框 rim
        UIColor *rimColor = [WFCU_VOICE_ARC_RIM_COLOR colorWithAlphaComponent:selected];
        [rimColor setStroke];
        UIBezierPath *rimPath = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(circleBounds, 1.0, 1.0)];
        rimPath.lineWidth = 2.0;
        [rimPath stroke];
    }

    // 文字: "语音" 与 "松开 发送"
    CGFloat labelCenterY = self.arcTop + 44.0 - 8.0 * selected;
    if (1.0 - selected > 0.01) {
        [self drawCenteredText:WFCString(@"VoiceInputVoice") inContext:ctx centerY:labelCenterY color:[WFCU_VOICE_PILL_LABEL colorWithAlphaComponent:1.0 - selected] font:[UIFont boldSystemFontOfSize:18]];
    }
    if (selected > 0.01) {
        [self drawCenteredText:WFCString(@"VoiceInputReleaseToSend") inContext:ctx centerY:labelCenterY color:[WFCU_VOICE_LABEL_SELECTED colorWithAlphaComponent:selected] font:[UIFont boldSystemFontOfSize:18]];
    }

    CGContextRestoreGState(ctx);
}

- (void)drawCenteredText:(NSString *)text inContext:(CGContextRef)ctx centerY:(CGFloat)centerY color:(UIColor *)color font:(UIFont *)font {
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    CGSize size = [text sizeWithAttributes:attrs];
    CGRect rect = CGRectMake(self.centerX - size.width / 2.0, centerY - size.height / 2.0, size.width, size.height);
    [text drawInRect:rect withAttributes:attrs];
}

- (void)drawPillInContext:(CGContextRef)ctx isLeft:(BOOL)isLeft selected:(CGFloat)selected label:(NSString *)label hint:(NSString *)hint alpha:(CGFloat)alpha {
    CGFloat thickness = self.pillThickness * (1.0 + 0.06 * selected);
    CGFloat innerDegrees = asin((self.pillGap / 2.0 + self.pillThickness / 2.0) / self.pillRadius);
    CGFloat outerDegrees = asin(MIN(1.0, (self.stageWidth / 2.0 + thickness) / self.pillRadius));

    CGFloat startAngle = isLeft ? -M_PI_2 - outerDegrees : -M_PI_2 + innerDegrees;
    CGFloat sweepAngle = outerDegrees - innerDegrees;

    // 绘制弧形按钮柱
    UIBezierPath *arcPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.centerX, self.pillCenterY)
                                                           radius:self.pillRadius
                                                       startAngle:startAngle
                                                         endAngle:startAngle + sweepAngle
                                                        clockwise:YES];
    arcPath.lineWidth = thickness;
    arcPath.lineCapStyle = kCGLineCapRound;

    UIColor *pillColor = WFCUColorBlend(WFCU_VOICE_PILL_COLOR, WFCU_VOICE_PILL_SELECTED, selected);
    [[pillColor colorWithAlphaComponent:CGColorGetAlpha(pillColor.CGColor) * alpha] setStroke];
    [arcPath stroke];

    // 绘制按钮文字 (沿弧线绘制)
    CGFloat offsetX = isLeft ? -self.labelOffsetX : self.labelOffsetX;
    UIColor *labelColor = WFCUColorBlend(WFCU_VOICE_PILL_LABEL, WFCU_VOICE_LABEL_SELECTED, selected);
    [self drawTextOnArc:label inContext:ctx center:CGPointMake(self.centerX, self.pillCenterY) radius:self.pillRadius offsetX:offsetX font:[UIFont systemFontOfSize:17] color:[labelColor colorWithAlphaComponent:alpha] maxWidth:self.maxLabelWidth];

    // 绘制上方的提示文字 (松开 取消 / 松开 识别并编辑)
    if (selected > 0) {
        CGFloat hintRadius = self.pillRadius + thickness / 2.0 + 24.0 - 8.0 * (1.0 - selected);
        UIColor *hintColor = [WFCU_VOICE_HINT_COLOR colorWithAlphaComponent:alpha * selected];
        [self drawTextOnArc:hint inContext:ctx center:CGPointMake(self.centerX, self.pillCenterY) radius:hintRadius offsetX:offsetX font:[UIFont systemFontOfSize:14] color:hintColor maxWidth:self.maxLabelWidth + 40.0];
    }
}

- (void)drawTextOnArc:(NSString *)text inContext:(CGContextRef)ctx center:(CGPoint)center radius:(CGFloat)radius offsetX:(CGFloat)offsetX font:(UIFont *)font color:(UIColor *)color maxWidth:(CGFloat)maxWidth {
    if (!text.length || CGColorGetAlpha(color.CGColor) == 0) return;

    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    CGSize textSize = [text sizeWithAttributes:attrs];
    CGFloat width = textSize.width;
    UIFont *useFont = font;
    if (width > maxWidth && maxWidth > 0) {
        useFont = [font fontWithSize:font.pointSize * (maxWidth / width)];
        attrs = @{NSFontAttributeName: useFont, NSForegroundColorAttributeName: color};
        textSize = [text sizeWithAttributes:attrs];
        width = maxWidth;
    }

    CGFloat centerAngle = -M_PI_2 + asin(MAX(-1.0, MIN(1.0, offsetX / radius)));
    CGFloat totalAngle = width / radius;
    CGFloat startAngle = centerAngle - totalAngle / 2.0;

    CGFloat currWidth = 0;
    for (NSUInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        CGSize chSize = [ch sizeWithAttributes:attrs];
        CGFloat chAngle = startAngle + (currWidth + chSize.width / 2.0) / radius;
        currWidth += chSize.width;

        CGContextSaveGState(ctx);
        CGFloat cx = center.x + radius * cos(chAngle);
        CGFloat cy = center.y + radius * sin(chAngle);

        CGContextTranslateCTM(ctx, cx, cy);
        CGContextRotateCTM(ctx, chAngle + M_PI_2);

        CGRect chRect = CGRectMake(-chSize.width / 2.0, -chSize.height / 2.0, chSize.width, chSize.height);
        [ch drawInRect:chRect withAttributes:attrs];
        CGContextRestoreGState(ctx);
    }
}

@end

#pragma mark - 4. 语音气泡 Layout (VoiceBubbleView)

typedef NS_ENUM(NSInteger, WFCUBubbleState) {
    WFCUBubbleStateSend = 0,
    WFCUBubbleStateCancel = 1,
    WFCUBubbleStateText = 2,
    WFCUBubbleStateEdit = 3,
    WFCUBubbleStateNoText = 4,
    WFCUBubbleStateTooShort = 5
};

typedef struct {
    CGFloat left;
    CGFloat width;
    CGFloat height;
    CGFloat tailX;
    CGFloat waveWidth;
    CGFloat waveHeight;
    CGFloat waveCenterX;
    CGFloat waveCenterY;
    CGFloat waveAlpha;
    CGFloat textAlpha;
    CGFloat hintAlpha;
    CGFloat textBottomMargin;
    CGFloat r, g, b, a;
    CGFloat waveR, waveG, waveB, waveA;
} WFCUBubbleFrame;

static inline void WFCUSetFrameColor(WFCUBubbleFrame *frame, UIColor *color, BOOL isWave) {
    if (!color) color = [UIColor clearColor];
    CGFloat red = 0, green = 0, blue = 0, alpha = 1.0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    if (isWave) {
        frame->waveR = red; frame->waveG = green; frame->waveB = blue; frame->waveA = alpha;
    } else {
        frame->r = red; frame->g = green; frame->b = blue; frame->a = alpha;
    }
}

@interface WFCUVoiceBubbleView : UIView
@property (nonatomic, strong) UIColor *bubbleColor;
@property (nonatomic, assign) CGFloat tailX;
@property (nonatomic, readonly) CGFloat tailHeight;
@end

@implementation WFCUVoiceBubbleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _bubbleColor = WFCUAppPrimaryColor();
        _tailX = -1;
        _tailHeight = 8.0;
    }
    return self;
}

- (void)setBubbleColor:(UIColor *)bubbleColor {
    _bubbleColor = bubbleColor;
    [self setNeedsDisplay];
}

- (void)setTailX:(CGFloat)tailX {
    _tailX = tailX;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    // 注意：必须用 bounds 而不是 drawRect 传入的 rect（脏区），
    // 否则局部重绘时会按脏区尺寸画出一个尺寸/位置都不对的气泡
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat bodyBottom = height - self.tailHeight;
    if (width <= 0 || bodyBottom <= 0) return;

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat radius = 18.0;
    CGFloat r = MIN(radius, MIN(width, bodyBottom) / 2.0);

    // 1. 气泡主体
    CGRect bodyRect = CGRectMake(0, 0, width, bodyBottom);
    UIBezierPath *bodyPath = [UIBezierPath bezierPathWithRoundedRect:bodyRect cornerRadius:r];
    [self.bubbleColor setFill];
    [bodyPath fill];

    // 2. 底部尖角
    CGFloat tailWidth = 18.0;
    CGFloat half = tailWidth / 2.0;
    CGFloat x = self.tailX < 0 ? width / 2.0 : self.tailX;
    x = MAX(MIN(r + half, width / 2.0), MIN(MAX(width - r - half, width / 2.0), x));

    CGFloat tip = 1.5;
    UIBezierPath *tailPath = [UIBezierPath bezierPath];
    [tailPath moveToPoint:CGPointMake(x - half, bodyBottom - 1.0)];
    [tailPath addLineToPoint:CGPointMake(x - tip, height - 1.0)];
    [tailPath addQuadCurveToPoint:CGPointMake(x + tip, height - 1.0) controlPoint:CGPointMake(x, height)];
    [tailPath addLineToPoint:CGPointMake(x + half, bodyBottom - 1.0)];
    [tailPath closePath];

    [self.bubbleColor setFill];
    [tailPath fill];
}

@end

#pragma mark - 4.1 编辑用输入框

/**
 * 编辑识别文字用的 UITextView。
 *
 * 文字要显示在蓝色气泡上，输入框必须完全透明。只设一次 backgroundColor 并不稳：
 * UIAppearance（例如某些三方 SDK 给 UITextView 设了白底）是在视图加入 window 时才应用的，
 * 会覆盖掉之前设置的 clearColor，结果气泡里就出现一块白色方块。
 * 这里在 init / didMoveToWindow / layoutSubviews 里反复兜底，并把内部容器视图的背景也清掉。
 */
@interface WFCUVoiceEditTextView : UITextView
@end

@implementation WFCUVoiceEditTextView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self wfcu_clearBackground];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self wfcu_clearBackground];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self wfcu_clearBackground];
}

- (void)wfcu_clearBackground {
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.layer.backgroundColor = [UIColor clearColor].CGColor;
    // UITextView 内部还有自己的容器视图，一并清掉，避免残留白底
    for (UIView *subview in self.subviews) {
        subview.backgroundColor = [UIColor clearColor];
        subview.opaque = NO;
    }
}

@end

#pragma mark - 5. 向量图标绘制 Helper

@interface WFCUVectorIconView : UIView
@property (nonatomic, assign) NSInteger iconType; // 0: Close, 1: Sound
@property (nonatomic, strong) UIColor *iconColor;
@end

@implementation WFCUVectorIconView

- (instancetype)initWithFrame:(CGRect)frame iconType:(NSInteger)type {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _iconType = type;
        _iconColor = [UIColor whiteColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    [self.iconColor setStroke];
    [self.iconColor setFill];

    if (self.iconType == 0) {
        // 关闭图标 (X)
        UIBezierPath *path = [UIBezierPath bezierPath];
        CGFloat margin = rect.size.width * 0.33;
        [path moveToPoint:CGPointMake(margin, margin)];
        [path addLineToPoint:CGPointMake(rect.size.width - margin, rect.size.height - margin)];
        [path moveToPoint:CGPointMake(rect.size.width - margin, margin)];
        [path addLineToPoint:CGPointMake(margin, rect.size.height - margin)];
        path.lineWidth = 3.0;
        path.lineCapStyle = kCGLineCapRound;
        [path stroke];
    } else {
        // 音频喇叭图标
        UIBezierPath *speaker = [UIBezierPath bezierPath];
        [speaker moveToPoint:CGPointMake(22, 28)];
        [speaker addLineToPoint:CGPointMake(27, 28)];
        [speaker addLineToPoint:CGPointMake(34, 22)];
        [speaker addLineToPoint:CGPointMake(34, 44)];
        [speaker addLineToPoint:CGPointMake(27, 38)];
        [speaker addLineToPoint:CGPointMake(22, 38)];
        [speaker closePath];
        [speaker fill];

        // 弧形声波
        UIBezierPath *wave1 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(32, 33) radius:6 startAngle:-M_PI_4 endAngle:M_PI_4 clockwise:YES];
        wave1.lineWidth = 2.5;
        wave1.lineCapStyle = kCGLineCapRound;
        [wave1 stroke];

        UIBezierPath *wave2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(32, 33) radius:11 startAngle:-M_PI_4 endAngle:M_PI_4 clockwise:YES];
        wave2.lineWidth = 2.5;
        wave2.lineCapStyle = kCGLineCapRound;
        [wave2 stroke];
    }
}

@end

#pragma mark - 6. 主浮层 (WFCUVoiceInputView)

@interface WFCUVoiceInputView () <UITextViewDelegate>

@property (nonatomic, assign) CGRect recordButtonFrame;

@property (nonatomic, strong) WFCUVoiceInputBackgroundView *backgroundView;
@property (nonatomic, strong) WFCUVoiceRecordBottomView *bottomView;
@property (nonatomic, strong) UILabel *countDownLabel;

@property (nonatomic, strong) WFCUVoiceBubbleView *bubbleView;
@property (nonatomic, strong) WFCUVoiceWaveView *waveView;
@property (nonatomic, strong) UITextView *textEditText;
@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) UIView *editActionsLayout;
@property (nonatomic, strong) UIView *cancelLayout;
@property (nonatomic, strong) UIView *sendVoiceLayout;
@property (nonatomic, strong) UIButton *cancelIconButton;
@property (nonatomic, strong) UIButton *sendVoiceIconButton;
@property (nonatomic, strong) UIButton *sendTextButton;

@property (nonatomic, assign) WFCUVoiceInputZone zone;
@property (nonatomic, assign, readwrite) BOOL editing;
@property (nonatomic, assign) WFCUBubbleState bubbleState;
@property (nonatomic, assign) WFCUBubbleFrame currentBubbleFrame;

@property (nonatomic, assign) CGFloat stageLeft;
@property (nonatomic, assign) CGFloat stageWidth;
@property (nonatomic, assign) CGFloat bubbleBottomMargin;
@property (nonatomic, assign) CGFloat editActionsBottomMargin;
@property (nonatomic, assign) CGFloat keyboardOffset;
@property (nonatomic, assign) BOOL layoutReady;
@property (nonatomic, assign) BOOL asrFinished;
@property (nonatomic, assign) BOOL asrFailed;
@property (nonatomic, assign) BOOL userEditedText;

@property (nonatomic, strong) CADisplayLink *bubbleAnimDisplayLink;
@property (nonatomic, assign) CFTimeInterval bubbleAnimStartTime;
@property (nonatomic, assign) CGFloat bubbleAnimDuration;
@property (nonatomic, assign) WFCUBubbleFrame fromBubbleFrame;
@property (nonatomic, assign) WFCUBubbleFrame toBubbleFrame;

@end

@implementation WFCUVoiceInputView

- (instancetype)initWithFrame:(CGRect)frame recordButtonFrame:(CGRect)recordButtonFrame {
    self = [super initWithFrame:frame];
    if (self) {
        _recordButtonFrame = recordButtonFrame;
        _zone = WFCUVoiceInputZoneSend;
        _bubbleState = WFCUBubbleStateSend;
        self.backgroundColor = [UIColor clearColor];
        [self setupSubviews];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.bubbleAnimDisplayLink invalidate];
}

- (void)setupSubviews {
    // 1. 背景
    self.backgroundView = [[WFCUVoiceInputBackgroundView alloc] initWithFrame:self.bounds];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.backgroundView];

    // 2. 底部操作区
    self.bottomView = [[WFCUVoiceRecordBottomView alloc] initWithFrame:self.bounds];
    self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.bottomView];

    // 3. 倒计时 label
    self.countDownLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.countDownLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    self.countDownLabel.font = [UIFont systemFontOfSize:14];
    self.countDownLabel.textAlignment = NSTextAlignmentCenter;
    self.countDownLabel.hidden = YES;
    [self addSubview:self.countDownLabel];

    UIColor *primaryColor = WFCUAppPrimaryColor();
    UIColor *contentColor = WFCUContentColorForPrimaryColor(primaryColor);

    // 4. 气泡及内容
    self.bubbleView = [[WFCUVoiceBubbleView alloc] initWithFrame:CGRectZero];
    self.bubbleView.alpha = 0;
    // 子视图不允许超出气泡，避免文字/光标区域在气泡外露出边角
    self.bubbleView.clipsToBounds = YES;
    [self addSubview:self.bubbleView];

    self.waveView = [[WFCUVoiceWaveView alloc] initWithFrame:CGRectZero];
    self.waveView.barColor = contentColor;
    [self.bubbleView addSubview:self.waveView];

    self.textEditText = [[WFCUVoiceEditTextView alloc] initWithFrame:CGRectZero];
    self.textEditText.backgroundColor = [UIColor clearColor];
    self.textEditText.opaque = NO;
    self.textEditText.textColor = contentColor;
    self.textEditText.tintColor = contentColor;
    self.textEditText.font = [UIFont systemFontOfSize:20];
    self.textEditText.delegate = self;
    self.textEditText.userInteractionEnabled = NO;
    self.textEditText.textContainerInset = UIEdgeInsetsZero;
    self.textEditText.textContainer.lineFragmentPadding = 0;
    // 浮层是深色的，键盘也用深色，编辑时和浮层连成一个整体，不露出白色的键盘背景
    self.textEditText.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.bubbleView addSubview:self.textEditText];

    self.hintLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hintLabel.backgroundColor = [UIColor clearColor];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.font = [UIFont systemFontOfSize:18];
    self.hintLabel.alpha = 0;
    [self.bubbleView addSubview:self.hintLabel];

    // 5. 编辑状态的操作按钮组 (取消、发送原语音、发送)
    self.editActionsLayout = [[UIView alloc] initWithFrame:CGRectZero];
    self.editActionsLayout.hidden = YES;
    [self addSubview:self.editActionsLayout];

    // 取消按钮布局
    self.cancelLayout = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 96, 96)];
    self.cancelLayout.userInteractionEnabled = YES;
    UITapGestureRecognizer *cancelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEditCancelClick)];
    [self.cancelLayout addGestureRecognizer:cancelTap];

    self.cancelIconButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, 66, 66)];
    self.cancelIconButton.backgroundColor = WFCU_VOICE_ARC_COLOR;
    self.cancelIconButton.layer.cornerRadius = 33;
    self.cancelIconButton.layer.masksToBounds = YES;
    WFCUVectorIconView *closeIcon = [[WFCUVectorIconView alloc] initWithFrame:self.cancelIconButton.bounds iconType:0];
    closeIcon.userInteractionEnabled = NO;
    [self.cancelIconButton addSubview:closeIcon];
    [self.cancelIconButton addTarget:self action:@selector(onEditCancelClick) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelLayout addSubview:self.cancelIconButton];

    UILabel *cancelLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 72, 96, 20)];
    cancelLbl.text = WFCString(@"Cancel");
    cancelLbl.textColor = WFCU_VOICE_ACTION_TEXT;
    cancelLbl.font = [UIFont systemFontOfSize:15];
    cancelLbl.textAlignment = NSTextAlignmentCenter;
    cancelLbl.userInteractionEnabled = NO;
    [self.cancelLayout addSubview:cancelLbl];
    [self.editActionsLayout addSubview:self.cancelLayout];

    // 发送原语音按钮布局
    self.sendVoiceLayout = [[UIView alloc] initWithFrame:CGRectMake(106, 0, 96, 96)];
    self.sendVoiceLayout.userInteractionEnabled = YES;
    UITapGestureRecognizer *sendVoiceTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onEditSendVoiceClick)];
    [self.sendVoiceLayout addGestureRecognizer:sendVoiceTap];

    self.sendVoiceIconButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, 66, 66)];
    self.sendVoiceIconButton.backgroundColor = WFCU_VOICE_ARC_COLOR;
    self.sendVoiceIconButton.layer.cornerRadius = 33;
    self.sendVoiceIconButton.layer.masksToBounds = YES;
    WFCUVectorIconView *soundIcon = [[WFCUVectorIconView alloc] initWithFrame:self.sendVoiceIconButton.bounds iconType:1];
    soundIcon.userInteractionEnabled = NO;
    [self.sendVoiceIconButton addSubview:soundIcon];
    [self.sendVoiceIconButton addTarget:self action:@selector(onEditSendVoiceClick) forControlEvents:UIControlEventTouchUpInside];
    [self.sendVoiceLayout addSubview:self.sendVoiceIconButton];

    UILabel *sendVoiceLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 72, 96, 20)];
    sendVoiceLbl.text = WFCString(@"VoiceInputSendVoice");
    sendVoiceLbl.textColor = WFCU_VOICE_ACTION_TEXT;
    sendVoiceLbl.font = [UIFont systemFontOfSize:15];
    sendVoiceLbl.textAlignment = NSTextAlignmentCenter;
    sendVoiceLbl.userInteractionEnabled = NO;
    [self.sendVoiceLayout addSubview:sendVoiceLbl];
    [self.editActionsLayout addSubview:self.sendVoiceLayout];

    // 发送文字按钮，与 Android 一致用浅灰色，主色调只用在气泡上
    self.sendTextButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.sendTextButton setBackgroundImage:[UIImage imageWithColor:WFCU_VOICE_SEND_BUTTON size:CGSizeMake(1, 1)] forState:UIControlStateNormal];
    [self.sendTextButton setBackgroundImage:[UIImage imageWithColor:WFCU_VOICE_SEND_PRESSED size:CGSizeMake(1, 1)] forState:UIControlStateHighlighted];
    // 与 Android 一致：识别没结束或者文字为空时按钮置灰（底色 #4E4E4E、文字 #737373），
    // 否则删空文字后会一直留着一个浅色（看起来是白色）的方块
    [self.sendTextButton setBackgroundImage:[UIImage imageWithColor:WFCU_VOICE_SEND_DISABLED size:CGSizeMake(1, 1)] forState:UIControlStateDisabled];
    [self.sendTextButton setTitle:WFCString(@"Send") forState:UIControlStateNormal];
    [self.sendTextButton setTitleColor:WFCU_VOICE_LABEL_SELECTED forState:UIControlStateNormal];
    [self.sendTextButton setTitleColor:WFCU_VOICE_SEND_DISABLED_TEXT forState:UIControlStateDisabled];
    self.sendTextButton.titleLabel.font = [UIFont systemFontOfSize:19];
    self.sendTextButton.layer.cornerRadius = 37;
    self.sendTextButton.layer.masksToBounds = YES;
    self.sendTextButton.enabled = NO;
    [self.sendTextButton addTarget:self action:@selector(onEditSendTextClick) forControlEvents:UIControlEventTouchUpInside];
    [self.editActionsLayout addSubview:self.sendTextButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bounds.size.width <= 0 || self.bounds.size.height <= 0) return;

    self.stageLeft = 0;
    self.stageWidth = self.bounds.size.width;

    CGFloat buttonTop = self.recordButtonFrame.origin.y;
    CGFloat arcTop = MIN(self.bounds.size.height - 110, buttonTop - 16);
    [self.bottomView setStageLeft:self.stageLeft right:self.stageLeft + self.stageWidth arcTop:arcTop];

    self.backgroundView.stageLeft = self.stageLeft;
    self.backgroundView.stageRight = self.stageLeft + self.stageWidth;
    if (!self.editing) {
        self.backgroundView.panelTop = [self.bottomView pillTop] + 18;
    }

    self.bubbleBottomMargin = self.bounds.size.height - MAX(160.0, [self.bottomView pillTop] - 141.0);
    self.editActionsBottomMargin = MAX(16.0, self.bounds.size.height - arcTop - 20.0);

    self.countDownLabel.frame = CGRectMake(self.stageLeft, self.bubbleBottomMargin - 44, self.stageWidth, 24);

    CGFloat actionRowY = self.bounds.size.height - self.editActionsBottomMargin - 96 - self.keyboardOffset;
    self.editActionsLayout.frame = CGRectMake(self.stageLeft + 16, actionRowY, self.stageWidth - 40, 96);
    self.cancelLayout.frame = CGRectMake(0, 0, 96, 96);
    self.sendVoiceLayout.frame = CGRectMake(106, 0, 96, 96);
    self.sendTextButton.frame = CGRectMake(self.editActionsLayout.bounds.size.width - 124, 0, 124, 74);

    if (!self.layoutReady) {
        self.layoutReady = YES;
        WFCUBubbleFrame frame;
        [self computeBubbleFrameForState:self.bubbleState frame:&frame];
        [self applyBubbleFrame:&frame toFrame:&frame fraction:1.0];
    }
}

#pragma mark - Hit Test & Touch Handling

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.editing) {
        return nil; // 非编辑模式下，让触摸事件穿透给底部的按住说话按钮
    }
    if (self.hidden || self.alpha < 0.01) {
        return nil;
    }
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView) {
        return hitView;
    }
    // 编辑模式下拦截全屏所有触摸，避免穿透到底部的消息列表 TableView 触发长按上下文菜单
    if (CGRectContainsPoint(self.bounds, point)) {
        return self;
    }
    return nil;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.editing) {
        [self endEditing:YES];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

#pragma mark - 7. 对外 API 接口

- (void)show {
    self.bottomView.speechToTextEnabled = self.speechToTextEnabled;
    [self layoutIfNeeded];

    self.backgroundView.progress = 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundView.progress = 1.0;
    }];

    [self.bottomView showWithDuration:0.34];
    [self.waveView startAnimation];

    // 气泡弹起
    self.bubbleView.alpha = 0;
    self.bubbleView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.6, 0.6), CGAffineTransformMakeTranslation(0, 24));

    [UIView animateWithDuration:0.34 delay:0.04 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
        self.bubbleView.alpha = 1;
        self.bubbleView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss {
    [self.waveView stopAnimation];
    [self.bottomView hideWithDuration:0.22 completion:nil];

    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundView.progress = 0;
        self.bubbleView.alpha = 0;
        self.editActionsLayout.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)updateZoneWithPoint:(CGPoint)point {
    if (self.editing || !self.layoutReady) return;

    WFCUVoiceInputZone zone = [self.bottomView zoneAtPoint:point];
    if (zone == self.zone) return;

    self.zone = zone;
    [self.bottomView setZone:zone];
    // 滑到"转文字"时 WFCUChatInputBar 靠这个回调开始实时识别
    if ([self.delegate respondsToSelector:@selector(voiceInputView:didChangeZone:)]) {
        [self.delegate voiceInputView:self didChangeZone:zone];
    }

    // iOS 震动反馈
    AudioServicesPlaySystemSound(1519); // Peek feedback

    if (zone == WFCUVoiceInputZoneCancel) {
        [self animateBubbleToState:WFCUBubbleStateCancel];
    } else if (zone == WFCUVoiceInputZoneText) {
        [self animateBubbleToState:WFCUBubbleStateText];
    } else {
        [self animateBubbleToState:WFCUBubbleStateSend];
    }
}

- (void)setVoiceLevel:(CGFloat)level {
    if (self.bubbleState == WFCUBubbleStateSend || self.bubbleState == WFCUBubbleStateCancel || self.bubbleState == WFCUBubbleStateText) {
        [self.waveView setLevel:level];
    }
}

- (void)setRecognizedText:(NSString *)text {
    if (!text) text = @"";
    if (![self.textEditText.text isEqualToString:text]) {
        self.textEditText.text = text;
        if (self.bubbleState == WFCUBubbleStateText || self.bubbleState == WFCUBubbleStateEdit) {
            [self animateBubbleToState:self.bubbleState];
        }
        [self scrollEditTextToBottom];
    }
}

/**
 * 气泡到高度上限后文字在内部滚动，识别追加的文字默认滚到底部保持可见
 */
- (void)scrollEditTextToBottom {
    if (!self.textEditText.text.length) return;
    [self.textEditText layoutIfNeeded];
    [self.textEditText scrollRangeToVisible:NSMakeRange(self.textEditText.text.length - 1, 1)];
}

- (void)showTooShortTip {
    self.hintLabel.text = WFCString(@"RecordingTooShort");
    self.hintLabel.textColor = WFCUContentColorForPrimaryColor(WFCUAppPrimaryColor());
    [self animateBubbleToState:WFCUBubbleStateTooShort];

    // 震动动画
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    shake.duration = 0.42;
    shake.values = @[ @(0), @(-10), @(10), @(-7), @(7), @(-3), @(3), @(0) ];
    [self.bubbleView.layer addAnimation:shake forKey:@"shake"];
}

- (void)enterEditing:(NSString *)text {
    if (self.editing) return;
    self.userInteractionEnabled = YES; // 关键：进入编辑状态后允许接收事件
    self.editing = YES;
    self.userEditedText = NO;
    self.asrFinished = NO;

    if (text) self.textEditText.text = text;

    [self.countDownLabel setHidden:YES];
    [self.bottomView hideWithDuration:0.2 completion:nil];

    // 深灰背景升到气泡下方，与 Android 一致
    [self.backgroundView animatePanelTop:[self editPanelTop] duration:0.36];

    self.editActionsLayout.hidden = NO;
    self.editActionsLayout.alpha = 0;
    self.editActionsLayout.transform = CGAffineTransformMakeTranslation(0, 28);
    [UIView animateWithDuration:0.3 delay:0.14 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.editActionsLayout.alpha = 1.0;
        self.editActionsLayout.transform = CGAffineTransformIdentity;
    } completion:nil];

    self.textEditText.userInteractionEnabled = YES;
    self.textEditText.editable = YES;
//    [self.textEditText becomeFirstResponder];

    self.waveView.loading = YES;
    [self animateBubbleToState:WFCUBubbleStateEdit];
    [self scrollEditTextToBottom];
    [self updateSendTextButtonState];
}

- (void)updateEditingText:(NSString *)text finished:(BOOL)finished {
    self.asrFinished = finished;
    if (finished) {
        self.waveView.loading = NO;
    }
    if (!self.userEditedText && text) {
        self.textEditText.text = text;
        [self animateBubbleToState:WFCUBubbleStateEdit];
        [self scrollEditTextToBottom];
    }
    [self updateSendTextButtonState];
}

- (NSString *)editingText {
    return self.textEditText.text ?: @"";
}

/**
 * 发送按钮的可用状态，和 Android 的 updateEditActions 一致：
 * 识别结束、并且去掉首尾空白后还有文字时才能发送
 */
- (void)updateSendTextButtonState {
    NSString *text = [self.textEditText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.sendTextButton.enabled = self.asrFinished && text.length > 0;
}

#pragma mark - 8. 气泡 Frame 计算与 Morphing 动画

- (void)animateBubbleToState:(WFCUBubbleState)state {
    BOOL changed = self.bubbleState != state;
    self.bubbleState = state;
    if (!self.layoutReady) return;

    WFCUBubbleFrame from = self.currentBubbleFrame;
    WFCUBubbleFrame to;
    [self computeBubbleFrameForState:state frame:&to];

    self.fromBubbleFrame = from;
    self.toBubbleFrame = to;
    self.bubbleAnimStartTime = CACurrentMediaTime();
    self.bubbleAnimDuration = changed ? 0.32 : 0.18;

    if (!self.bubbleAnimDisplayLink) {
        self.bubbleAnimDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onBubbleAnimTick:)];
        [self.bubbleAnimDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.bubbleAnimDisplayLink.paused = NO;
}

- (void)onBubbleAnimTick:(CADisplayLink *)link {
    CFTimeInterval now = CACurrentMediaTime();
    CGFloat elapsed = now - self.bubbleAnimStartTime;
    CGFloat duration = self.bubbleAnimDuration > 0 ? self.bubbleAnimDuration : 0.32;
    CGFloat progress = MIN(1.0, elapsed / duration);
    // Cubic bezier ease-out
    CGFloat t = 1.0 - pow(1.0 - progress, 3.0);

    const WFCUBubbleFrame fromFrame = _fromBubbleFrame;
    const WFCUBubbleFrame toFrame = _toBubbleFrame;
    [self applyBubbleFrame:&fromFrame toFrame:&toFrame fraction:t];

    if (progress >= 1.0) {
        self.bubbleAnimDisplayLink.paused = YES;
    }
}

- (void)computeBubbleFrameForState:(WFCUBubbleState)state frame:(WFCUBubbleFrame *)frame {
    CGFloat tailHeight = self.bubbleView.tailHeight;
    CGFloat maxWidth = self.stageWidth - 32.0;
    CGFloat sendWidth = MIN(maxWidth, MAX(160.0, self.stageWidth * 0.475));
    CGFloat tailTargetX = 0;

    UIColor *primaryColor = WFCUAppPrimaryColor();
    UIColor *contentColor = WFCUContentColorForPrimaryColor(primaryColor);

    frame->waveAlpha = 1.0;
    frame->textAlpha = 0.0;
    frame->hintAlpha = 0.0;
    frame->textBottomMargin = 20.0;
    WFCUSetFrameColor(frame, primaryColor, NO);
    WFCUSetFrameColor(frame, contentColor, YES);

    switch (state) {
        case WFCUBubbleStateCancel:
            frame->width = 78.0;
            frame->height = 78.0 + tailHeight;
            tailTargetX = [self.bottomView cancelCenterX];
            frame->left = MAX(self.stageLeft + 16.0, tailTargetX - frame->width / 2.0);
            WFCUSetFrameColor(frame, WFCU_VOICE_RED_COLOR, NO);
            WFCUSetFrameColor(frame, [UIColor whiteColor], YES);
            frame->waveWidth = 34.0;
            frame->waveHeight = 16.0;
            frame->waveCenterX = frame->width / 2.0;
            frame->waveCenterY = (frame->height - tailHeight) / 2.0;
            break;

        case WFCUBubbleStateText:
        case WFCUBubbleStateEdit:
        case WFCUBubbleStateNoText: {
            BOOL noText = (state == WFCUBubbleStateNoText);
            BOOL showWave = (state == WFCUBubbleStateText) || (state == WFCUBubbleStateEdit && !self.asrFinished);

            frame->left = self.stageLeft + 16.0;
            frame->width = maxWidth;
            frame->textBottomMargin = showWave ? 20.0 : 0.0;
            frame->height = [self measureBubbleHeightForWidth:frame->width textBottomMargin:frame->textBottomMargin];
            // 高度不能超出可用空间，否则超长文字会把气泡顶出屏幕上沿；
            // 到上限后由 UITextView 在气泡内部滚动
            CGFloat bubbleBottomY = self.bounds.size.height - [self currentBubbleBottomMargin] - self.keyboardOffset;
            CGFloat maxHeight = bubbleBottomY - [self bubbleTopMargin];
            if (maxHeight > 0) {
                frame->height = MIN(frame->height, maxHeight);
            }
            WFCUSetFrameColor(frame, noText ? WFCU_VOICE_RED_COLOR : primaryColor, NO);
            WFCUSetFrameColor(frame, noText ? [UIColor whiteColor] : contentColor, YES);
            frame->waveWidth = 34.0;
            frame->waveHeight = 16.0;
            frame->waveCenterX = frame->width - 20.0 - frame->waveWidth / 2.0;
            frame->waveCenterY = frame->height - tailHeight - 18.0;
            frame->waveAlpha = showWave ? 1.0 : 0.0;
            frame->textAlpha = noText ? 0.0 : 1.0;
            frame->hintAlpha = noText ? 1.0 : 0.0;
            tailTargetX = self.stageLeft + self.stageWidth * 0.755;
            break;
        }

        case WFCUBubbleStateTooShort:
            frame->width = MIN(maxWidth, MAX(sendWidth, [self measureHintWidthForMaxWidth:maxWidth]));
            frame->height = 78.0 + tailHeight;
            frame->left = self.stageLeft + (self.stageWidth - frame->width) / 2.0;
            frame->waveWidth = sendWidth * 0.46;
            frame->waveHeight = 20.0;
            frame->waveCenterX = frame->width / 2.0;
            frame->waveCenterY = (frame->height - tailHeight) / 2.0;
            frame->waveAlpha = 0.0;
            frame->hintAlpha = 1.0;
            tailTargetX = frame->left + frame->width / 2.0;
            break;

        default: // WFCUBubbleStateSend
            frame->width = sendWidth;
            frame->height = 78.0 + tailHeight;
            frame->left = self.stageLeft + (self.stageWidth - frame->width) / 2.0;
            frame->waveWidth = frame->width * 0.46;
            frame->waveHeight = 20.0;
            frame->waveCenterX = frame->width / 2.0;
            frame->waveCenterY = (frame->height - tailHeight) / 2.0;
            tailTargetX = frame->left + frame->width / 2.0;
            break;
    }

    frame->tailX = tailTargetX - frame->left;
}

- (CGFloat)measureBubbleHeightForWidth:(CGFloat)width textBottomMargin:(CGFloat)bottomMargin {
    CGFloat textWidth = width - 40.0; // 20pt padding each side
    CGSize size = [self.textEditText sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGFloat textHeight = MAX(30.0, size.height);
    return textHeight + 36.0 + bottomMargin + self.bubbleView.tailHeight;
}

- (CGFloat)measureHintWidthForMaxWidth:(CGFloat)maxWidth {
    CGSize size = [self.hintLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    return size.width + 40.0;
}

- (void)applyBubbleFrame:(const WFCUBubbleFrame *)from toFrame:(const WFCUBubbleFrame *)to fraction:(CGFloat)f {
    WFCUBubbleFrame cur = {0};
    cur.left = from->left + (to->left - from->left) * f;
    cur.width = from->width + (to->width - from->width) * f;
    cur.height = from->height + (to->height - from->height) * f;
    cur.tailX = from->tailX + (to->tailX - from->tailX) * f;
    cur.waveWidth = from->waveWidth + (to->waveWidth - from->waveWidth) * f;
    cur.waveHeight = from->waveHeight + (to->waveHeight - from->waveHeight) * f;
    cur.waveCenterX = from->waveCenterX + (to->waveCenterX - from->waveCenterX) * f;
    cur.waveCenterY = from->waveCenterY + (to->waveCenterY - from->waveCenterY) * f;
    cur.waveAlpha = from->waveAlpha + (to->waveAlpha - from->waveAlpha) * f;
    cur.textAlpha = from->textAlpha + (to->textAlpha - from->textAlpha) * f;
    cur.hintAlpha = from->hintAlpha + (to->hintAlpha - from->hintAlpha) * f;
    cur.textBottomMargin = from->textBottomMargin + (to->textBottomMargin - from->textBottomMargin) * f;

    cur.r = from->r + (to->r - from->r) * f;
    cur.g = from->g + (to->g - from->g) * f;
    cur.b = from->b + (to->b - from->b) * f;
    cur.a = from->a + (to->a - from->a) * f;

    cur.waveR = from->waveR + (to->waveR - from->waveR) * f;
    cur.waveG = from->waveG + (to->waveG - from->waveG) * f;
    cur.waveB = from->waveB + (to->waveB - from->waveB) * f;
    cur.waveA = from->waveA + (to->waveA - from->waveA) * f;

    self.currentBubbleFrame = cur;

    CGFloat bottomY = self.bounds.size.height - [self currentBubbleBottomMargin] - self.keyboardOffset;
    self.bubbleView.frame = CGRectMake(cur.left, bottomY - cur.height, cur.width, cur.height);
    self.bubbleView.bubbleColor = [UIColor colorWithRed:cur.r green:cur.g blue:cur.b alpha:cur.a];
    self.bubbleView.tailX = cur.tailX;

    self.waveView.frame = CGRectMake(cur.waveCenterX - cur.waveWidth / 2.0, cur.waveCenterY - cur.waveHeight / 2.0, cur.waveWidth, cur.waveHeight);
    self.waveView.barColor = [UIColor colorWithRed:cur.waveR green:cur.waveG blue:cur.waveB alpha:cur.waveA];
    self.waveView.alpha = cur.waveAlpha;

    CGFloat textWidth = cur.width - 40.0;
    self.textEditText.frame = CGRectMake(20.0, 18.0, textWidth, cur.height - self.bubbleView.tailHeight - 18.0 - cur.textBottomMargin);
    // 文字/光标的可见性只由 textAlpha 控制：识别结束后声波隐藏（waveAlpha=0），
    // 但文字仍要显示，所以这里颜色 alpha 固定为 1，不能用 waveA
    self.textEditText.alpha = cur.textAlpha;
    self.textEditText.textColor = [UIColor colorWithRed:cur.waveR green:cur.waveG blue:cur.waveB alpha:1.0];
    self.textEditText.tintColor = [UIColor colorWithRed:cur.waveR green:cur.waveG blue:cur.waveB alpha:1.0];

    self.hintLabel.frame = CGRectMake(20.0, 18.0, textWidth, cur.height - self.bubbleView.tailHeight - 36.0);
    self.hintLabel.alpha = cur.hintAlpha;
}

#pragma mark - 9. UITextViewDelegate & 按钮事件

- (void)textViewDidChange:(UITextView *)textView {
    self.userEditedText = YES;
    if (self.bubbleState == WFCUBubbleStateEdit) {
        [self animateBubbleToState:WFCUBubbleStateEdit];
    }
    // 删空文字后发送按钮要置灰，不能一直留着一个浅色方块
    [self updateSendTextButtonState];
}

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
    NSString *text = [self.textEditText.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!text.length) return;
    if ([self.delegate respondsToSelector:@selector(voiceInputView:didSendText:)]) {
        [self.delegate voiceInputView:self didSendText:text];
    }
}

#pragma mark - 10. 键盘 Notification

/**
 * 气泡底部到屏幕底部的距离。
 * 录音态要避开底部的弧形按钮区；编辑态贴在底部按钮组上方 20pt，
 * 否则文字超长时气泡只向上长，气泡和按钮之间会留出一大块空白
 */
- (CGFloat)currentBubbleBottomMargin {
    if (self.editing) {
        return self.editActionsBottomMargin + 96.0 + 20.0;
    }
    return self.bubbleBottomMargin;
}

/**
 * 气泡顶部到屏幕上沿的最小留白
 */
- (CGFloat)bubbleTopMargin {
    CGFloat topMargin = 12.0;
    if (@available(iOS 11.0, *)) {
        topMargin += self.safeAreaInsets.top;
    }
    return topMargin;
}

/**
 * 编辑文字时深灰背景完全不透明处，在气泡下边缘稍上方
 */
- (CGFloat)editPanelTop {
    return self.bounds.size.height - self.keyboardOffset - [self currentBubbleBottomMargin] - self.bubbleView.tailHeight - 5.0;
}

- (void)keyboardWillChangeFrame:(NSNotification *)note {
    if (!self.editing) return;

    CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardInSelf = [self convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.bounds) - CGRectGetMinY(keyboardInSelf));
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    // 与 Android 一致，只把按钮顶到键盘上方 12pt，气泡和深灰背景跟着一起移动，按钮和键盘之间不露出遮罩
    self.keyboardOffset = overlap > 0 ? MAX(0, overlap - self.editActionsBottomMargin + 12.0) : 0;
    [self.backgroundView animatePanelTop:[self editPanelTop] duration:duration];

    [UIView animateWithDuration:duration animations:^{
        [self setNeedsLayout];
        [self layoutIfNeeded];

        // 可用空间随键盘变化，重新计算气泡高度（超限时收缩，文字在气泡内滚动）
        WFCUBubbleFrame frame;
        [self computeBubbleFrameForState:self.bubbleState frame:&frame];
        self.fromBubbleFrame = frame;
        self.toBubbleFrame = frame;
        self.bubbleAnimDisplayLink.paused = YES;
        [self applyBubbleFrame:&frame toFrame:&frame fraction:1.0];
    }];
}

@end
