//
//  LBXPermission.m
//  LBXKits
//
//  Created by lbx on 2017/9/7.
//  Copyright © 2017年 lbx. All rights reserved.
//

#import "LBXPermission.h"
#import <UIKit/UIKit.h>

#import "LBXPermissionCamera.h"
#import "LBXPermissionPhotos.h"

@implementation LBXPermission

+ (BOOL)authorizedWithType:(LBXPermissionType)type
{
    switch (type) {
        case LBXPermissionType_Camera:
            return [LBXPermissionCamera authorized];
            break;
        case LBXPermissionType_Photos:
            return [LBXPermissionPhotos authorized];
            break;
        default:
            break;
    }
    return NO;
}

+ (void)authorizeWithType:(LBXPermissionType)type completion:(void(^)(BOOL granted,BOOL firstTime))completion
{
    switch (type) {
        case LBXPermissionType_Camera:
            return [LBXPermissionCamera authorizeWithCompletion:completion];
            break;
        case LBXPermissionType_Photos:
            return [LBXPermissionPhotos authorizeWithCompletion:completion];
            break;
            
        default:
            break;
    }
}

@end
