//
//  WFCCCertificateManager.m
//  WFChatClient
//

#import "WFCCCertificateManager.h"

#import <CommonCrypto/CommonDigest.h>
#import <arpa/inet.h>

NSArray<NSString *> *WFCCCertificateFileExtensions(void) {
    static NSArray<NSString *> *extensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extensions = @[@"cer", @"crt", @"pem", @"der"];
    });
    return extensions;
}

#pragma mark - 极简 DER 解析
// 说明：SecCertificateCopyValues 在 iOS 上是 __IPHONE_NA（不可用），
// 所以 SAN / CN / 有效期这些信息自己解析 X.509 DER 拿。
// 解析失败只会导致诊断信息缺失，不影响真正的信任判断（那是 Security.framework 做的）。

static BOOL WFCCDERReadTLV(const uint8_t *buf, NSUInteger len, NSUInteger *offset,
                           uint8_t *outTag, NSUInteger *outContentOffset, NSUInteger *outContentLen) {
    NSUInteger o = *offset;
    if (o + 2 > len) {
        return NO;
    }
    uint8_t tag = buf[o++];
    NSUInteger l = buf[o++];
    if (l & 0x80) {
        NSUInteger numBytes = l & 0x7F;
        if (numBytes == 0 || numBytes > 4 || o + numBytes > len) {
            return NO;
        }
        l = 0;
        for (NSUInteger i = 0; i < numBytes; i++) {
            l = (l << 8) | buf[o++];
        }
    }
    if (o + l > len) {
        return NO;
    }
    if (outTag) *outTag = tag;
    if (outContentOffset) *outContentOffset = o;
    if (outContentLen) *outContentLen = l;
    *offset = o + l;
    return YES;
}

static NSString *WFCCDEROIDString(const uint8_t *buf, NSUInteger len) {
    if (len == 0) {
        return nil;
    }
    NSMutableString *string = [NSMutableString string];
    NSUInteger i = 0;
    uint32_t first = buf[i++];
    [string appendFormat:@"%u.%u", first / 40, first % 40];
    uint32_t value = 0;
    while (i < len) {
        uint8_t b = buf[i++];
        value = (value << 7) | (b & 0x7F);
        if (!(b & 0x80)) {
            [string appendFormat:@".%u", value];
            value = 0;
        }
    }
    return string;
}

static NSString *WFCCIPString(const uint8_t *bytes, NSUInteger len) {
    char buffer[INET6_ADDRSTRLEN] = {0};
    if (len == 4) {
        if (inet_ntop(AF_INET, bytes, buffer, sizeof(buffer))) {
            return [NSString stringWithUTF8String:buffer];
        }
    } else if (len == 16) {
        if (inet_ntop(AF_INET6, bytes, buffer, sizeof(buffer))) {
            return [[NSString stringWithUTF8String:buffer] lowercaseString];
        }
    }
    return nil;
}

