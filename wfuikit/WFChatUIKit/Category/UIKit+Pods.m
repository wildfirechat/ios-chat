//
//  UIKit+Pods.m
//  WFChatUIKit
//
//  Created by dklinzh on 2019/7/22.
//

#import "UIKit+Pods.h"

@interface _BundleClass : NSObject

@end

@implementation _BundleClass

@end

@implementation NSBundle (Pods)

+ (instancetype)wf_bundle {
#ifdef COCOAPODS
    return [NSBundle bundleForClass:_BundleClass.class];
#else
    return [self mainBundle];
#endif
}

@end

@implementation UIImage (Pods)

+ (instancetype)wf_imageNamed:(NSString *)name {
#ifdef COCOAPODS
    return [self imageNamed:name inBundle:[NSBundle wf_bundle] compatibleWithTraitCollection:nil];
#else
    return [self imageNamed:name];
#endif
}

@end

@implementation UIView (Pods)

+ (instancetype)wf_createViewFromNibName:(NSString *)nibName {
#ifdef COCOAPODS
    NSArray *nib = [[NSBundle wf_bundle] loadNibNamed:nibName owner:self options:nil];
#else
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
#endif
    return [nib objectAtIndex:0];
}

+ (instancetype)wf_createViewFromNib {
    return [self wf_createViewFromNibName:NSStringFromClass(self.class)];
}

@end
