//
//  WFCCCertificateManager+IM.m
//  WFChatClient
//

#import "WFCCCertificateManager+IM.h"
#import "WFCCNetworkService.h"

@implementation WFCCCertificateManager (IM)

- (void)applyToIMNetworkService {
    NSArray<NSString *> *paths = self.certificateFilePaths;
    if (paths.count < self.certificates.count) {
        // 有只在内存里的证书（运行时下发），先落成文件再交给协议栈
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"wfc_certs"];
        paths = [self materializeCertificateFilesToDirectory:directory];
    }
    [[WFCCNetworkService sharedInstance] UseTls:NO selfSignedCerts:paths];
}

+ (void)setupWithMainBundleCertificates {
    WFCCCertificateManager *manager = [WFCCCertificateManager sharedManager];
    [manager loadCertificatesFromBundle:[NSBundle mainBundle]];
    [manager applyToIMNetworkService];
}

@end