static NSDate *WFCCDERTime(const uint8_t *buf, NSUInteger len, uint8_t tag) {
    NSString *string = [[NSString alloc] initWithBytes:buf length:len encoding:NSASCIIStringEncoding];
    if (!string.length) {
        return nil;
    }
    NSString *clean = [string stringByReplacingOccurrencesOfString:@"Z" withString:@""];
    clean = [clean stringByReplacingOccurrencesOfString:@"z" withString:@""];
    // 去掉可能的小数秒
    NSRange dot = [clean rangeOfString:@"."];
    if (dot.location != NSNotFound) {
        clean = [clean substringToIndex:dot.location];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSString *format = nil;
    if (tag == 0x17) {
        // UTCTime: YYMMDDHHMMSS
        format = clean.length == 12 ? @"yyMMddHHmmss" : @"yyMMddHHmm";
    } else if (tag == 0x18) {
        // GeneralizedTime: YYYYMMDDHHMMSS
        format = clean.length == 14 ? @"yyyyMMddHHmmss" : @"yyyyMMddHHmm";
    } else {
        return nil;
    }
    formatter.dateFormat = format;
    return [formatter dateFromString:clean];
}

/// Name ::= SEQUENCE OF RelativeDistinguishedName，取 CN（2.5.4.3）
static void WFCCDERParseName(const uint8_t *buf, NSUInteger len, NSString **outCN) {
    NSUInteger o = 0;
    while (o < len) {
        uint8_t tag;
        NSUInteger contentOffset = 0, contentLen = 0;
        NSUInteger next = o;
        if (!WFCCDERReadTLV(buf, len, &next, &tag, &contentOffset, &contentLen)) {
            break;
        }
        if (tag == 0x31) { // SET
            const uint8_t *setBuf = buf + contentOffset;
            NSUInteger setLen = contentLen;
            NSUInteger so = 0;
            while (so < setLen) {
                uint8_t t2;
                NSUInteger c2 = 0, l2 = 0;
                NSUInteger n2 = so;
                if (!WFCCDERReadTLV(setBuf, setLen, &n2, &t2, &c2, &l2)) {
                    break;
                }
                if (t2 == 0x30) {
                    uint8_t t3;
                    NSUInteger c3 = 0, l3 = 0;
                    NSUInteger n3 = 0;
                    if (WFCCDERReadTLV(setBuf + c2, l2, &n3, &t3, &c3, &l3) && t3 == 0x06) {
                        NSString *oid = WFCCDEROIDString(setBuf + c2 + c3, l3);
                        if ([oid isEqualToString:@"2.5.4.3"]) {
                            uint8_t t4;
                            NSUInteger c4 = 0, l4 = 0;
                            NSUInteger n4 = n3;
                            if (WFCCDERReadTLV(setBuf + c2, l2, &n4, &t4, &c4, &l4)) {
                                NSString *value = [[NSString alloc] initWithBytes:setBuf + c2 + c4 length:l4 encoding:NSUTF8StringEncoding];
                                if (!value.length) {
                                    value = [[NSString alloc] initWithBytes:setBuf + c2 + c4 length:l4 encoding:NSISOLatin1StringEncoding];
                                }
                                if (value.length && outCN) {
                                    *outCN = value;
                                }
                            }
                        }
                    }
                }
                so = n2;
            }
        }
        o = next;
    }
}

/// GeneralNames ::= SEQUENCE OF GeneralName，取 dNSName(0x82) 和 iPAddress(0x87)
static void WFCCDERParseGeneralNames(const uint8_t *buf, NSUInteger len,
                                     NSMutableArray<NSString *> *dnsNames,
                                     NSMutableArray<NSString *> *ipAddresses) {
    NSUInteger o = 0;
    while (o < len) {
        uint8_t tag;
        NSUInteger contentOffset = 0, contentLen = 0;
        NSUInteger next = o;
        if (!WFCCDERReadTLV(buf, len, &next, &tag, &contentOffset, &contentLen)) {
            break;
        }
        if (tag == 0x82) { // dNSName，implicit IA5String
            NSString *value = [[NSString alloc] initWithBytes:buf + contentOffset length:contentLen encoding:NSASCIIStringEncoding];
            if (value.length) {
                [dnsNames addObject:[value lowercaseString]];
            }
        } else if (tag == 0x87) { // iPAddress，implicit OCTET STRING
            NSString *value = WFCCIPString(buf + contentOffset, contentLen);
            if (value.length) {
                [ipAddresses addObject:value];
            }
        }
        o = next;
    }
}

/// Extensions ::= SEQUENCE OF Extension，找 subjectAltName(2.5.29.17)
static void WFCCDERParseExtensions(const uint8_t *buf, NSUInteger len,
                                   NSMutableArray<NSString *> *dnsNames,
                                   NSMutableArray<NSString *> *ipAddresses) {
    NSUInteger o = 0;
    while (o < len) {
        uint8_t tag;
        NSUInteger contentOffset = 0, contentLen = 0;
        NSUInteger next = o;
        if (!WFCCDERReadTLV(buf, len, &next, &tag, &contentOffset, &contentLen)) {
            break;
        }
        if (tag == 0x30) { // Extension
            const uint8_t *extBuf = buf + contentOffset;
            NSUInteger extLen = contentLen;
            uint8_t t;
            NSUInteger c = 0, l = 0;
            NSUInteger n = 0;
            NSString *oid = nil;
            if (WFCCDERReadTLV(extBuf, extLen, &n, &t, &c, &l) && t == 0x06) {
                oid = WFCCDEROIDString(extBuf + c, l);
            }
            if ([oid isEqualToString:@"2.5.29.17"]) {
                while (n < extLen) {
                    NSUInteger n2 = n;
                    if (!WFCCDERReadTLV(extBuf, extLen, &n2, &t, &c, &l)) {
                        break;
                    }
                    if (t == 0x04) { // extnValue OCTET STRING，内容是 DER 编码的 GeneralNames
                        const uint8_t *valueBuf = extBuf + c;
                        NSUInteger valueLen = l;
                        uint8_t gt;
                        NSUInteger gc = 0, gl = 0;
                        NSUInteger go = 0;
                        if (WFCCDERReadTLV(valueBuf, valueLen, &go, &gt, &gc, &gl) && gt == 0x30) {
                            WFCCDERParseGeneralNames(valueBuf + gc, gl, dnsNames, ipAddresses);
                        }
                        break;
                    }
                    n = n2;
                }
            }
        }
        o = next;
    }
}

static void WFCCDERParseCertificate(NSData *der,
                                    NSString **outCN,
                                    NSMutableArray<NSString *> *dnsNames,
                                    NSMutableArray<NSString *> *ipAddresses,
                                    NSDate **outNotBefore,
                                    NSDate **outNotAfter) {
    const uint8_t *buf = der.bytes;
    NSUInteger len = der.length;
    if (!buf || len == 0) {
        return;
    }
    // Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signatureValue }
    uint8_t tag;
    NSUInteger c = 0, l = 0;
    NSUInteger o = 0;
    if (!WFCCDERReadTLV(buf, len, &o, &tag, &c, &l) || tag != 0x30) {
        return;
    }
    const uint8_t *certBuf = buf + c;
    NSUInteger certLen = l;
    // tbsCertificate
    NSUInteger to = 0;
    if (!WFCCDERReadTLV(certBuf, certLen, &to, &tag, &c, &l) || tag != 0x30) {
        return;
    }
    const uint8_t *tbsBuf = certBuf + c;
    NSUInteger tbsLen = l;

    // tbs 子元素顺序：[0] version(可选), serial, signature, issuer, validity, subject, spki, [3] extensions
    NSUInteger index = 0;
    NSUInteger po = 0;
    while (po < tbsLen) {
        NSUInteger next = po;
        if (!WFCCDERReadTLV(tbsBuf, tbsLen, &next, &tag, &c, &l)) {
            break;
        }
        if (index == 0 && tag == 0xA0) {
            // version，不占用序号
            po = next;
            continue;
        }
        if (index == 3 && tag == 0x30) { // validity
            NSUInteger vo = 0;
            for (int i = 0; i < 2; i++) {
                uint8_t vt;
                NSUInteger vc = 0, vl = 0;
                NSUInteger vn = vo;
                if (!WFCCDERReadTLV(tbsBuf + c, l, &vn, &vt, &vc, &vl)) {
                    break;
                }
                NSDate *date = WFCCDERTime(tbsBuf + c + vc, vl, vt);
                if (i == 0) {
                    if (date && outNotBefore) *outNotBefore = date;
                } else {
                    if (date && outNotAfter) *outNotAfter = date;
                }
                vo = vn;
            }
        } else if (index == 4 && tag == 0x30) { // subject
            WFCCDERParseName(tbsBuf + c, l, outCN);
        } else if (index == 6 && tag == 0xA3) { // extensions [3]
            const uint8_t *extOuter = tbsBuf + c;
            NSUInteger extOuterLen = l;
            NSUInteger eo = 0;
            uint8_t et;
            NSUInteger ec = 0, el = 0;
            if (WFCCDERReadTLV(extOuter, extOuterLen, &eo, &et, &ec, &el) && et == 0x30) {
                WFCCDERParseExtensions(extOuter + ec, el, dnsNames, ipAddresses);
            }
        }
        index++;
        po = next;
    }
}

#pragma mark - 工具函数

static BOOL WFCCIsIPLiteral(NSString *host) {
    if (!host.length) {
        return NO;
    }
    struct in_addr addr4;
    struct in6_addr addr6;
    return inet_pton(AF_INET, host.UTF8String, &addr4) == 1 || inet_pton(AF_INET6, host.UTF8String, &addr6) == 1;
}

/// 域名匹配，支持 *.example.com 只匹配一层
static BOOL WFCCDNSMatches(NSString *pattern, NSString *host) {
    if (!pattern.length || !host.length) {
        return NO;
    }
    if ([pattern hasPrefix:@"*."]) {
        NSString *suffix = [pattern substringFromIndex:1]; // ".example.com"
        if (![host hasSuffix:suffix] || host.length <= suffix.length) {
            return NO;
        }
        NSString *prefix = [host substringToIndex:host.length - suffix.length];
        return prefix.length > 0 && [prefix rangeOfString:@"."].location == NSNotFound;
    }
    return [pattern isEqualToString:host];
}

static NSString *WFCCNormalizeHost(NSString *host) {    if (!host.length) {
        return nil;
    }
    NSString *result = [[host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    // 去掉可能的端口和 IPv6 字面量方括号
    if ([result hasPrefix:@"["]) {
        NSRange end = [result rangeOfString:@"]"];
        if (end.location != NSNotFound) {
            result = [result substringWithRange:NSMakeRange(1, end.location - 1)];
        }
    } else {
        NSRange colon = [result rangeOfString:@":"];
        if (colon.location != NSNotFound && [result componentsSeparatedByString:@":"].count == 2) {
            result = [result substringToIndex:colon.location];
        }
    }
    if ([result hasSuffix:@"."]) {
        result = [result substringToIndex:result.length - 1];
    }
    return result;
}

/// 兼容低版本系统的信任评估
static BOOL WFCCEvaluateTrust(SecTrustRef trust, CFErrorRef *error) {
    if (@available(iOS 12.0, macOS 10.14, *)) {
        return SecTrustEvaluateWithError(trust, error);
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SecTrustResultType result = kSecTrustResultInvalid;
    OSStatus status = SecTrustEvaluate(trust, &result);
#pragma clang diagnostic pop
    if (status != errSecSuccess) {
        return NO;
    }
    return result == kSecTrustResultProceed || result == kSecTrustResultUnspecified;
}

/// 提取信任对象里的证书链（leaf 在首位）
static NSArray<NSData *> *WFCCCertificateChainFromTrust(SecTrustRef trust) {
    NSMutableArray<NSData *> *chain = [NSMutableArray array];
    if (!trust) {
        return chain;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFIndex count = SecTrustGetCertificateCount(trust);
    for (CFIndex i = 0; i < count; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, i);
        if (!certificate) {
            continue;
        }
        CFDataRef data = SecCertificateCopyData(certificate);
        if (data) {
            [chain addObject:(__bridge_transfer NSData *)data];
        }
    }
#pragma clang diagnostic pop
    return chain;
}

#pragma mark - WFCCCertificate

@interface WFCCCertificate ()
@property (nonatomic, copy, readwrite) NSData *derData;
@property (nonatomic, copy, readwrite, nullable) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *subject;
@property (nonatomic, copy, readwrite, nullable) NSString *commonName;
@property (nonatomic, copy, readwrite) NSString *sha256Fingerprint;
@property (nonatomic, strong, readwrite, nullable) NSDate *notBefore;
@property (nonatomic, strong, readwrite, nullable) NSDate *notAfter;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *dnsNames;
@property (nonatomic, copy, readwrite) NSArray<NSString *> *ipAddresses;
/// +1 持有，dealloc 时释放
@property (nonatomic, assign) SecCertificateRef secCertificate;
- (instancetype)initWithDERData:(NSData *)derData filePath:(nullable NSString *)filePath;
/// 返回 +1 的 SecCertificateRef
- (SecCertificateRef)createSecCertificate CF_RETURNS_RETAINED;
@end

@implementation WFCCCertificate

- (instancetype)initWithDERData:(NSData *)derData filePath:(nullable NSString *)filePath {
    self = [super init];
    if (self) {
        _derData = [derData copy];
        _filePath = [filePath copy];
        _dnsNames = @[];
        _ipAddresses = @[];
        [self parse];
    }
    return self;
}

- (void)dealloc {
    if (_secCertificate) {
        CFRelease(_secCertificate);
        _secCertificate = NULL;
    }
}

- (void)parse {
    if (!_derData.length) {
        return;
    }
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)_derData);
    if (!cert) {
        return;
    }
    _secCertificate = cert;

    CFStringRef summary = SecCertificateCopySubjectSummary(cert);
    if (summary) {
        _subject = [(__bridge_transfer NSString *)summary copy] ?: @"";
    }
    if (!_subject.length) {
        _subject = @"";
    }

    // SHA-256 指纹
    unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(_derData.bytes, (CC_LONG)_derData.length, digest);
    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 3];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        if (i > 0) {
            [fingerprint appendString:@":"];
        }
        [fingerprint appendFormat:@"%02X", digest[i]];
    }
    _sha256Fingerprint = fingerprint;

    // SAN / CN / 有效期（自解析，失败只影响诊断信息）
    NSMutableArray<NSString *> *dnsNames = [NSMutableArray array];
    NSMutableArray<NSString *> *ipAddresses = [NSMutableArray array];
    NSString *commonName = nil;
    NSDate *notBefore = nil;
    NSDate *notAfter = nil;
    WFCCDERParseCertificate(_derData, &commonName, dnsNames, ipAddresses, &notBefore, &notAfter);
    _dnsNames = [dnsNames copy];
    _ipAddresses = [ipAddresses copy];
    _commonName = commonName;
    _notBefore = notBefore;
    _notAfter = notAfter;
}

