//
//  XLPageViewControllerUtil.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/8.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController

#import "XLPageViewControllerUtil.h"

@implementation XLPageViewControllerUtil

+ (CGFloat)widthForText:(NSString *)text font:(UIFont *)font size:(CGSize)size {
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin |
    NSStringDrawingUsesFontLeading;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *attributes = @{
                                 NSFontAttributeName : font,
                                 NSParagraphStyleAttributeName : style
                                 };
    CGSize textSize = [text boundingRectWithSize:size
                                          options:opts
                                       attributes:attributes
                                          context:nil].size;
    return textSize.width;
}

+ (UIColor *)colorTransformFrom:(UIColor*)fromColor to:(UIColor *)toColor progress:(CGFloat)progress {

    if (!fromColor || !toColor) {
        NSLog(@"Warning !!! color is nil");
        return [UIColor blackColor];
    }

    progress = progress >= 1 ? 1 : progress;

    progress = progress <= 0 ? 0 : progress;
    
    const CGFloat * fromeComponents = CGColorGetComponents(fromColor.CGColor);
    
    const CGFloat * toComponents = CGColorGetComponents(toColor.CGColor);
    
    size_t  fromColorNumber = CGColorGetNumberOfComponents(fromColor.CGColor);
    size_t  toColorNumber = CGColorGetNumberOfComponents(toColor.CGColor);
    
    if (fromColorNumber == 2) {
        CGFloat white = fromeComponents[0];
        fromColor = [UIColor colorWithRed:white green:white blue:white alpha:1];
        fromeComponents = CGColorGetComponents(fromColor.CGColor);
    }
    
    if (toColorNumber == 2) {
        CGFloat white = toComponents[0];
        toColor = [UIColor colorWithRed:white green:white blue:white alpha:1];
        toComponents = CGColorGetComponents(toColor.CGColor);
    }
    
    CGFloat red = fromeComponents[0]*(1 - progress) + toComponents[0]*progress;
    CGFloat green = fromeComponents[1]*(1 - progress) + toComponents[1]*progress;
    CGFloat blue = fromeComponents[2]*(1 - progress) + toComponents[2]*progress;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1];
}

+ (void)showAnimationToShadow:(UIView *)shadow shadowWidth:(CGFloat)shadowWidth fromItemRect:(CGRect)fromItemRect toItemRect:(CGRect)toItemRect type:(XLPageShadowLineAnimationType)type progress:(CGFloat)progress {
    
    //没有动画，跳过
    if (type == XLPageShadowLineAnimationTypeNone) {
        return;
    }
    
    //平移动画
    if (type == XLPageShadowLineAnimationTypePan) {
        CGFloat distance = CGRectGetMidX(toItemRect) - CGRectGetMidX(fromItemRect);
        CGFloat centerX = CGRectGetMidX(fromItemRect) + fabs(progress)*distance;
        shadow.center = CGPointMake(centerX, shadow.center.y);
    }
    
    //缩放动画
    if (type == XLPageShadowLineAnimationTypeZoom) {
        CGFloat distance = fabs(CGRectGetMidX(toItemRect) - CGRectGetMidX(fromItemRect));
        CGFloat fromX = CGRectGetMidX(fromItemRect) - shadowWidth/2.0f;
        CGFloat toX = CGRectGetMidX(toItemRect) - shadowWidth/2.0f;
        if (progress > 0) {//向右移动
            //前半段0~0.5，x不变 w变大
            if (progress <= 0.5) {
                //让过程变成0~1
                CGFloat newProgress = 2*fabs(progress);
                CGFloat newWidth = shadowWidth + newProgress*distance;
                CGRect shadowFrame = shadow.frame;
                shadowFrame.size.width = newWidth;
                shadowFrame.origin.x = fromX;
                shadow.frame = shadowFrame;
            }else if (progress >= 0.5) { //后半段0.5~1，x变大 w变小
                //让过程变成1~0
                CGFloat newProgress = 2*(1-fabs(progress));
                CGFloat newWidth = shadowWidth + newProgress*distance;
                CGFloat newX = toX - newProgress*distance;
                CGRect shadowFrame = shadow.frame;
                shadowFrame.size.width = newWidth;
                shadowFrame.origin.x = newX;
                shadow.frame = shadowFrame;
            }
        }else {//向左移动
            //前半段0~-0.5，x变小 w变大
            if (progress >= -0.5) {
                //让过程变成0~1
                CGFloat newProgress = 2*fabs(progress);
                CGFloat newWidth = shadowWidth + newProgress*distance;
                CGFloat newX = fromX - newProgress*distance;
                CGRect shadowFrame = shadow.frame;
                shadowFrame.size.width = newWidth;
                shadowFrame.origin.x = newX;
                shadow.frame = shadowFrame;
            }else if (progress <= -0.5) { //后半段-0.5~-1，x变大 w变小
                //让过程变成1~0
                CGFloat newProgress = 2*(1-fabs(progress));
                CGFloat newWidth = shadowWidth + newProgress*distance;
                CGRect shadowFrame = shadow.frame;
                shadowFrame.size.width = newWidth;
                shadowFrame.origin.x = toX;
                shadow.frame = shadowFrame;
            }
        }
    }
}

@end

#import <objc/runtime.h>

@implementation UIView (LetMeScroll)

static NSString *LetMeScrollFirstKey = @"LetMeScrollFirstKey";

- (void)setXl_letMeScrollFirst:(BOOL)xl_letMeScrollFirst {
    objc_setAssociatedObject(self, &LetMeScrollFirstKey,
                             @(xl_letMeScrollFirst), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)xl_letMeScrollFirst {
    return [objc_getAssociatedObject(self, &LetMeScrollFirstKey) boolValue];
}

@end


@implementation UIViewController (Title)

static NSString *XLVCTitleKey = @"XLVCTitleKey";

- (void)setXl_title:(NSString *)xl_title {
    objc_setAssociatedObject(self, &LetMeScrollFirstKey,
                             xl_title, OBJC_ASSOCIATION_COPY);
}

- (NSString *)xl_title {
    return objc_getAssociatedObject(self, &LetMeScrollFirstKey);
}

@end

@implementation UIScrollView (GestureRecognizer)

static NSString *XLOtherGestureRecognizerBlockKey = @"XLOtherGestureRecognizerBlockKey";

+ (void)load {
    [self addRecognizeSimultaneouslyObserver];
}

+ (void)addRecognizeSimultaneouslyObserver {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:);
        SEL swizzledSelector = @selector(xl_gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (BOOL)xl_gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    BOOL recognize = self.xl_otherGestureRecognizerBlock ? self.xl_otherGestureRecognizerBlock(otherGestureRecognizer) : NO;
    return recognize;
}

- (void)setXl_otherGestureRecognizerBlock:(XLOtherGestureRecognizerBlock)xl_otherGestureRecognizerBlock {
    objc_setAssociatedObject(self, &XLOtherGestureRecognizerBlockKey,
    xl_otherGestureRecognizerBlock, OBJC_ASSOCIATION_COPY);
}

- (XLOtherGestureRecognizerBlock)xl_otherGestureRecognizerBlock {
    return objc_getAssociatedObject(self, &XLOtherGestureRecognizerBlockKey);
}

@end
