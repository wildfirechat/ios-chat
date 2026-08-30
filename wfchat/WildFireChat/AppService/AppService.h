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

@interface AppService : NSObject <WFCUAppServiceProvider, WFCCDefaultPortraitProvider>
+ (AppService *)sharedAppService;

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword slideVerifyToken:(NSString *)slideVerifyToken success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)sendLoginCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendLoginCode:(NSString *)phoneNumber slideVerifyToken:(NSString *)slideVerifyToken success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendResetCode:(NSString *)phoneNumber slideVerifyToken:(NSString *)slideVerifyToken success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

//发送删除账号验证码
- (void)sendDestroyAccountCode:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
- (void)sendDestroyAccountCode:(NSString *)slideVerifyToken success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyAccount:(NSString *)code success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

//创建扫码登录会话（本端=被扫码端）。userId 为空表示全新的登录二维码；
//返回的 token 用于拼二维码内容：wildfirechat://pcsession/<token>（手机端扫码后确认登录）。
- (void)createPCLoginSession:(NSString *)userId success:(void(^)(NSString *token))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

//轮询扫码登录状态（与 PC 端 loginWithPCSession 同一接口）。
//code 0 = 登录成功，result 里是 userId/imToken；9 = 已被扫码、等待手机端确认；
//18 = 会话已取消（手机端拒绝/取消），应重新生成二维码。
- (void)loginWithPCLoginSession:(NSString *)token
                        success:(void(^)(NSString *userId, NSString *imToken))successBlock
                        scanned:(void(^)(NSString *userName, NSString *portrait))scannedBlock
                       canceled:(void(^)(void))canceledBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock;

- (void)showPCSessionViewController:(UIViewController *)baseController pcOnlineInfos:(NSArray<WFCCPCOnlineInfo *> *)onlineInfos;

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

// 滑动验证
- (void)getSlideVerify:(void(^)(NSDictionary *result))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)verifySlide:(NSString *)token x:(int)x success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (NSData *)getAppServiceCookies;
- (NSString *)getAppServiceAuthToken;

//清除应用服务认证cookies和认证token
- (void)clearAppServiceAuthInfos;

// 版本检查
- (void)checkVersion:(void(^)(NSDictionary *versionInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;
@end

NS_ASSUME_NONNULL_END
