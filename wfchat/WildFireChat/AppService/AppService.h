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

- (void)login:(NSString *)user password:(NSString *)password success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)sendCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

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
@end

NS_ASSUME_NONNULL_END