/// 返回 +1 的 SecCertificateRef（优先复用已解析的）
- (SecCertificateRef)createSecCertificate CF_RETURNS_RETAINED {
    if (_secCertificate) {
        return (SecCertificateRef)CFRetain(_secCertificate);
    }
    return SecCertificateCreateWithData(NULL, (__bridge CFDataRef)_derData);
}

- (BOOL)expired {
    if (!_notAfter) {
        return NO;
    }
    return [_notAfter timeIntervalSinceNow] < 0;
}

- (BOOL)matchesHost:(NSString *)host {
    NSString *normalized = WFCCNormalizeHost(host);
    if (!normalized.length) {
        return NO;
    }
    if (WFCCIsIPLiteral(normalized)) {
        for (NSString *ip in _ipAddresses) {
            if ([WFCCNormalizeHost(ip) isEqualToString:normalized]) {
                return YES;
            }
        }
        return NO;
    }
    for (NSString *dns in _dnsNames) {
        if (WFCCDNSMatches(dns, normalized)) {
            return YES;
        }
    }
    // 没有 dNSName SAN 时按 CN 兜底（和浏览器行为一致）
    if (_dnsNames.count == 0 && _commonName.length) {
        return WFCCDNSMatches([_commonName lowercaseString], normalized);
    }
    return NO;
}

