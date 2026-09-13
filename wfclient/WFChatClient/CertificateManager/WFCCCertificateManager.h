//
//  WFCCCertificateManager.h
//  WFChatClient
//
//  自签证书信任管理。
//
//  职责：
//  1. 遍历/加载 App 内置的证书文件（.cer/.crt/.pem/.der，一个 pem 文件里可以有多张证书）；
//  2. 为 NSURLSession、WKWebView、AFNetworking、IM 长连接等提供统一的证书信任评估接口。
//
//  主机绑定完全依赖证书里的 SAN（Subject Alternative Name）：评估时统一使用
//  SecPolicyCreateSSL(true, host)，证书必须覆盖客户端实际拨号的地址（域名或 IP），
//  没有跳过校验的后门。
//
//  本文件只依赖 Foundation / Security，可以同时被 WFChatClient、宿主 App 和
//  ShareExtension 复用（后两者可以不链接 WFChatClient，直接把本文件加入自己的编译源）。
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

/// 遍历证书时默认识别的文件扩展名（不区分大小写）
FOUNDATION_EXPORT NSArray<NSString *> *WFCCCertificateFileExtensions(void);

/// 信任模式
typedef NS_ENUM(NSInteger, WFCCCertTrustMode) {
    /// 默认：先走系统信任库，失败再用内置证书当锚点。
    /// 公签证书、用户自己安装并信任的证书、内置自签证书三种情况都能通过。
    WFCCCertTrustModeSystemThenPin = 0,
    /// 只用内置证书当锚点，忽略系统信任库里的其它根证书。
    WFCCCertTrustModePinOnly = 1,
};

/// 证书链校验策略
typedef NS_ENUM(NSInteger, WFCCCertPolicyMode) {
    /**
     * 严格：使用 SecPolicyCreateSSL，遵守 Apple 对 TLS 服务端证书的全部策略——
     * 825 天有效期上限、extendedKeyUsage=serverAuth、SAN 主机匹配全部由系统完成。
     * 要求证书合规，不合规的证书即使内置为信任锚也会被拒绝。
     */
    WFCCCertPolicyModeTLS = 0,
    /**
     * 宽松：使用 SecPolicyCreateBasicX509，只校验证书链和有效期，
     * 不套用 Apple 对 TLS 证书的 825 天有效期上限、serverAuth EKU 等要求；
     * 主机绑定由本模块按证书 SAN 自行完成（域名/IP/通配）。
     * 用于兼容不满足 Apple TLS 策略的自签证书。
     */
    WFCCCertPolicyModePermissive = 1,
};

#pragma mark - 证书对象

/**
 * 一张已解析的证书。除 DER 数据外，还暴露证书里绑定的身份（SAN/CN/有效期），
 * 供上层做日志、提前校验和给用户友好提示。
 */
@interface WFCCCertificate : NSObject

/// DER 原始数据
@property (nonatomic, copy, readonly) NSData *derData;
/// 来源文件路径（如果有）。mars::stn::UseTls 需要的是路径而不是内容
@property (nonatomic, copy, readonly, nullable) NSString *filePath;
/// 证书主题摘要，一般就是 CN
@property (nonatomic, copy, readonly) NSString *subject;
/// 主题里的 CN（Common Name）
@property (nonatomic, copy, readonly, nullable) NSString *commonName;
/// SHA-256 指纹，形如 "AB:CD:..."，便于排障和确认换证书是否生效
@property (nonatomic, copy, readonly) NSString *sha256Fingerprint;
/// 生效时间
@property (nonatomic, strong, readonly, nullable) NSDate *notBefore;
/// 过期时间
@property (nonatomic, strong, readonly, nullable) NSDate *notAfter;
/// 是否已过期（无法解析有效期时为 NO）
@property (nonatomic, readonly) BOOL expired;

/// 证书 SAN 里的 DNS 名称
@property (nonatomic, copy, readonly) NSArray<NSString *> *dnsNames;
/// 证书 SAN 里的 IP 地址
@property (nonatomic, copy, readonly) NSArray<NSString *> *ipAddresses;

- (instancetype)init NS_UNAVAILABLE;

/**
 * host 是否被这张证书覆盖。
 * 域名大小写不敏感，支持 *.example.com 通配（只匹配一层）；IP 按 SAN 里的 IP 精确匹配。
 * 注意：这只是给上层做提前校验/日志用的，真正的信任判断在 evaluateServerTrust:host:。
 */
- (BOOL)matchesHost:(NSString *)host;

/// 一行可读摘要，用于日志
- (NSString *)summary;

@end

#pragma mark - 管理器

