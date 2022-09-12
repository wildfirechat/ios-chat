//
//  AppService.h
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import <WFChatClient/WFCChatClient.h>
#import "Device.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppService : NSObject <WFCUAppServiceProvider>
+ (AppService *)sharedAppService;

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)sendLoginCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

//发送删除账号验证码
- (void)sendDestroyAccountCode:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyAccount:(NSString *)code success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock;

- (void)showPCSessionViewController:(UIViewController *)baseController pcClient:(WFCCPCOnlineInfo *)clientInfo;

- (void)addDevice:(NSString *)name
         deviceId:(NSString *)deviceId
            owner:(NSArray<NSString *> *)owners
          success:(void(^)(Device *device))successBlock
            error:(void(^)(int error_code))errorBlock;

- (void)getMyDevices:(void(^)(NSArray<Device *> *devices))successBlock
               error:(void(^)(int error_code))errorBlock;

- (void)delDevice:(NSString *)deviceId
          success:(void(^)(Device *device))successBlock
            error:(void(^)(int error_code))errorBlock;

- (NSData *)getAppServiceCookies;
- (NSString *)getAppServiceAuthToken;

//清除应用服务认证cookies和认证token
- (void)clearAppServiceAuthInfos;
@end

NS_ASSUME_NONNULL_END