- (NSString *)summary {
    NSMutableArray<NSString *> *identities = [NSMutableArray array];
    for (NSString *dns in _dnsNames) {
        [identities addObject:[NSString stringWithFormat:@"DNS:%@", dns]];
    }
    for (NSString *ip in _ipAddresses) {
        [identities addObject:[NSString stringWithFormat:@"IP:%@", ip]];
    }
    NSString *identityText = identities.count ? [identities componentsJoinedByString:@", "] : @"(无 SAN)";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    NSString *validity = _notAfter ? [formatter stringFromDate:_notAfter] : @"未知";
    return [NSString stringWithFormat:@"CN=%@ 指纹=%@ SAN=[%@] 有效期至=%@%@",
            _commonName.length ? _commonName : _subject, _sha256Fingerprint, identityText, validity,
            self.expired ? @"（已过期）" : @""];
}

@end

#pragma mark - WFCCCertificateManager

@interface WFCCCertificateManager ()
@property (nonatomic, strong) NSMutableArray<WFCCCertificate *> *mutableCertificates;
/// 缓存 SecCertificateRef 数组（NSArray of __bridge_transfer id）
@property (nonatomic, strong, nullable) NSArray *pinnedSecCertificates;
+ (NSArray<NSData *> *)derListFromData:(NSData *)data;
- (NSArray<WFCCCertificate *> *)addCertificateDataInternal:(NSData *)data filePath:(nullable NSString *)filePath;
@end

