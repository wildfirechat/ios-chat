//
//  WFRedirector.m
//  WildFireChat
//
//  Created by Rain on 14/3/2025.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFRedirector.h"
#import "WFCConfig.h"

@implementation WFRedirector

/*
 问：为什么要引入这个URL重定向器？
 答：野火有双网模式，各种客户端可以在单位内网和外网使用，头像及媒体类消息中的链接，有可能是内网中的，也有可能是外网中的。当在另外一张网使用时，就需要做地址转换，使用这个类进行转换。
 
 问：什么样的客户需要使用？
 答：使用双网的客户。
 
 问：如何实现转换？
 答：实现这WFCCUrlRedirector这个协议以后，设置到WFCCNetworkService实例中。SDK当从协议栈读取到头像或者媒体类消息时，会把链接调用此对象进行转换。
 
 问：实现这个转换器，如何判断当前在那个网络？
 答：WFCCNetworkService有个方法connectedToMainNetwork，可以判断当前使用的是主网还是备网。再把URL转到对应的地址去。前提是需要连上IM。如果在连上IM服务之前使用将不准确。
 
 问：这个转换器可以直接使用吗？
 答：可以直接使用，本项目已将主备媒体地址前缀抽取到 WFCConfig.h 的 MAIN_MEDIA_URL_PREFIX / BACKUP_MEDIA_URL_PREFIX，可直接修改配置使用。也可以根据客户的实际情况来完成这个redirect方法。
 */
- (NSString *)redirect:(NSString *)originalUrl {
    if (!MAIN_MEDIA_URL_PREFIX.length || !BACKUP_MEDIA_URL_PREFIX.length) {
        return originalUrl;
    }
    
    if ([WFCCNetworkService sharedInstance].connectedToMainNetwork) {
        // 主网下，把备网地址前缀替换成主网的。
        return [originalUrl stringByReplacingOccurrencesOfString:BACKUP_MEDIA_URL_PREFIX withString:MAIN_MEDIA_URL_PREFIX];
    } else {
        // 备网下，把主网地址前缀替换成备网的。
        return [originalUrl stringByReplacingOccurrencesOfString:MAIN_MEDIA_URL_PREFIX withString:BACKUP_MEDIA_URL_PREFIX];
    }
}
@end
