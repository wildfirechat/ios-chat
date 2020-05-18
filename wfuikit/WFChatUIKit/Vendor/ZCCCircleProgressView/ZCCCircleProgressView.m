//
//  ZCCCircleProgressView.m
//  MOSOBOStudent
//
//  Created by mac on 2017/10/23.
//  Copyright © 2017年 zcc. All rights reserved.
//

#import "ZCCCircleProgressView.h"

@interface ZCCCircleProgressView()
@property (nonatomic, strong)CAGradientLayer *gradientLayer;
//进度圆环
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAShapeLayer *shapeLayer2;

@property (nonatomic, strong)NSTimer *timer;

@end

@implementation ZCCCircleProgressView

- (instancetype)initWithFrame:(CGRect)frame{
    
    if(self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor whiteColor];
        self.lineWidth = frame.size.width/8;
        [self addCircleWithColor:[UIColor purpleColor]];
    }
    return self;
}


- (void)addCircleWithColor:(UIColor *)color{
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width / 2, height / 2) radius:(width - self.lineWidth)/2 startAngle:M_PI / 2+0.01 endAngle:M_PI / 2 clockwise:YES];
    UIBezierPath *circlePath2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(width / 2, height / 2) radius:(width - 4 * self.lineWidth)/2 startAngle:M_PI / 2+0.01 endAngle:M_PI / 2 clockwise:YES];
    
    CAShapeLayer *bgLayer = [CAShapeLayer layer];
    bgLayer.frame = self.bounds;
    bgLayer.fillColor = [UIColor clearColor].CGColor;
    bgLayer.lineWidth = self.lineWidth;
    bgLayer.strokeColor = SDColor(212, 212, 212, 1.0).CGColor;
    bgLayer.strokeStart = 0;
    bgLayer.strokeEnd = 1;
    bgLayer.lineCap = kCALineCapRound;
    bgLayer.path = circlePath.CGPath;
    [self.layer addSublayer:bgLayer];
    
    CAShapeLayer *bgLayer2 = [CAShapeLayer layer];
    bgLayer2.frame = self.bounds;
    bgLayer2.fillColor = [UIColor clearColor].CGColor;
    bgLayer2.lineWidth = self.lineWidth;
    bgLayer2.strokeColor = SDColor(212, 212, 212, 1.0).CGColor;
    bgLayer2.strokeStart = 0;
    bgLayer2.strokeEnd = 1;
    bgLayer2.lineCap = kCALineCapRound;
    bgLayer2.path = circlePath2.CGPath;
    [self.layer addSublayer:bgLayer2];
    
    
    _shapeLayer = [CAShapeLayer layer];
    _shapeLayer.frame = self.bounds;
    _shapeLayer.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer.lineWidth = self.lineWidth;
    _shapeLayer.lineCap = kCALineCapRound;
    _shapeLayer.strokeColor = [UIColor blueColor].CGColor;
    _shapeLayer.strokeStart = 0;
    _shapeLayer.strokeEnd = 0;
    _shapeLayer.path = circlePath.CGPath;
    [self.layer addSublayer:_shapeLayer];
    
    _shapeLayer2 = [CAShapeLayer layer];
    _shapeLayer2.frame = self.bounds;
    _shapeLayer2.fillColor = [UIColor clearColor].CGColor;
    _shapeLayer2.lineWidth = self.lineWidth;
    _shapeLayer2.lineCap = kCALineCapRound;
    _shapeLayer2.strokeColor = [UIColor blueColor].CGColor;
    _shapeLayer2.strokeStart = 0;
    _shapeLayer2.strokeEnd = 0;
    _shapeLayer2.path = circlePath2.CGPath;
    [self.layer addSublayer:_shapeLayer2];

    self.gradientLayer = [CAGradientLayer layer];
    
    CAGradientLayer *leftGradientLayer = [CAGradientLayer layer];
    leftGradientLayer.frame = CGRectMake(0, 0, width / 2, height);
    [leftGradientLayer setColors:[NSArray arrayWithObjects:(id)SDColor(255, 255, 0, 1).CGColor, (id)SDColor(255, 255.0/2, 0, 1).CGColor, nil]];
    [leftGradientLayer setLocations:@[@0,@0.9]];
    [leftGradientLayer setStartPoint:CGPointMake(0, 1)];
    [leftGradientLayer setEndPoint:CGPointMake(1, 0)];
    [_gradientLayer addSublayer:leftGradientLayer];


    CAGradientLayer *rightGradientLayer = [CAGradientLayer layer];
    rightGradientLayer.frame = CGRectMake(width / 2, 0, width / 2, height);
    [rightGradientLayer setColors:[NSArray arrayWithObjects:(id)SDColor(255, 255.0 / 2, 0, 1.0).CGColor, (id)SDColor(255, 0, 0, 1.0).CGColor, nil]];
    [rightGradientLayer setLocations:@[@0.1, @1]];
    [rightGradientLayer setStartPoint:CGPointMake(0.5, 0)];
    [rightGradientLayer setEndPoint:CGPointMake(0.5, 1)];
    [_gradientLayer addSublayer:rightGradientLayer];
     
    [self.gradientLayer setMask:_shapeLayer];
    
    self.gradientLayer.frame = self.bounds;
    [self.layer addSublayer:self.gradientLayer];
}

- (void)animateToProgress:(CGFloat)progress subProgress:(CGFloat)subProgress {
    if(_shapeLayer.strokeEnd != 0){
        [self animateToZero];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_shapeLayer.strokeEnd * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf deleteTimer];
        NSDictionary *userInfo = @{@"progressStr":@(progress),@"subProgress":@(subProgress)};
        
        weakSelf.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:weakSelf selector:@selector(animate:) userInfo:userInfo repeats:YES];
    });
    
}

- (void)animate:(NSTimer *)time {
    CGFloat progress = [[time.userInfo objectForKey:@"progressStr"]  floatValue];
    CGFloat subProgress = [[time.userInfo objectForKey:@"subProgress"] floatValue];
    
    if(_shapeLayer.strokeEnd <= progress || _shapeLayer2.strokeEnd <= subProgress) {
        if(_shapeLayer.strokeEnd <= progress) {
            _shapeLayer.strokeEnd += 0.01;
        }
        
        if(_shapeLayer2.strokeEnd <= subProgress) {
            _shapeLayer2.strokeEnd += 0.01;
        }
    } else {
        [self deleteTimer];
    }
}

- (void)animateToZero{
    [self deleteTimer];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(animateReset) userInfo:nil repeats:YES];
}

- (void)animateReset{
    if(_shapeLayer.strokeEnd > 0 || _shapeLayer2.strokeEnd > 0){
        if(_shapeLayer.strokeEnd > 0) {
            _shapeLayer.strokeEnd -= 0.01;
        }
        
        if(_shapeLayer2.strokeEnd > 0) {
            _shapeLayer2.strokeEnd -= 0.01;
        }
    }else{
        [self deleteTimer];
    }
}

- (void)setProgress:(CGFloat)progress subProgress:(CGFloat)subProgress {
    _shapeLayer.strokeEnd = progress;
    _shapeLayer2.strokeEnd = subProgress;
}

- (void)reset {
    _shapeLayer.strokeEnd = 0;
    _shapeLayer2.strokeEnd = 0;
}

- (void)deleteTimer{
    [self.timer invalidate];
    self.timer = nil;
}

@end