@interface WFCCCertificateManager : NSObject

+ (instancetype)sharedManager;
- (instancetype)init NS_DESIGNATED_INITIALIZER;

#pragma mark 配置

/// 总开关，默认 YES。关闭后所有评估都只用系统信任库，不做内置证书覆盖
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
/// 信任模式，默认 WFCCCertTrustModeSystemThenPin
@property (nonatomic, assign) WFCCCertTrustMode trustMode;
/// 证书链校验策略，默认 WFCCCertPolicyModePermissive（兼容不合规的自签证书）
@property (nonatomic, assign) WFCCCertPolicyMode policyMode;
/// 是否输出评估过程日志，默认 YES
@property (nonatomic, assign) BOOL verboseLog;

#pragma mark 遍历 / 加载证书

/// 遍历 bundle 资源根目录（不递归）下所有证书文件并加载，返回本次新增的证书
- (NSArray<WFCCCertificate *> *)loadCertificatesFromBundle:(NSBundle *)bundle;
/// 遍历目录下的证书文件，recursive=YES 时递归子目录
- (NSArray<WFCCCertificate *> *)loadCertificatesFromDirectory:(NSString *)directory recursive:(BOOL)recursive;
/// 加载单个证书文件，返回本次新增的证书（pem 里有多张会全部加载）
- (NSArray<WFCCCertificate *> *)addCertificateFile:(NSString *)filePath;
/// 直接加载 DER/PEM 数据，返回新增的第一张证书
- (nullable WFCCCertificate *)addCertificateData:(NSData *)data;
/// 清空已加载的证书
- (void)removeAllCertificates;

/// 已加载的全部证书（只读快照）
@property (nonatomic, copy, readonly) NSArray<WFCCCertificate *> *certificates;
/// 已加载证书对应的文件路径，可直接传给 mars::stn::UseTls
@property (nonatomic, copy, readonly) NSArray<NSString *> *certificateFilePaths;
/// 把没有源文件的证书（运行时下发的）落成临时文件并返回路径
- (NSArray<NSString *> *)materializeCertificateFilesToDirectory:(NSString *)directory;

#pragma mark 信任评估

/**
 * 评估一条服务端信任链。
 * host 参与 SAN 校验，传 nil 时只校验证书链本身。
 */
- (BOOL)evaluateServerTrust:(SecTrustRef)trust host:(nullable NSString *)host;

/**
 * 评估一条 DER 证书链（leaf 在首位）。
 * 用于协议栈等只有证书链原始数据、没有 SecTrustRef 的场景。
 */
- (BOOL)evaluateCertificateChain:(NSArray<NSData *> *)derChain host:(nullable NSString *)host;

/**
 * 统一处理鉴权挑战，host 取自 challenge.protectionSpace。
 * NSURLSessionDataDelegate、AFNetworking 的 challenge block、WKWebView 的
 * didReceiveAuthenticationChallenge 都可以直接转调这里。
 */
- (void)handleChallenge:(NSURLAuthenticationChallenge *)challenge
             completion:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential * _Nullable credential))completion;

/**
 * 返回一个可直接赋给 AFNetworking 的
 * setSessionDidReceiveAuthenticationChallengeBlock: 的 block。
 * 非 serverTrust 的挑战会返回 NSURLSessionAuthChallengePerformDefaultHandling。
 */
- (NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session,
                                            NSURLAuthenticationChallenge *challenge,
                                            NSURLCredential * _Nullable __autoreleasing * _Nullable credential))sessionChallengeBlock;

#pragma mark 诊断

/// 把"当前 host + 已加载证书各自的 SAN/有效期"拼成一段可读文本，证书不匹配时方便现场排查
- (NSString *)describeCertificatesForHost:(nullable NSString *)host;

@end

#pragma mark - 可直接当 session delegate 用的轻量代理

/**
 * 只处理证书挑战，不带其它 NSURLSession 回调。
 * 已经有自己 delegate 的地方（例如 WFCCIMService 里带上传进度的 model）不要用它，
 * 直接在原有 delegate 里实现挑战方法并转调 handleChallenge:completion: 即可。
 */
@interface WFCCCertificateURLSessionDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate>
+ (instancetype)delegateWithManager:(WFCCCertificateManager *)manager;
@end

@interface NSURLSession (WFCCCertificate)

/// 创建一个带自签证书信任的 session
+ (NSURLSession *)wfc_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
                                 delegateQueue:(nullable NSOperationQueue *)queue;

/// 创建一个带自签证书信任的 session（内部串行队列）
+ (NSURLSession *)wfc_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
