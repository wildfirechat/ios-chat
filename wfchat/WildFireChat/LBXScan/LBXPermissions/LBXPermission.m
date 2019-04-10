//
//  LBXPermission.m
//  LBXKits
//
//  Created by lbx on 2017/9/7.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "LBXPermission.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>


typedef void(^completionPermissionHandler)(BOOL granted,BOOL firstTime);


@implementation LBXPermission

+ (BOOL)authorizedWithType:(LBXPermissionType)type
{
    SEL sel = NSSelectorFromString(@"authorized");
    
    NSString *strClass = nil;
    switch (type) {
        case LBXPermissionType_Camera:
            strClass = @"LBXPermissionCamera";
            break;
        case LBXPermissionType_Photos:
            strClass = @"LBXPermissionPhotos";
            break;
        default:
            break;
    }
    
    if (strClass) {
        BOOL ret  = ((BOOL *(*)(id,SEL))objc_msgSend)( NSClassFromString(strClass), sel);
        return ret;
    }
    
    return NO;
}

+ (void)authorizeWithType:(LBXPermissionType)type completion:(void(^)(BOOL granted,BOOL firstTime))completion
{
    NSString *strClass = nil;
    switch (type) {
        case LBXPermissionType_Camera:
            strClass = @"LBXPermissionCamera";
            break;
        case LBXPermissionType_Photos:
            strClass = @"LBXPermissionPhotos";
            break;
        default:
            break;
    }
    
    if (strClass)
    {
        SEL sel = NSSelectorFromString(@"authorizeWithCompletion:");
        ((void(*)(id,SEL, completionPermissionHandler))objc_msgSend)(NSClassFromString(strClass),sel, completion);
    }
}

@end
