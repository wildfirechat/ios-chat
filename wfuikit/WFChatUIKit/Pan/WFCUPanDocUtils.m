//
//  WFCUPanDocUtils.m
//  WFChatUIKit
//

#import "WFCUPanDocUtils.h"
#import "WFCUConfigManager.h"

@implementation WFCUPanDocUtils

+ (NSSet<NSString *> *)onlineDocExtensions {
    static NSSet *set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 与服务端 DocsService 的 WORD/CELL/SLIDE/PDF 组一致
        set = [NSSet setWithArray:@[
            // word
            @"doc", @"docx", @"docm", @"dot", @"dotx", @"dotm", @"odt", @"ott", @"rtf", @"txt",
            @"wps", @"wpt", @"fodt", @"mht", @"mhtml", @"htm", @"html", @"epub", @"fb2",
            // cell
            @"xls", @"xlsx", @"xlsm", @"xlt", @"xltx", @"xltm", @"xlsb", @"ods", @"ots", @"csv",
            @"et", @"ett", @"fods",
            // slide
            @"ppt", @"pptx", @"pptm", @"pot", @"potx", @"potm", @"pps", @"ppsx", @"ppsm", @"odp",
            @"otp", @"dps", @"dpt", @"fodp",
            // pdf
            @"pdf", @"djvu", @"xps", @"oxps"
        ]];
    });
    return set;
}

+ (BOOL)isOnlineDocName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    }
    NSString *ext = [[name pathExtension] lowercaseString];
    if (ext.length == 0) {
        return NO;
    }
    return [[self onlineDocExtensions] containsObject:ext];
}

+ (NSString *)panServerAddress {
    id<WFCUPanService> provider = [WFCUConfigManager globalManager].panServiceProvider;
    if (!provider) {
        return nil;
    }
    if ([provider respondsToSelector:@selector(panServerAddress)]) {
        return [provider panServerAddress];
    }
    return nil;
}

+ (BOOL)isPanConfigured {
    return [WFCUConfigManager isPanConfigured];
}

+ (NSString *)encodeQueryValue:(NSString *)value {
    if (value == nil) {
        return nil;
    }
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
                               @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

+ (NSString *)docBase {
    NSString *root = [self panServerAddress];
    if (root.length == 0) {
        return nil;
    }
    while ([root hasSuffix:@"/"]) {
        root = [root substringToIndex:root.length - 1];
    }
    return [root stringByAppendingString:@"/doc/"];
}

+ (BOOL)isDocUrl:(NSString *)url {
    NSString *base = [self docBase];
    if (base.length == 0 || url.length == 0) {
        return NO;
    }
    // base 形如 <root>/doc/，另接受不带斜杠的 <root>/doc
    return [url hasPrefix:base] || [url isEqualToString:[base substringToIndex:base.length - 1]];
}

+ (NSString *)docOpenUrl:(NSInteger)fileId {
    NSString *base = [self docBase];
    if (base.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@open?fileId=%ld&platform=mobile", base, (long)fileId];
}

+ (NSString *)docViewUrl:(NSString *)url name:(NSString *)name {
    NSString *base = [self docBase];
    if (base.length == 0 || url.length == 0) {
        return nil;
    }
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@open?url=%@&platform=mobile", base, [self encodeQueryValue:url]];
    if (name.length) {
        [result appendFormat:@"&name=%@", [self encodeQueryValue:name]];
    }
    return result;
}

+ (NSString *)licensesUrl {
    NSString *base = [self docBase];
    if (base.length == 0) {
        return nil;
    }
    return [base stringByAppendingString:@"licenses.html"];
}

@end
