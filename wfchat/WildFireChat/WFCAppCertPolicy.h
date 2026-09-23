//
//  WFCAppCertPolicy.h
//  WildFireChat
//
//  私有化部署（自签 CA）下的**应用层 HTTPS** 证书策略。
//
//  背景：本部署的服务端证书由内置 CA（cacert.crt，CN=wildfire-im）签发，
//        系统信任库不认识它，因此 AppServer / 组织通讯录 / 投票 / 接龙 / 语音转文字
//        这些 https 接口如果只用系统信任校验会握手失败（表现为登录报网络错误）。
//        这里用「钉扎内置 CA」的方式校验：既不用让测试设备装描述文件，也不跳过校验。
//
//  注意：
//   1) 若服务端换成公签证书，请删掉这些调用（或改为 [AFSecurityPolicy defaultPolicy]）。
//   2) 协议栈（IM 长连接）的证书另有一套，在 AppDelegate 里通过
//      setUseWebsocket: / UseTls:selfSignedCerts: 设置，见那里的注释。
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@interface WFCAppCertPolicy : NSObject

/// 取（首次调用时构建并缓存）钉扎了内置 CA 的安全策略
+ (AFSecurityPolicy *)pinnedPolicy;

/// 给 AFHTTPSessionManager 应用钉扎策略（创建 manager 后调用一行）
+ (void)applyTo:(AFHTTPSessionManager *)manager;

@end
