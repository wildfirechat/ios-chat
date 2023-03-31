//
//  XLPageTitleCell.m
//  XLPageViewControllerExample
//
//  Created by MengXianLiang on 2019/5/13.
//  Copyright © 2019 xianliang meng. All rights reserved.
//  https://github.com/mengxianliang/XLPageViewController

#import <UIKit/UIKit.h>
#import "XLPageTitleCell.h"

#pragma mark -
#pragma mark 自定义cell类
@interface XLPageTitleLabel : UILabel

@property (nonatomic, assign) XLPageTextVerticalAlignment textVerticalAlignment;

@end

@implementation XLPageTitleLabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    switch (self.textVerticalAlignment) {
        case XLPageTextVerticalAlignmentCenter:
            textRect.origin.y = (bounds.size.height - textRect.size.height)/2.0;
            break;
        case XLPageTextVerticalAlignmentTop: {
            CGFloat topY = self.font.pointSize > [UIFont labelFontSize] ? 0 : 2;
            textRect.origin.y = topY;
        }
            break;
        case XLPageTextVerticalAlignmentBottom:
            textRect.origin.y = bounds.size.height - textRect.size.height;
            break;
        default:
            break;
    }
    return textRect;
}

- (void)drawTextInRect:(CGRect)requestedRect {
    CGRect actualRect = [self textRectForBounds:requestedRect limitedToNumberOfLines:self.numberOfLines];
    [super drawTextInRect:actualRect];
}

@end

#pragma mark -
#pragma mark Cell类

@implementation XLPageTitleCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.textLabel = [[XLPageTitleLabel alloc] init];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.textLabel];
        self.config = [XLPageViewControllerConfig defaultConfig];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
}

- (void)configCellOfSelected:(BOOL)selected {
    self.textLabel.textColor = selected ? self.config.titleSelectedColor : self.config.titleNormalColor;
    self.textLabel.font = selected ? self.config.titleSelectedFont : self.config.titleNormalFont;
    XLPageTitleLabel *label = (XLPageTitleLabel *)self.textLabel;
    label.textVerticalAlignment = self.config.textVerticalAlignment;
}

- (void)showAnimationOfProgress:(CGFloat)progress type:(XLPageTitleCellAnimationType)type {
    if (type == XLPageTitleCellAnimationTypeSelected) {
        self.textLabel.textColor = [XLPageViewControllerUtil colorTransformFrom:self.config.titleSelectedColor to:self.config.titleNormalColor progress:progress];
    }else if (type == XLPageTitleCellAnimationTypeWillSelected){
        self.textLabel.textColor = [XLPageViewControllerUtil colorTransformFrom:self.config.titleNormalColor to:self.config.titleSelectedColor progress:progress];
    }
}

@end
