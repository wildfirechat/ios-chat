//
//  WFCAppCertPolicy.m
//  WildFireChat
//

#import "WFCAppCertPolicy.h"

static AFSecurityPolicy *gWFCAppCertPolicy = nil;

@implementation WFCAppCertPolicy

+ (AFSecurityPolicy *)pinnedPolicy {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 与协议栈保持一致的约定：内置 CA 放在 App Bundle，命名为 cacert/ca-bundle/ca/rootca（.crt 或 .pem）
        NSString *caPath = [[NSBundle mainBundle] pathForResource:@"cacert" ofType:@"crt"];
        if (caPath.length == 0) {
            caPath = [[NSBundle mainBundle] pathForResource:@"cacert" ofType:@"pem"];
        }
        NSData *caData = caPath.length ? [NSData dataWithContentsOfFile:caPath] : nil;
        if (caData.length == 0) {
            // CA 缺失时不静默跳过校验，只回退系统默认策略并明确报错，避免"看起来连上了其实没校验"
            NSLog(@"[WFC] 未找到内置 CA（cacert.crt）—— 应用层 HTTPS 将使用系统默认校验策略；"
                   "请确认 cacert.crt 已加入 App 的 Copy Bundle Resources");
            gWFCAppCertPolicy = [AFSecurityPolicy defaultPolicy];
            return;
        }

        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        policy.allowInvalidCertificates = NO;   // 不跳过校验：用内置 CA 作为锚点做校验（钉扎）
        policy.validatesDomainName = YES;       // 服务端叶子证书 SAN 已包含授权地址，可正常通过
        policy.pinnedCertificates = [NSSet setWithObject:caData];
        gWFCAppCertPolicy = policy;
        NSLog(@"[WFC] 应用层证书钉扎已启用（内置 CA：%@）", caPath.lastPathComponent);
    });
    return gWFCAppCertPolicy;
}

+ (void)applyTo:(AFHTTPSessionManager *)manager {
    if (manager) {
        manager.securityPolicy = [self pinnedPolicy];
    }
}

@end
