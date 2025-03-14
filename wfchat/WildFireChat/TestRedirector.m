//
//  TestRedirector.m
//  WildFireChat
//
//  Created by Rain on 14/3/2025.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "TestRedirector.h"

@implementation TestRedirector

/*
 问：为什么要引入这个URL重定向器？
 答：野火有双网模式，各种客户端可以在单位内网和外网使用，头像及媒体类消息中的链接，有可能是内网中的，也有可能是外网中的。当在另外一张网使用时，就需要做地址转换，使用这个类进行转换。
 
 问：什么样的客户需要使用？
 答：使用双网的客户。
 
 问：如何实现转换？
 答：实现这WFCCUrlRedirector这个协议以后，设置到WFCCNetworkService实例中。SDK当从协议栈读取到头像或者媒体类消息时，会把链接调用此对象进行转换。
 
 问：实现这个转换器，如何判断当前在那个网络？
 答：WFCCNetworkService有个方法connectedToMainNetwork，可以判断当前使用的是主网还是备网。再把URL转到对应的地址去。
 
 问：这个转换器可以直接使用吗？
 答：不能，这个转换器是个示例，需要根据客户的实际情况来完成这个redirect方法。
 */
- (NSString *)redirect:(NSString *)originalUrl {
    /*
    //主网媒体地址前缀和备网媒体地址前缀
    NSString *mainNWUrlPrefix = @"https://main.network.url/";
    NSString *backupNWUrlPrefix = @"https://10.11.0.15/";
     
    //判断当前是那个网络，再进行替换。
    if ([WFCCNetworkService sharedInstance].connectedToMainNetwork) {
        //主网下，把备网的地址替换成主网的。
        return [originalUrl stringByReplacingOccurrencesOfString:backupNWUrlPrefix withString:mainNWUrlPrefix];
    } else {
        //备网下，把主网的地址替换成备网的。
        return [originalUrl stringByReplacingOccurrencesOfString:mainNWUrlPrefix withString:backupNWUrlPrefix];
    }
     */
    return originalUrl;
}
@end
