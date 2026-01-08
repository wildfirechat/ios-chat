//
//  WFCSlideVerifyView.m
//  WildFireChat
//
//  Created by Claude on 2026-01-07.
//

#import "WFCSlideVerifyView.h"
#import "AppService.h"
#import "MBProgressHUD.h"

@interface WFCSlideVerifyView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *sliderImageView;
@property (nonatomic, strong) UIView *sliderTrackView;
@property (nonatomic, strong) UIImageView *sliderButton;
@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) NSString *token;
@property (nonatomic, assign) int sliderY;
@property (nonatomic, assign) CGFloat sliderStartX;
@property (nonatomic, assign) BOOL isVerified;

@end

@implementation WFCSlideVerifyView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        // 延迟加载验证码，确保layoutSubviews已经执行
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadVerifyCode];
        });
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;

    // 背景图容器
    self.backgroundImageView = [[UIImageView alloc] init];
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    self.backgroundImageView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
    [self addSubview:self.backgroundImageView];

    // 滑块图
    self.sliderImageView = [[UIImageView alloc] init];
    self.sliderImageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:self.sliderImageView];

    // 滑块轨道
    self.sliderTrackView = [[UIView alloc] init];
    self.sliderTrackView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    self.sliderTrackView.layer.cornerRadius = 20;
    [self addSubview:self.sliderTrackView];

    // 滑块按钮
    self.sliderButton = [[UIImageView alloc] init];
    // 使用代码生成箭头图标
    self.sliderButton.image = [self createArrowIcon];
    self.sliderButton.backgroundColor = [UIColor whiteColor];
    self.sliderButton.layer.cornerRadius = 20;
    self.sliderButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.sliderButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.sliderButton.layer.shadowOpacity = 0.2;
    self.sliderButton.layer.shadowRadius = 2;
    self.sliderButton.userInteractionEnabled = YES;
    self.sliderButton.contentMode = UIViewContentModeCenter;
    self.sliderButton.tintColor = [UIColor grayColor];
    [self.sliderTrackView addSubview:self.sliderButton];

    // 提示标签
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = @"向右滑动完成验证";
    self.hintLabel.textColor = [UIColor grayColor];
    self.hintLabel.font = [UIFont systemFontOfSize:14];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    [self.sliderTrackView addSubview:self.hintLabel];

    // 添加手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.sliderButton addGestureRecognizer:panGesture];

    // 刷新按钮
    UIButton *refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [refreshButton setImage:[UIImage systemImageNamed:@"arrow.clockwise"] forState:UIControlStateNormal];
    [refreshButton addTarget:self action:@selector(refreshVerify) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:refreshButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat padding = 10;
    CGFloat imageHeight = 150;
    CGFloat sliderTrackHeight = 40;

    // 背景图
    self.backgroundImageView.frame = CGRectMake(padding, padding, self.bounds.size.width - 2 * padding, imageHeight);

    // 滑块轨道
    self.sliderTrackView.frame = CGRectMake(padding, imageHeight + padding + 10, self.bounds.size.width - 2 * padding, sliderTrackHeight);

    // 滑块按钮
    self.sliderButton.frame = CGRectMake(0, 0, sliderTrackHeight, sliderTrackHeight);

    // 提示标签
    self.hintLabel.frame = self.sliderTrackView.bounds;

    // 刷新按钮
    UIButton *refreshButton = self.subviews.lastObject;
    refreshButton.frame = CGRectMake(self.bounds.size.width - 40, self.bounds.size.height - 40, 30, 30);
}

