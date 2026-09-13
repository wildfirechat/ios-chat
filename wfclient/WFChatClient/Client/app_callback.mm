//
//  app_callback.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#include "app_callback.h"

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import <Security/Security.h>
#import "WFCCUtilities.h"
#import "WFCCCertificateManager.h"
#import "sys/utsname.h"
#import "WFCCNetworkService.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

namespace mars {
    namespace app {

AppCallBack* AppCallBack::instance_ = NULL;

AppCallBack* AppCallBack::Instance() {
    if(instance_ == NULL) {
        instance_ = new AppCallBack();
    }
    
    return instance_;
}

void AppCallBack::Release() {
    delete instance_;
    instance_ = NULL;
}
        
    AppCallBack::AppCallBack() {
        
        
    }

        
        void AppCallBack::SetAccountUserName(const std::string &userName) {
            info.username = userName;
            
            NSString *path = [WFCCUtilities getDocumentPathWithComponent:[NSString stringWithUTF8String:info.username.c_str()]];
            filePath = [path UTF8String];
        }
        
        bool AppCallBack::isDBAlreadyCreated(const std::string &clientId) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                 NSUserDomainMask, YES);
            NSString *documentDirectory = [paths objectAtIndex:0];
            NSFileManager *myFileManager = [NSFileManager defaultManager];
            NSString *cid = [NSString stringWithUTF8String:clientId.c_str()];
            BOOL isDir = NO;
            BOOL isExist = NO;
            for (NSString *path in [myFileManager contentsOfDirectoryAtPath:documentDirectory error:nil]) {
                        
                NSString *dbPath = [[[documentDirectory stringByAppendingPathComponent:path] stringByAppendingPathComponent:cid] stringByAppendingPathComponent:@"data"];;
                        
                isExist = [myFileManager fileExistsAtPath:dbPath isDirectory:&isDir];
                if(isExist && !isDir) {
                    return true;
                }
            }
            return false;
        }
    
        void AppCallBack::SetAccountLogoned(bool isLogoned) {
            info.is_logoned = isLogoned;
        }
        
// return your app path
std::string AppCallBack::GetAppFilePath(){
    return filePath;
}
        
AccountInfo AppCallBack::GetAccountInfo() {
    return info;
}

unsigned int AppCallBack::GetClientVersion() {
    
    return 0;
}

static BOOL PSPDFIsDevelopmentBuild() {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL isDevelopment = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // There is no provisioning profile in AppStore Apps.
        NSData *data = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"embedded" ofType:@"mobileprovision"]];
        if (data) {
            const char *bytes = (const char *)[data bytes];
            NSMutableString *profile = [[NSMutableString alloc] initWithCapacity:data.length];
            for (NSUInteger i = 0; i < data.length; i++) {
                [profile appendFormat:@"%c", bytes[i]];
            }
            // Look for debug value, if detected we're a development build.
            NSString *cleared = [[profile componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] componentsJoinedByString:@""];
            isDevelopment = [cleared rangeOfString:@"<key>get-task-allow</key><true/>"].length > 0;
        }
    });
    return isDevelopment;
#endif
}
        
int AppCallBack::GetPushType() {
    return PSPDFIsDevelopmentBuild() ? 1 : 0;
}
        
DeviceInfo AppCallBack::GetDeviceInfo() {
    DeviceInfo info;
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    
    info.clientid = [[[WFCCNetworkService sharedInstance] getClientId] UTF8String];
    info.platform = [WFCCNetworkService sharedInstance].isPad?PlatformType_iPad:PlatformType_iOS;    
    info.packagename = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"] UTF8String];
    info.pushtype = mars::app::AppCallBack::Instance()->GetPushType();
    info.device = [deviceString UTF8String];
    info.deviceversion = [[UIDevice currentDevice].systemVersion UTF8String];
    info.phonename = [[UIDevice currentDevice].name UTF8String];
    
    NSArray *languages = [NSLocale preferredLanguages];
    NSString *currentLanguage = [languages objectAtIndex:0];
    info.language = [currentLanguage UTF8String];
    
    CTTelephonyNetworkInfo *nwinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = nwinfo.subscriberCellularProvider;
    info.carriername = carrier.carrierName ? [carrier.carrierName UTF8String] : "";
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if (appVersion) {
        info.appversion = [appVersion UTF8String];
    }
    
    info.sdkversion = [SDKVERSION UTF8String];
    
    return info;
}

