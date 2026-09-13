//
//  WFCUCertImageDownloaderOperation.h
//  WFChatUIKit
//
//  让 SDWebImage 的图片下载（头像、图片消息、表情等）支持内置自签证书。
//
//  SDWebImage 的下载最终走 NSURLSession 的默认信任评估，自签证书会被拒绝。
//  这里继承 SDWebImageDownloaderOperation 覆写鉴权挑战，统一交给 WFCCCertificateManager 评估；
//  并在 +load 中把它设为默认 operation，无需改动任何 sd_setImageWithURL 调用点。
//

#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCUCertImageDownloaderOperation : SDWebImageDownloaderOperation

/// 把本类设为 SDWebImage 默认的下载 Operation，幂等
+ (void)install;

@end

NS_ASSUME_NONNULL_END
