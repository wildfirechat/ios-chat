//
//  WFCUCertImageDownloaderOperation.m
//  WFChatUIKit
//

#import "WFCUCertImageDownloaderOperation.h"
#import <WFChatClient/WFCChatClient.h>

@implementation WFCUCertImageDownloaderOperation

+ (void)load {
    [self install];
}

+ (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 必须在 SDWebImageDownloader.sharedDownloader 创建之前设置，所以放在 +load 里
        SDWebImageDownloaderConfig.defaultDownloaderConfig.operationClass = [WFCUCertImageDownloaderOperation class];
    });
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [[WFCCCertificateManager sharedManager] handleChallenge:challenge completion:completionHandler];
        return;
    }
    // 非证书挑战交回父类（保留 SDWebImage 自己的 credential 处理）
    if ([SDWebImageDownloaderOperation instancesRespondToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]) {
        [super URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end