void AppCallBack::GetRootCerts(std::vector<std::string> &certs) {
    certs.clear();
    
#if TARGET_OS_OSX
    // macOS：Security.framework 可以枚举系统锚点证书
    CFArrayRef anchors = NULL;
    OSStatus status = SecTrustCopyAnchorCertificates(&anchors);
    if (status == errSecSuccess && anchors != NULL) {
        CFIndex count = CFArrayGetCount(anchors);
        for (CFIndex i = 0; i < count; ++i) {
            SecCertificateRef cert = (SecCertificateRef)CFArrayGetValueAtIndex(anchors, i);
            CFDataRef der = SecCertificateCopyData(cert);
            if (der != NULL) {
                certs.push_back(std::string((const char *)CFDataGetBytePtr(der), (size_t)CFDataGetLength(der)));
                CFRelease(der);
            }
        }
        CFRelease(anchors);
    }
    NSLog(@"[WFC] GetRootCerts(macOS) anchors=%lu, status=%d", (unsigned long)certs.size(), (int)status);
#else
    // iOS：SecTrustCopyAnchorCertificates 在 iOS 上不可用（头文件标记 __IPHONE_NA，符号未导出），
    // 系统没有公开 API 能枚举根证书，因此改为读取 App Bundle 内置的 CA 文件。
    // 使用方式：把 cacert.pem（可含多张 PEM 证书）加入 App 的 Copy Bundle Resources。
    // 私有化部署也可以不内置，直接通过 useTls(false, {服务端证书}) 传入证书。
    NSArray<NSString *> *candidates = @[@"cacert", @"ca-bundle", @"ca", @"rootca"];
    for (NSString *name in candidates) {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"pem"];
        if (path.length == 0) {
            path = [[NSBundle mainBundle] pathForResource:name ofType:@"crt"];
        }
        if (path.length == 0) {
            continue;
        }
        NSData *data = [NSData dataWithContentsOfFile:path];
        if (data.length == 0) {
            continue;
        }
        certs.push_back(std::string((const char *)data.bytes, (size_t)data.length));
        NSLog(@"[WFC] GetRootCerts(iOS) loaded bundled CA:%@ size=%lu", path, (unsigned long)data.length);
        break;
    }
    if (certs.empty()) {
        NSLog(@"[WFC] GetRootCerts(iOS) no bundled CA found; TLS cert verification will be skipped unless useTls passes a cert");
    }
#endif
    // 由 WFCCCertificateManager 统一加载的内置证书（bundle 根目录下的 .cer/.crt/.pem/.der）也作为根证书
    for (WFCCCertificate *certificate in [WFCCCertificateManager sharedManager].certificates) {
        if (certificate.derData.length) {
            certs.push_back(std::string((const char *)certificate.derData.bytes, (size_t)certificate.derData.length));
        }
    }
}

bool AppCallBack::CanVerifyServerCerts() {
    // iOS/macOS 的 Security.framework 都能直接校验证书链（系统根 + 用户信任的 CA + 域名）
    NSLog(@"[WFC] CanVerifyServerCerts -> true");
    return true;
}

int AppCallBack::VerifyServerCerts(const std::vector<std::string> &derChain, const std::string &host) {
    if (derChain.empty()) {
        return -1;
    }
    
    // 组装证书链（leaf 在首位）
    NSMutableArray *certs = [NSMutableArray array];
    for (const auto &der : derChain) {
        if (der.empty()) {
            continue;
        }
        NSData *data = [NSData dataWithBytes:der.data() length:der.size()];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
        if (cert) {
            [certs addObject:(__bridge_transfer id)cert];
        }
    }
    if (certs.count == 0) {
        NSLog(@"[WFC] VerifyServerCerts no valid cert parsed");
        return -1;
    }
    
    // 带上域名策略，让系统一并做域名校验
    NSString *hostStr = host.empty() ? nil : [NSString stringWithUTF8String:host.c_str()];
    SecPolicyRef policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)hostStr);
    if (!policy) {
        return -1;
    }
    
    SecTrustRef trust = NULL;
    OSStatus status = SecTrustCreateWithCertificates((__bridge CFArrayRef)certs, policy, &trust);
    if (status != errSecSuccess || !trust) {
        CFRelease(policy);
        NSLog(@"[WFC] VerifyServerCerts create trust failed:%d host:%@", (int)status, hostStr);
        return -1;
    }
    
    int result = -1;
    if (@available(iOS 12.0, macOS 10.14, *)) {
        CFErrorRef error = NULL;
        BOOL ok = SecTrustEvaluateWithError(trust, &error);
        if (!ok && error) {
            NSLog(@"[WFC] VerifyServerCerts failed host:%@ error:%@", hostStr, error);
            CFRelease(error);
        }
        result = ok ? 1 : 0;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        SecTrustResultType trustResult = kSecTrustResultInvalid;
        OSStatus evalStatus = SecTrustEvaluate(trust, &trustResult);
        if (evalStatus == errSecSuccess) {
            result = (trustResult == kSecTrustResultProceed || trustResult == kSecTrustResultUnspecified) ? 1 : 0;
        }
#pragma clang diagnostic pop
    }
    
    CFRelease(trust);
    CFRelease(policy);
    
    // 系统信任库校验失败时，用内置的自签证书再校验一次（锚点 + 域名/IP SAN）
    if (result != 1) {
        NSMutableArray<NSData *> *derArray = [NSMutableArray array];
        for (const auto &der : derChain) {
            if (!der.empty()) {
                [derArray addObject:[NSData dataWithBytes:der.data() length:der.size()]];
            }
        }
        BOOL pinned = [[WFCCCertificateManager sharedManager] evaluateCertificateChain:derArray host:hostStr];
        if (pinned) {
            result = 1;
            NSLog(@"[WFC] VerifyServerCerts host:%@ 通过内置证书校验", hostStr);
        }
    }
    
    NSLog(@"[WFC] VerifyServerCerts host:%@ chain:%lu result:%d", hostStr, (unsigned long)derChain.size(), result);
    return result;
}

}}
