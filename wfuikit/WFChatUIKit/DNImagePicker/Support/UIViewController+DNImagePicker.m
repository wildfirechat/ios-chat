//
//  UIViewController+DNImagePicker.m
//  ImagePicker
//
//  Created by DingXiao on 15/2/10.
//  Copyright (c) 2015年 dennis. All rights reserved.
//

#import "UIViewController+DNImagePicker.h"
#import "UIColor+Hex.h"

@implementation UIViewController (DNImagePicker)
- (void)createBarButtonItemAtPosition:(DNImagePickerNavigationBarPosition)position statusNormalImage:(UIImage *)normalImage statusHighlightImage:(UIImage *)highlightImage action:(SEL)action {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIEdgeInsets insets = UIEdgeInsetsZero;
    switch (position) {
        case DNImagePickerNavigationBarPositionLeft:
            insets = UIEdgeInsetsMake(0, -20, 0, 20);
            break;
        case DNImagePickerNavigationBarPositionRight:
            insets = UIEdgeInsetsMake(0, 13, 0, -13);
            break;
        default:
            break;
    }
    
    [button setImageEdgeInsets:insets];
    [button setFrame:CGRectMake(0, 0, 44, 44)];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setImage:normalImage forState:UIControlStateNormal];
    [button setImage:highlightImage forState:UIControlStateHighlighted];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    switch (position) {
        case DNImagePickerNavigationBarPositionLeft:
            self.navigationItem.leftBarButtonItem = barButtonItem;
            break;
        case DNImagePickerNavigationBarPositionRight:
            self.navigationItem.rightBarButtonItem = barButtonItem;
            break;
        default:
            break;
    }
}

- (void)createBarButtonItemAtPosition:(DNImagePickerNavigationBarPosition)position text:(NSString *)text action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIEdgeInsets insets = UIEdgeInsetsZero;
    switch (position) {
        case DNImagePickerNavigationBarPositionLeft:
            insets = UIEdgeInsetsMake(0, -49 + 26, 0, 19);
            break;
        case DNImagePickerNavigationBarPositionRight:
            insets = UIEdgeInsetsMake(0, 49 - 26, 0, -19);
            break;
        default:
            break;
    }
    
    [button setTitleEdgeInsets:insets];
    [button setFrame:CGRectMake(0, 0, 64, 30)];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:text forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0f];
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor dn_hexStringToColor:@"#808080"] forState:UIControlStateHighlighted];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    switch (position) {
        case DNImagePickerNavigationBarPositionLeft:
            self.navigationItem.leftBarButtonItem = barButtonItem;
            break;
        case DNImagePickerNavigationBarPositionRight:
            self.navigationItem.rightBarButtonItem = barButtonItem;
            break;
        default:
            break;
    }
}

- (void)createBackBarButtonItemStatusNormalImage:(UIImage *)normalImage statusHighlightImage:(UIImage *)highlightImage withTitle:(NSString *)title action:(SEL)action {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 84, 44)];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor dn_hexStringToColor:@"#808080"] forState:UIControlStateHighlighted];
    UIEdgeInsets imageInsets = UIEdgeInsetsMake(0, -20, 0, 60);
    UIEdgeInsets titleInsets = UIEdgeInsetsMake(0, -45, 0, -15);
    [button.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [button setImageEdgeInsets:imageInsets];
    [button setTitleEdgeInsets:titleInsets];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateHighlighted];
    [button setImage:normalImage forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

@end