@implementation WFCCCertificateManager

+ (instancetype)sharedManager {
    static WFCCCertificateManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WFCCCertificateManager alloc] init];
    });
    return manager;
}

+ (void)load {
    // 启动时自动遍历主 bundle 根目录下的所有证书。
    // App 里 main bundle 是 App，ShareExtension 里是 Extension，各自加载自己 bundle 内的证书。
    [[self sharedManager] loadCertificatesFromBundle:[NSBundle mainBundle]];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableCertificates = [NSMutableArray array];
        _enabled = YES;
        _trustMode = WFCCCertTrustModeSystemThenPin;
        _policyMode = WFCCCertPolicyModePermissive;
        _verboseLog = YES;
    }
    return self;
}

#pragma mark 配置

- (void)setTrustMode:(WFCCCertTrustMode)trustMode {
    _trustMode = trustMode;
    [self invalidatePinnedCertificates];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (_verboseLog) {
        NSLog(@"[WFCCCert] %@", enabled ? @"已启用自签证书信任" : @"已关闭自签证书信任");
    }
}

#pragma mark 加载证书

- (NSArray<WFCCCertificate *> *)loadCertificatesFromBundle:(NSBundle *)bundle {
    NSString *resourcePath = bundle.resourcePath;
    if (!resourcePath.length) {
        return @[];
    }
    return [self loadCertificatesFromDirectory:resourcePath recursive:NO];
}

- (NSArray<WFCCCertificate *> *)loadCertificatesFromDirectory:(NSString *)directory recursive:(BOOL)recursive {
    if (!directory.length) {
        return @[];
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    if (recursive) {
        NSDirectoryEnumerator<NSString *> *enumerator = [fileManager enumeratorAtPath:directory];
        for (NSString *relative in enumerator) {
            [files addObject:[directory stringByAppendingPathComponent:relative]];
        }
    } else {
        NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directory error:nil];
        for (NSString *name in contents) {
            [files addObject:[directory stringByAppendingPathComponent:name]];
        }
    }

    NSMutableArray<WFCCCertificate *> *added = [NSMutableArray array];
    NSArray<NSString *> *extensions = WFCCCertificateFileExtensions();
    for (NSString *path in files) {
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:path isDirectory:&isDirectory] || isDirectory) {
            continue;
        }
        NSString *extension = path.pathExtension.lowercaseString;
        if (![extensions containsObject:extension]) {
            continue;
        }
        [added addObjectsFromArray:[self addCertificateFile:path]];
    }
    return added;
}

- (NSArray<WFCCCertificate *> *)addCertificateFile:(NSString *)filePath {
    if (!filePath.length) {
        return @[];
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data.length) {
        if (_verboseLog) {
            NSLog(@"[WFCCCert] 读取证书文件失败: %@", filePath);
        }
        return @[];
    }
    return [self addCertificateDataInternal:data filePath:filePath];
}

- (nullable WFCCCertificate *)addCertificateData:(NSData *)data {
    NSArray<WFCCCertificate *> *added = [self addCertificateDataInternal:data filePath:nil];
    return added.firstObject;
}