- (void)loadVerifyCode {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    hud.label.text = @"加载中...";
    // 设置背景色为透明，避免白色方块闪烁
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];

    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] getSlideVerify:^(NSDictionary *result) {
        [hud hideAnimated:YES];

        NSLog(@"滑动验证码返回数据: %@", result);

        if (result && result[@"token"] && result[@"backgroundImage"] && result[@"sliderImage"]) {
            weakSelf.token = result[@"token"];
            weakSelf.sliderY = [result[@"y"] intValue];

            NSLog(@"Token: %@", weakSelf.token);
            NSLog(@"SliderY: %d", weakSelf.sliderY);
            NSLog(@"BackgroundImage length: %lu", (unsigned long)[result[@"backgroundImage"] length]);
            NSLog(@"SliderImage length: %lu", (unsigned long)[result[@"sliderImage"] length]);

            // 设置图片
            [weakSelf setBackgroundImageFromBase64:result[@"backgroundImage"]];
            [weakSelf setSliderImageFromBase64:result[@"sliderImage"]];

            weakSelf.isVerified = NO;
            [weakSelf reset];
        } else {
            NSLog(@"验证码数据不完整或为空");

            // 通知代理加载失败，需要关闭窗口
            if ([weakSelf.delegate respondsToSelector:@selector(slideVerifyViewDidLoadFailed)]) {
                [weakSelf.delegate slideVerifyViewDidLoadFailed];
            }
        }
    } error:^(NSString *message) {
        [hud hideAnimated:YES];
        NSLog(@"加载验证码失败: %@", message);

        // 通知代理加载失败，需要关闭窗口
        if ([weakSelf.delegate respondsToSelector:@selector(slideVerifyViewDidLoadFailed)]) {
            [weakSelf.delegate slideVerifyViewDidLoadFailed];
        }
    }];
}

- (void)setBackgroundImageFromBase64:(NSString *)base64String {
    NSLog(@"开始解析背景图，数据长度: %lu", (unsigned long)base64String.length);

    // 去除 data URI 前缀，提取纯 base64 数据
    if ([base64String hasPrefix:@"data:image/png;base64,"]) {
        base64String = [base64String substringFromIndex:22];
    }

    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSLog(@"解码后数据长度: %lu", (unsigned long)imageData.length);

    UIImage *image = [UIImage imageWithData:imageData];

    if (image) {
        self.backgroundImageView.image = image;
        NSLog(@"背景图设置成功，尺寸: %@, backgroundImageView frame: %@", NSStringFromCGSize(image.size), NSStringFromCGRect(self.backgroundImageView.frame));
    } else {
        NSLog(@"背景图解析失败");
    }
}

- (void)setSliderImageFromBase64:(NSString *)base64String {
    NSLog(@"开始解析滑块图片，数据长度: %lu", (unsigned long)base64String.length);

    // 去除 data URI 前缀，提取纯 base64 数据
    if ([base64String hasPrefix:@"data:image/png;base64,"]) {
        base64String = [base64String substringFromIndex:22];
    }

    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSLog(@"解码后数据长度: %lu", (unsigned long)imageData.length);

    UIImage *image = [UIImage imageWithData:imageData];

    if (image) {
        self.sliderImageView.image = image;
        NSLog(@"滑块图片设置成功，尺寸: %@", NSStringFromCGSize(image.size));
    } else {
        NSLog(@"滑块图片解析失败");
    }

    // 强制布局以确保frame正确
    [self setNeedsLayout];
    [self layoutIfNeeded];

    // 分别计算宽度和高度的缩放比例
    // 背景图原始尺寸：300 x 150
    CGFloat scaleX = CGRectGetWidth(self.backgroundImageView.frame) / 300.0;
    CGFloat scaleY = CGRectGetHeight(self.backgroundImageView.frame) / 150.0;

    // 使用对应的缩放比例计算滑块尺寸
    CGFloat sliderWidth = 50 * scaleX;
    CGFloat sliderHeight = 50 * scaleY;
    CGFloat sliderX = CGRectGetMinX(self.sliderTrackView.frame); // 初始位置在轨道左侧
    CGFloat backgroundY = CGRectGetMinY(self.backgroundImageView.frame); // 背景图的Y坐标

    // 滑块图片的Y坐标 = 背景图的Y + (原图中的Y坐标 * 高度缩放比例)
    CGFloat sliderY = backgroundY + (self.sliderY * scaleY);

    self.sliderImageView.frame = CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);

    NSLog(@"滑块图片 frame: %@", NSStringFromCGRect(self.sliderImageView.frame));
    NSLog(@"背景图 frame: %@", NSStringFromCGRect(self.backgroundImageView.frame));
    NSLog(@"计算: sliderY=%d, scaleX=%.3f, scaleY=%.3f, backgroundY=%.2f, 最终Y=%.2f", self.sliderY, scaleX, scaleY, backgroundY, sliderY);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    if (self.isVerified) {
        return;
    }

    CGPoint translation = [gesture translationInView:self.sliderTrackView];
    CGPoint location = [gesture locationInView:self.sliderTrackView];

    CGFloat maxDistance = CGRectGetWidth(self.sliderTrackView.frame) - CGRectGetWidth(self.sliderButton.frame);

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.sliderStartX = CGRectGetMinX(self.sliderButton.frame);
            break;

        case UIGestureRecognizerStateChanged: {
            CGFloat newX = self.sliderStartX + translation.x;
            newX = MAX(0, MIN(newX, maxDistance));

            CGRect frame = self.sliderButton.frame;
            frame.origin.x = newX;
            self.sliderButton.frame = frame;

            // 同时移动滑块图片
            CGRect sliderFrame = self.sliderImageView.frame;
            sliderFrame.origin.x = CGRectGetMinX(self.backgroundImageView.frame) + newX;
            self.sliderImageView.frame = sliderFrame;

            self.hintLabel.alpha = 1 - (newX / maxDistance);
            break;
        }

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            CGFloat newX = CGRectGetMinX(self.sliderButton.frame);

            // 只要滑动超过 10px 就验证
            if (newX < 10) {
                // 滑动距离不够，回弹
                [self reset];
            } else {
                // 滑动完成，提交验证
                [self verifySlidePosition:(int)newX];
            }
            break;
        }

        default:
            break;
    }
}

