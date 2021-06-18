
#import "HWCircleView.h"

@implementation HWCircleView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
 
    return self;
}
 
- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
}
 
- (void)drawRect:(CGRect)rect {
    int lineWidth = 3;
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineWidth = lineWidth;
    [[UIColor greenColor] set];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    CGFloat radius = (MIN(rect.size.width, rect.size.height) - lineWidth - 20) * 0.5;
    [path addArcWithCenter:(CGPoint){rect.size.width * 0.5, rect.size.height * 0.5} radius:radius startAngle:M_PI * 1.5 endAngle:M_PI * 1.5 + M_PI * 2 * _progress clockwise:YES];
    [path stroke];
}
@end
