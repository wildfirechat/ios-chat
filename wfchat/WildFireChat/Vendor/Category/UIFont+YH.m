//
//  UIFont+YH.m
//  WildFireChat
//
//  Created by Zack Zhang on 2020/3/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "UIFont+YH.h"
#import <WFChatUIKit/WFCUConfigManager.h>



@implementation UIFont (YH)
+ (UIFont *)pingFangSCWithWeight:(FontWeightStyle)fontWeight size:(CGFloat)fontSize {
    return [self _pingFangSCWithWeight:fontWeight size:fontSize];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:fontSize]];
}

+ (UIFont *)scaledBoldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont boldSystemFontOfSize:[WFCUConfigManager scaledSize:fontSize]];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight {
    return [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:fontSize] weight:weight];
}

+ (UIFont *)scaledPingFangSCWithWeight:(FontWeightStyle)fontWeight size:(CGFloat)fontSize {
    return [self _pingFangSCWithWeight:fontWeight size:[WFCUConfigManager scaledSize:fontSize]];
}

+ (UIFont *)scaledFontWithName:(NSString *)fontName size:(CGFloat)fontSize {
    UIFont *font = [UIFont fontWithName:fontName size:[WFCUConfigManager scaledSize:fontSize]];
    return font ?: [UIFont systemFontOfSize:[WFCUConfigManager scaledSize:fontSize]];
}

+ (UIFont *)_pingFangSCWithWeight:(FontWeightStyle)fontWeight size:(CGFloat)fontSize {
    if (fontWeight < FontWeightStyleMedium || fontWeight > FontWeightStyleThin) {
        fontWeight = FontWeightStyleRegular;
    }

    NSString *fontName = @"PingFangSC-Regular";
    switch (fontWeight) {
        case FontWeightStyleMedium:
            fontName = @"PingFangSC-Medium";
            break;
        case FontWeightStyleSemibold:
            fontName = @"PingFangSC-Semibold";
            break;
        case FontWeightStyleLight:
            fontName = @"PingFangSC-Light";
            break;
        case FontWeightStyleUltralight:
            fontName = @"PingFangSC-Ultralight";
            break;
        case FontWeightStyleRegular:
            fontName = @"PingFangSC-Regular";
            break;
        case FontWeightStyleThin:
            fontName = @"PingFangSC-Thin";
            break;
    }
    
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
 
    return font ?: [UIFont systemFontOfSize:fontSize];
}
@end