- (NSArray<WFCCCertificate *> *)addCertificateDataInternal:(NSData *)data filePath:(nullable NSString *)filePath {
    NSArray<NSData *> *derList = [WFCCCertificateManager derListFromData:data];
    if (!derList.count && data.length) {
        // 不是 PEM，按 DER 处理
        derList = @[data];
    }
    NSMutableArray<WFCCCertificate *> *added = [NSMutableArray array];
    for (NSData *der in derList) {
        WFCCCertificate *certificate = [[WFCCCertificate alloc] initWithDERData:der filePath:filePath];
        if (!certificate.sha256Fingerprint.length) {
            continue;
        }
        @synchronized (self) {
            BOOL exists = NO;
            for (WFCCCertificate *existing in self.mutableCertificates) {
                if ([existing.sha256Fingerprint isEqualToString:certificate.sha256Fingerprint]) {
                    exists = YES;
                    break;
                }
            }
            if (exists) {
                continue;
            }
            [self.mutableCertificates addObject:certificate];
        }
        [added addObject:certificate];
        if (_verboseLog) {
            NSLog(@"[WFCCCert] 已加载证书: %@ (%@)", certificate.summary, filePath ?: @"<内存>");
        }
    }
    if (added.count) {
        [self invalidatePinnedCertificates];
    }
    return added;
}

- (void)removeAllCertificates {
    @synchronized (self) {
        [self.mutableCertificates removeAllObjects];
    }
    [self invalidatePinnedCertificates];
}

- (NSArray<WFCCCertificate *> *)certificates {
    @synchronized (self) {
        return [self.mutableCertificates copy];
    }
}

- (NSArray<NSString *> *)certificateFilePaths {
    NSMutableOrderedSet<NSString *> *paths = [NSMutableOrderedSet orderedSet];
    for (WFCCCertificate *certificate in self.certificates) {
        if (certificate.filePath.length) {
            [paths addObject:certificate.filePath];
        }
    }
    return paths.array;
}

- (NSArray<NSString *> *)materializeCertificateFilesToDirectory:(NSString *)directory {
    if (!directory.length) {
        return @[];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (WFCCCertificate *certificate in self.certificates) {
        if (certificate.filePath.length) {
            [paths addObject:certificate.filePath];
            continue;
        }
        NSString *name = [NSString stringWithFormat:@"wfc_cert_%@.der",
                          [certificate.sha256Fingerprint stringByReplacingOccurrencesOfString:@":" withString:@""]];
        NSString *path = [directory stringByAppendingPathComponent:name];
        if ([certificate.derData writeToFile:path atomically:YES]) {
            [paths addObject:path];
        }
    }
    return paths;
}

/// 从数据里提取所有 DER 证书：有 PEM 标记就按块解码，否则原样返回
+ (NSArray<NSData *> *)derListFromData:(NSData *)data {
    NSString *text = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    if (!text.length) {
        text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if (![text containsString:@"-----BEGIN "]) {
        return @[];
    }
    NSMutableArray<NSData *> *result = [NSMutableArray array];
    NSArray<NSString *> *lines = [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *base64 = nil;
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimmed hasPrefix:@"-----BEGIN "] && [trimmed hasSuffix:@"-----"]) {
            base64 = [NSMutableString string];
        } else if ([trimmed hasPrefix:@"-----END "] && base64) {
            NSData *der = [[NSData alloc] initWithBase64EncodedString:base64
                                                             options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (der.length) {
                [result addObject:der];
            }
            base64 = nil;
        } else if (base64) {
            [base64 appendString:trimmed];
        }
    }
    return result;
}

#pragma mark 信任评估

- (void)invalidatePinnedCertificates {
    @synchronized (self) {
        self.pinnedSecCertificates = nil;
    }
}

- (NSArray *)pinnedSecCertificates {
    @synchronized (self) {
        // 注意：这里必须用实例变量，用 self.pinnedSecCertificates 会递归调用本方法
        if (_pinnedSecCertificates) {
            return _pinnedSecCertificates;
        }
        NSMutableArray *array = [NSMutableArray array];
        for (WFCCCertificate *certificate in self.mutableCertificates) {
            SecCertificateRef ref = [certificate createSecCertificate];
            if (ref) {
                [array addObject:(__bridge_transfer id)ref];
            }
        }
        _pinnedSecCertificates = array;
        return array;
    }
}

/**
 * 宽松模式：SecPolicyCreateBasicX509 只校验证书链和有效期，
 * 主机绑定按服务端叶子证书的 SAN 自行完成。
 * 这样不满足 Apple TLS 策略（825 天有效期上限、serverAuth EKU）的自签证书也能用。
 */
- (BOOL)evaluatePermissiveTrust:(SecTrustRef)trust host:(nullable NSString *)host {
    NSArray<NSData *> *chain = WFCCCertificateChainFromTrust(trust);
    if (chain.count == 0) {
        if (_verboseLog) {
            NSLog(@"[WFCCCert] 宽松模式：拿不到服务端证书链 host=%@", host ?: @"");
        }
        return NO;
    }

    // 1. 主机绑定：按叶子证书的 SAN 校验
    if (host.length) {
        WFCCCertificate *leaf = [[WFCCCertificate alloc] initWithDERData:chain.firstObject filePath:nil];
        if (![leaf matchesHost:host]) {
            if (_verboseLog) {
                NSLog(@"[WFCCCert] 宽松模式：叶子证书 SAN 与 host 不匹配 host=%@ 叶子{%@}\n%@",
                      host, leaf.summary, [self describeCertificatesForHost:host]);
            }
            return NO;
        }
    }

    // 2. 链校验：换成 BasicX509 策略（不再套用 TLS 证书的 825 天/EKU 要求），并用内置证书当锚点
    NSArray *pinned = [self pinnedSecCertificates];
    if (pinned.count == 0) {
        // 没有内置证书，交回系统按原有策略评估
        CFErrorRef systemError = NULL;
        BOOL systemOK = WFCCEvaluateTrust(trust, &systemError);
        if (systemError) {
            CFRelease(systemError);
        }
        return systemOK;
    }
    SecPolicyRef basicPolicy = SecPolicyCreateBasicX509();
    if (basicPolicy) {
        SecTrustSetPolicies(trust, basicPolicy);
        CFRelease(basicPolicy);
    }
    OSStatus status = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)pinned);
    if (status != errSecSuccess) {
        if (_verboseLog) {
            NSLog(@"[WFCCCert] SecTrustSetAnchorCertificates 失败: %d", (int)status);
        }
        return NO;
    }
    SecTrustSetAnchorCertificatesOnly(trust, self.trustMode == WFCCCertTrustModePinOnly);
    CFErrorRef error = NULL;
    BOOL ok = WFCCEvaluateTrust(trust, &error);
    if (_verboseLog) {
        if (ok) {
            NSLog(@"[WFCCCert] 宽松模式通过 host=%@", host ?: @"");
        } else {
            NSLog(@"[WFCCCert] 宽松模式失败 host=%@ error=%@\n%@", host ?: @"", (__bridge NSError *)error, [self describeCertificatesForHost:host]);
        }
    }
    if (error) {
        CFRelease(error);
    }
    return ok;
}

