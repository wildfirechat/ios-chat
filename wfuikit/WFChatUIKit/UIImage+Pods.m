//
//  UIImage+Pods.m
//  WFChatUIKit
//
//  Created by dklinzh on 2019/7/22.
//

#import "UIImage+Pods.h"

@implementation UIImage (Pods)

+ (instancetype)wf_imageNamed:(NSString *)name {
#ifdef COCOAPODS
    return [self imageNamed:name inBundle:[NSBundle bundleForClass:self] compatibleWithTraitCollection:nil];
#else
    return [self imageNamed:name];
#endif
}

@end