- (void)verifySlidePosition:(int)x {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self animated:YES];
    // 设置背景色为透明，避免白色方块闪烁
    hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];

    // 分别计算宽度和高度的缩放比例
    CGFloat scaleX = CGRectGetWidth(self.backgroundImageView.frame) / 300.0;

    // 将屏幕坐标转换为原图坐标（300像素宽）
    int originalX = (int)(x / scaleX);

    NSLog(@"验证滑动: 屏幕X=%d, scaleX=%.3f, 原图X=%d", x, scaleX, originalX);

    __weak typeof(self) weakSelf = self;
    [[AppService sharedAppService] verifySlide:self.token x:originalX success:^{
        [hud hideAnimated:YES];
        weakSelf.isVerified = YES;
        weakSelf.hintLabel.text = @"验证通过";
        weakSelf.hintLabel.textColor = [UIColor greenColor];
        weakSelf.sliderButton.backgroundColor = [UIColor greenColor];

        if ([weakSelf.delegate respondsToSelector:@selector(slideVerifyViewDidVerifySuccess:)]) {
            [weakSelf.delegate slideVerifyViewDidVerifySuccess:weakSelf.token];
        }
    } error:^(NSString *message) {
        [hud hideAnimated:YES];
        [weakSelf reset];

        // 验证失败后，自动刷新验证码
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf refreshVerify];
        });

        if ([weakSelf.delegate respondsToSelector:@selector(slideVerifyViewDidVerifyFailed)]) {
            [weakSelf.delegate slideVerifyViewDidVerifyFailed];
        }
    }];
}

- (void)reset {
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.sliderButton.frame;
        frame.origin.x = 0;
        self.sliderButton.frame = frame;

        CGRect sliderFrame = self.sliderImageView.frame;
        sliderFrame.origin.x = CGRectGetMinX(self.backgroundImageView.frame);
        self.sliderImageView.frame = sliderFrame;

        self.hintLabel.alpha = 1.0;
        self.hintLabel.text = @"向右滑动完成验证";
        self.hintLabel.textColor = [UIColor grayColor];
        self.sliderButton.backgroundColor = [UIColor whiteColor];
    }];
}

- (void)refreshVerify {
    [self loadVerifyCode];
}

// 创建箭头图标
- (UIImage *)createArrowIcon {
    CGSize size = CGSizeMake(40, 40);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // 绘制箭头
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 2.0);

    // 箭头主线
    CGContextMoveToPoint(context, 15, 20);
    CGContextAddLineToPoint(context, 25, 20);

    // 箭头头部
    CGContextMoveToPoint(context, 20, 15);
    CGContextAddLineToPoint(context, 25, 20);
    CGContextAddLineToPoint(context, 20, 25);

    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
