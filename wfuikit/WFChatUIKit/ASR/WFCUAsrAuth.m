//
//  WFCUAsrAuth.m
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import "WFCUAsrAuth.h"
#import "WFCUConfigManager.h"
#import <WFChatClient/WFCChatClient.h>

@implementation WFCUAsrAuth

+ (NSString *)headerAuthCode {
    return @"authCode";
}

+ (BOOL)isAsrApiUrl:(NSString *)url {
    if (!url.length) {
        return NO;
    }
    NSURL *nsUrl = [NSURL URLWithString:url];
    NSString *path = nsUrl.path;
    return path.length > 0 && [path rangeOfString:@"/api/"].location != NSNotFound;
}

+ (void)getAuthCode:(void (^)(NSString *authCode))success
              error:(void (^)(int errorCode))error {
    WFCUConfigManager *manager = [WFCUConfigManager globalManager];
    if (manager.asrAuthCodeProvider) {
        manager.asrAuthCodeProvider(success, error);
        return;
    }
    // 和组织通讯录服务一样，使用管理后台类型（ApplicationType_Admin）的认证码
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin"
                                               type:2
                                               host:manager.imServerHost
                                            success:^(NSString *authCode) {
        if (success) {
            success(authCode);
        }
    } error:^(int error_code) {
        if (error) {
            error(error_code);
        }
    }];
}

@end
