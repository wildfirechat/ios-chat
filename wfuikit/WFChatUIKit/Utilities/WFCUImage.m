//
//  WFCUImage.m
//  WFChatUIKit
//
//  Created by Rain on 2022/7/16.
//  Copyright © 2022 Wildfirechat. All rights reserved.
//

#import "WFCUImage.h"

@implementation WFCUImage
+ (nullable UIImage *)imageNamed:(NSString *)name {
    return [UIImage imageNamed:name inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
}
@end
