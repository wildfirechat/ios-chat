//
//  WFCUAFSecurityPolicy+Certificate.h
//  WFChatUIKit
//
//  让 AFNetworking（App 的应用服务、组织通讯录、投票、网盘、归档、接龙以及
//  WFChatUIKit 自身的媒体下载）支持内置自签证书。
//
//  AFNetworking 默认用 AFSecurityPolicy 走 SSL 策略评估，自签证书会被拒绝，
//  而且用它的 pinning 也绕不过 Apple 对 TLS 证书的策略（825 天有效期、serverAuth EKU）。
//  这里在 AFSecurityPolicy 的评估入口上挂一层：先用 WFCCCertificateManager 评估，
//  通过就直接放行，否则完全回落到 AFNetworking 原有逻辑（只增加信任，不降低）。
//

#import "AFSecurityPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@interface AFSecurityPolicy (WFCUCertificate)

/// 安装（幂等）。+load 会自动调用，一般不需要手动调用
+ (void)installCertificateSupport;

@end

NS_ASSUME_NONNULL_END
