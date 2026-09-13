//
//  WFCUAFSecurityPolicy+Certificate.m
//  WFChatUIKit
//

#import "WFCUAFSecurityPolicy+Certificate.h"
#import <objc/runtime.h>

// WFChatUIKit / App 走 <WFChatClient/...>；
// ShareExtension 不链接 WFChatClient，编译时定义 WFCU_CERT_LOCAL_MANAGER，
// 直接复用同一份源文件并通过 HEADER_SEARCH_PATHS 找到证书管理器
#ifdef WFCU_CERT_LOCAL_MANAGER
#import "WFCCCertificateManager.h"
#else
#import <WFChatClient/WFCCCertificateManager.h>
#endif

@implementation AFSecurityPolicy (WFCUCertificate)

+ (void)load {
    [self installCertificateSupport];
}

+ (void)installCertificateSupport {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod(self, @selector(evaluateServerTrust:forDomain:));
        Method replacement = class_getInstanceMethod(self, @selector(wfc_evaluateServerTrust:forDomain:));
        if (original && replacement) {
            method_exchangeImplementations(original, replacement);
        }
    });
}

- (BOOL)wfc_evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain {
    WFCCCertificateManager *manager = [WFCCCertificateManager sharedManager];
    if (manager.isEnabled && manager.certificates.count > 0) {
        if ([manager evaluateServerTrust:serverTrust host:domain]) {
            return YES;
        }
    }
    // 没通过就完全交回 AFNetworking 原有逻辑
    return [self wfc_evaluateServerTrust:serverTrust forDomain:domain];
}

@end
