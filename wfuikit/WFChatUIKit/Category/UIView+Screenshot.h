//
//  UIView+Screenshot.h
//  WildFireChat
//
//  Created by heavyrain lee on 02/01/2018.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Screenshot)
- (UIImage *)screenshot;
- (UIImage *)screenshotWithRect:(CGRect)rect;
@end
