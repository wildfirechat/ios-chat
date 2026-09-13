//
//  WFCCCertificateManager+IM.h
//  WFChatClient
//
//  把内置自签证书接入 IM 协议栈（mars::stn::UseTls / 证书链校验回调）。
//  这个分类依赖 WFChatClient，只编译进 WFChatClient target；
//  ShareExtension 等只复用 WFCCCertificateManager 本体的目标不要引入本文件。
//

#import "WFCCCertificateManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFCCCertificateManager (IM)

/**
 * 把已加载的证书应用到 IM 长连接。
 * 等价于 [WFCCNetworkService UseTls:NO selfSignedCerts:self.certificateFilePaths]。
 * 只有内存证书（没有源文件）时会先落到临时目录再传路径。
 * 需要在连接之前调用。
 */
- (void)applyToIMNetworkService;

/**
 * 便捷入口：遍历主 bundle 根目录下所有证书并应用到 IM。
 * 幂等，可以重复调用。
 */
+ (void)setupWithMainBundleCertificates;

@end

NS_ASSUME_NONNULL_END