/// 两段式评估：先系统信任库，失败再按 trustMode 用内置证书当锚点
- (BOOL)evaluateTrustInternal:(SecTrustRef)trust host:(nullable NSString *)host {
    if (!trust) {
        return NO;
    }
    if (self.enabled && self.policyMode == WFCCCertPolicyModePermissive) {
        return [self evaluatePermissiveTrust:trust host:host];
    }
    CFErrorRef systemError = NULL;
    BOOL systemOK = NO;
    if (self.trustMode != WFCCCertTrustModePinOnly) {
        systemOK = WFCCEvaluateTrust(trust, &systemError);
    }
    if (systemError) {
        if (_verboseLog && !systemOK) {
            NSLog(@"[WFCCCert] 系统信任评估失败 host=%@ error=%@", host ?: @"", (__bridge NSError *)systemError);
        }
        CFRelease(systemError);
    }
    if (systemOK) {
        return YES;
    }
    if (!self.enabled) {
        return NO;
    }
    NSArray *pinned = [self pinnedSecCertificates];
    if (pinned.count == 0) {
        return NO;
    }
    OSStatus status = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)pinned);
    if (status != errSecSuccess) {
        if (_verboseLog) {
            NSLog(@"[WFCCCert] SecTrustSetAnchorCertificates 失败: %d", (int)status);
        }
        return NO;
    }
    BOOL anchorsOnly = (self.trustMode == WFCCCertTrustModePinOnly);
    SecTrustSetAnchorCertificatesOnly(trust, anchorsOnly);
    CFErrorRef pinnedError = NULL;
    BOOL pinnedOK = WFCCEvaluateTrust(trust, &pinnedError);
    if (_verboseLog) {
        if (pinnedOK) {
            NSLog(@"[WFCCCert] 内置证书信任通过 host=%@", host ?: @"");
        } else {
            NSLog(@"[WFCCCert] 内置证书信任失败 host=%@ error=%@\n%@", host ?: @"", (__bridge NSError *)pinnedError, [self describeCertificatesForHost:host]);
        }
    }
    if (pinnedError) {
        CFRelease(pinnedError);
    }
    return pinnedOK;
}

- (BOOL)evaluateServerTrust:(SecTrustRef)trust host:(nullable NSString *)host {
    return [self evaluateTrustInternal:trust host:host];
}

