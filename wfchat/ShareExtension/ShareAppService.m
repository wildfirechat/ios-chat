//
//  ShareAppService.m
//  ShareExtension
//
//  Created by Tom Lee on 2020/10/7.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "ShareAppService.h"
#import "AFNetworking.h"
#import "WFCConfig.h"
#import "SharePredefine.h"


static ShareAppService *sharedSingleton = nil;

@implementation ShareAppService
+ (ShareAppService *)sharedAppService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[ShareAppService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)sendTextMessage:(NSString *)phoneNumber success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/send_code" data:@{@"mobile":phoneNumber} success:successBlock error:errorBlock];
}

- (void)sendLinkMessage:(NSString *)phoneNumber success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/send_code" data:@{@"mobile":phoneNumber} success:successBlock error:errorBlock];
}

- (void)sendImageMessage:(NSString *)phoneNumber success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/send_code" data:@{@"mobile":phoneNumber} success:successBlock error:errorBlock];
}


- (void)post:(NSString *)path data:(id)data success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSData *cookiesdata = [self getAppServiceCookies];//url和登陆时传的url 是同一个
    if([cookiesdata length]) {
        NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
        NSHTTPCookie *cookie;
        for (cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
    }
    
    [manager POST:[APP_SERVER_ADDRESS stringByAppendingPathComponent:path]
       parameters:data
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
              NSDictionary *dict = responseObject;
              dispatch_async(dispatch_get_main_queue(), ^{
                  successBlock(dict);
                  if([dict[@"code"] intValue] == 0) {
                      if(successBlock) successBlock(dict);
                  } else {
                      if(errorBlock) errorBlock(@"error");
                  }
              });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                errorBlock(error.localizedDescription);
            });
          }];
}

- (NSData *)getAppServiceCookies {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    return [sharedDefaults objectForKey:WFC_SHARE_BACKUPED_APP_SERVER_COOKIES];
    
}
@end
