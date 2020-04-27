//
//  BubbleTipView.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/12.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "BubbleTipView.h"
#import <QuartzCore/QuartzCore.h>


#define kDefaultbubbleTipTextColor [UIColor whiteColor]
#define kDefaultbubbleTipBackgroundColor [UIColor redColor]
#define kDefaultOverlayColor [UIColor colorWithWhite:1.0f alpha:0.3]

#define kDefaultbubbleTipTextFont [UIFont systemFontOfSize:[UIFont smallSystemFontSize]]

#define kDefaultbubbleTipShadowColor [UIColor clearColor]

#define kbubbleTipStrokeColor [UIColor whiteColor]
#define kbubbleTipStrokeWidth 0.0f

#define kMarginToDrawInside (kbubbleTipStrokeWidth * 2)

#define kShadowOffset CGSizeMake(0.0f, 3.0f)
#define kShadowOpacity 0.2f
#define kShadowColor [UIColor colorWithWhite:0.0f alpha:kShadowOpacity]
#define kShadowRadius 1.0f

#define kbubbleTipHeight 18.0f
#define kbubbleTipTextSideMargin 6.0f

#define kbubbleTipCornerRadius 10.0f

#define kDefaultbubbleTipAlignment RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT

#define IOS_SYSTEM_VERSION_LESS_THAN(v)                                     \
                ([[[UIDevice currentDevice] systemVersion]                                   \
                                            compare:v                                        \
                                            options:NSNumericSearch] == NSOrderedAscending)

@implementation BubbleTipView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithSuperView:(UIView *)parentView {
    if ((self = [self initWithFrame:CGRectZero])) {
        [parentView addSubview:self];
    }
    
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    self.bubbleTipBackgroundColor = kDefaultbubbleTipBackgroundColor;
//    _bubbleTipOverlayColor = kDefaultOverlayColor;
//    self.bubbleTipTextColor = kDefaultbubbleTipTextColor;
    self.bubbleTipTextShadowColor = kDefaultbubbleTipShadowColor;
    self.bubbleTipTextFont = kDefaultbubbleTipTextFont;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // return;
    CGRect newFrame = self.frame;
    CGRect superviewFrame =
    CGRectIsEmpty(_frameToPositionInRelationWith) ? self.superview.frame : _frameToPositionInRelationWith;
    
    CGFloat textWidth = [self sizeOfTextForCurrentSettings].width;
    
    CGFloat viewWidth = textWidth + kbubbleTipTextSideMargin + (kMarginToDrawInside * 2);
    CGFloat viewHeight = kbubbleTipHeight + (kMarginToDrawInside * 2);
    
    if (self.isShowNotificationNumber) {
        newFrame.size.width = viewWidth;
        newFrame.size.height = viewHeight;
        newFrame.origin.y = 0;
        newFrame.origin.x = 48;
    }else{
        newFrame.size.width = 10;
        newFrame.size.height = 10;
        newFrame.origin.y = 4;
        newFrame.origin.x = 54;
    }
    
    
    newFrame.origin.x += _bubbleTipPositionAdjustment.x;
    newFrame.origin.y += _bubbleTipPositionAdjustment.y;
    
    self.frame = CGRectIntegral(newFrame);
    
    [self setNeedsDisplay];
}

#pragma mark - Private

- (CGSize)sizeOfTextForCurrentSettings {
    CGSize size;
    if (@available(iOS 7.0, *)) {
        size = [self.bubbleTipText sizeWithAttributes:@{NSFontAttributeName : self.bubbleTipTextFont}];
    } else {
        size = [self.bubbleTipText sizeWithFont:kDefaultbubbleTipTextFont];
    }
    
    if (self.bubbleTipText.length == 1) {
        size.width = 12;
    }
    if (self.bubbleTipText.length == 2) {
        size.width = 18;
    }
    if (self.bubbleTipText.length == 3) {
        size.width = 18;
    }
    
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

#pragma mark - Setters

- (void)setBubbleTipNumber:(int)msgCount {
    if (msgCount < 100 && msgCount > 0) {
        if(self.isShowNotificationNumber)
            [self setBubbleTipText:[NSString stringWithFormat:@"%d", msgCount]];
        else
            [self setBubbleTipText:@" "];
    } else if (msgCount >= 100) {
        if(self.isShowNotificationNumber)
            [self setBubbleTipText:@"···"];
        else
            [self setBubbleTipText:@" "];
    } else {
        [self setHidden:YES];
    }
    [self layoutSubviews];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {
    BOOL anyTextToDraw = (self.bubbleTipText.length > 0);
    
    if(!self.isShowNotificationNumber)
        [self setBubbleTipText:@" "];
    
    if (anyTextToDraw) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        CGRect rectToDraw = CGRectInset(rect, kMarginToDrawInside, kMarginToDrawInside);
        
        UIBezierPath *borderPath =
        [UIBezierPath bezierPathWithRoundedRect:rectToDraw
                              byRoundingCorners:(UIRectCorner)UIRectCornerAllCorners
                                    cornerRadii:CGSizeMake(kbubbleTipCornerRadius, kbubbleTipCornerRadius)];
        
        /* Background and shadow */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);
            
            CGContextSetFillColorWithColor(ctx, self.bubbleTipBackgroundColor.CGColor);
            // CGContextSetShadowWithColor(ctx, kShadowOffset, kShadowRadius, kShadowColor.CGColor);
            
            CGContextDrawPath(ctx, kCGPathFill);
        }
        CGContextRestoreGState(ctx);
        
        /* Stroke */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);
            
            CGContextSetLineWidth(ctx, kbubbleTipStrokeWidth);
            CGContextSetStrokeColorWithColor(ctx, kbubbleTipStrokeColor.CGColor);
            
            CGContextDrawPath(ctx, kCGPathStroke);
        }
        CGContextRestoreGState(ctx);
        
        /* Text */
        CGContextSaveGState(ctx);
        {
            CGContextSetFillColorWithColor(ctx, kDefaultbubbleTipTextColor.CGColor);
            CGContextSetShadowWithColor(ctx, self.bubbleTipTextShadowOffset, 1.0,
                                        self.bubbleTipTextShadowColor.CGColor);
            
            CGRect textFrame = rectToDraw;
            CGSize textSize = [self sizeOfTextForCurrentSettings];
            
            textFrame.size.height = textSize.height;
            textFrame.origin.y = rectToDraw.origin.y + ceilf((rectToDraw.size.height - textFrame.size.height) / 2.0f);
            if(IOS_SYSTEM_VERSION_LESS_THAN(@"7.0"))
            {
                [self.bubbleTipText drawInRect:textFrame
                                      withFont:self.bubbleTipTextFont
                                 lineBreakMode:NSLineBreakByCharWrapping
                                     alignment:NSTextAlignmentCenter];
            }
            else
            {
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
                paragraphStyle.alignment = NSTextAlignmentCenter;
                
                [self.bubbleTipText drawInRect:textFrame
                                withAttributes:@{
                                                 NSFontAttributeName : self.bubbleTipTextFont,
                                                 NSForegroundColorAttributeName : kDefaultbubbleTipTextColor,
                                                 NSParagraphStyleAttributeName : paragraphStyle
                                                 }];
            }
            
        }
        CGContextRestoreGState(ctx);
    }
}

@end