- (BOOL)evaluateCertificateChain:(NSArray<NSData *> *)derChain host:(nullable NSString *)host {
    if (!derChain.count) {
        return NO;
    }
    NSMutableArray *certs = [NSMutableArray arrayWithCapacity:derChain.count];
    for (NSData *der in derChain) {
        if (!der.length) {
            continue;
        }
        SecCertificateRef ref = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)der);
        if (ref) {
            [certs addObject:(__bridge_transfer id)ref];
        }
    }
    if (certs.count == 0) {
        return NO;
    }
    NSString *hostString = host.length ? host : nil;
    SecPolicyRef policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)hostString);
    if (!policy) {
        return NO;
    }
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates((__bridge CFArrayRef)certs, policy, &trust);
    CFRelease(policy);
    if (status != errSecSuccess || !trust) {
        return NO;
    }
    BOOL result = [self evaluateTrustInternal:trust host:host];
    CFRelease(trust);
    return result;
}

- (void)handleChallenge:(NSURLAuthenticationChallenge *)challenge
             completion:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completion {
    if (!completion) {
        return;
    }
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completion(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        return;
    }
    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    NSString *host = challenge.protectionSpace.host;
    if (trust && [self evaluateServerTrust:trust host:host]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
        completion(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        // 交回系统处理：系统信任库里有该证书时会通过，否则按原有的失败方式报错
        completion(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (NSURLSessionAuthChallengeDisposition (^)(NSURLSession *, NSURLAuthenticationChallenge *, NSURLCredential * _Nullable __autoreleasing * _Nullable))sessionChallengeBlock {
    __weak typeof(self) weakSelf = self;
    return ^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential *__autoreleasing *credential) {
        WFCCCertificateManager *manager = weakSelf ?: [WFCCCertificateManager sharedManager];
        __block NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        __block NSURLCredential *resultCredential = nil;
        [manager handleChallenge:challenge completion:^(NSURLSessionAuthChallengeDisposition d, NSURLCredential *c) {
            disposition = d;
            resultCredential = c;
        }];
        if (credential) {
            *credential = resultCredential;
        }
        return disposition;
    };
}

#pragma mark 诊断

- (NSString *)describeCertificatesForHost:(nullable NSString *)host {
    NSArray<WFCCCertificate *> *certs = self.certificates;
    NSMutableString *text = [NSMutableString string];
    NSString *normalizedHost = WFCCNormalizeHost(host);
    [text appendFormat:@"当前地址: %@\n", normalizedHost.length ? normalizedHost : @"(未提供)"];
    [text appendFormat:@"已加载证书 %lu 张，信任模式: %@，校验策略: %@，开关: %@\n",
     (unsigned long)certs.count,
     self.trustMode == WFCCCertTrustModePinOnly ? @"PinOnly" : @"SystemThenPin",
     self.policyMode == WFCCCertPolicyModeTLS ? @"TLS(严格)" : @"BasicX509(宽松)",
     self.enabled ? @"开" : @"关"];
    NSInteger index = 1;
    for (WFCCCertificate *certificate in certs) {
        NSString *match = @"-";
        if (normalizedHost.length) {
            match = [certificate matchesHost:normalizedHost] ? @"匹配" : @"不匹配";
        }
        [text appendFormat:@"  %ld) %@ host=%@\n", (long)index, certificate.summary, match];
        index++;
    }
    return text;
}

@end

#pragma mark - WFCCCertificateURLSessionDelegate

@interface WFCCCertificateURLSessionDelegate ()
@property (nonatomic, strong) WFCCCertificateManager *manager;
@end

@implementation WFCCCertificateURLSessionDelegate

+ (instancetype)delegateWithManager:(WFCCCertificateManager *)manager {
    WFCCCertificateURLSessionDelegate *delegate = [[WFCCCertificateURLSessionDelegate alloc] init];
    delegate.manager = manager ?: [WFCCCertificateManager sharedManager];
    return delegate;
}

- (void)URLSession:(NSURLSession *)session
              didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
                completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    [self.manager handleChallenge:challenge completion:completionHandler];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
              didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
                completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    [self.manager handleChallenge:challenge completion:completionHandler];
}

@end

#pragma mark - NSURLSession (WFCCCertificate)

@implementation NSURLSession (WFCCCertificate)

+ (NSURLSession *)wfc_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration
                                 delegateQueue:(NSOperationQueue *)queue {
    WFCCCertificateURLSessionDelegate *delegate = [WFCCCertificateURLSessionDelegate delegateWithManager:[WFCCCertificateManager sharedManager]];
    // NSURLSession 会强引用自己的 delegate，不需要额外持有
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration ?: [NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:delegate
                                                     delegateQueue:queue];
    return session;
}

+ (NSURLSession *)wfc_sessionWithConfiguration:(NSURLSessionConfiguration *)configuration {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    return [self wfc_sessionWithConfiguration:configuration delegateQueue:queue];
}

@end
