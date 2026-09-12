//
//  WFCUAsrAuth.h
//  WFChatUIKit
//
//  Created by WildFireChat.
//  Copyright © 2026 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * asr-api 鉴权
 * <p>
 * 请求 asr-api 时，需要在 HTTP header authCode 中带上从 IM 服务获取的认证码，asr-api 向 IM 服务校验认证码后得到用户 ID。
 * 认证码 1 分钟内有效，每次请求前重新获取。
 */
@interface WFCUAsrAuth : NSObject

/// 鉴权请求头，asr-api 从该 header 中读取认证码
@property (class, nonatomic, readonly) NSString *headerAuthCode;

/**
 * 是否是 asr-api 的地址。asr-api 的接口都在 /api/ 路径下，直连 wf-voice 的地址没有路径
 */
+ (BOOL)isAsrApiUrl:(NSString *)url;

/**
 * 获取认证码，主线程回调
 */
+ (void)getAuthCode:(void (^)(NSString *authCode))success
              error:(void (^)(int errorCode))error;

@end

NS_ASSUME_NONNULL_END
