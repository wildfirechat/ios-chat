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
#import "ShareUtility.h"

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


- (void)sendLinkMessage:(SharedConversation *)conversation link:(NSString *)link title:(NSString *)title thumbnailLink:(NSString *)thumbnailLink success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    
    [dataDict setObject:link forKey:@"u"];
    if (thumbnailLink) {
        [dataDict setObject:thumbnailLink forKey:@"t"];
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                           options:kNilOptions
                                                                             error:nil];
    
    [self post:@"/messages/send"
          data:@{@"type":@(conversation.type),
                 @"target":conversation.target,
                 @"line":@(conversation.line),
                 @"content_type":@(8),
                 @"content_searchable":title,
                 @"content_binary":[data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]
          }
       success:successBlock
         error:errorBlock];
}

- (void)sendTextMessage:(SharedConversation *)conversation text:(NSString *)text success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/messages/send"
          data:@{@"type":@(conversation.type),
                 @"target":conversation.target,
                 @"line":@(conversation.line),
                 @"content_type":@(1),
                 @"content_searchable":text
          }
       success:successBlock
         error:errorBlock];
}

- (void)sendImageMessage:(SharedConversation *)conversation mediaUrl:(NSString *)mediaUrl thubnail:(UIImage *)thubnail success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    NSData *data = UIImageJPEGRepresentation(thubnail, 0.4);
    
    [self post:@"/messages/send"
          data:@{@"type":@(conversation.type),
                 @"target":conversation.target,
                 @"line":@(conversation.line),
                 @"content_type":@(3),
                 @"content_media_type":@(1),
                 @"content_remote_url":mediaUrl,
                 @"content_searchable":@"[图片]",
                 @"content_binary":[data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed]
          }
       success:successBlock
         error:errorBlock];
}

- (void)sendFileMessage:(SharedConversation *)conversation mediaUrl:(NSString *)mediaUrl fileName:(NSString *)fileName size:(long long)size success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    
    [self post:@"/messages/send"
          data:@{@"type":@(conversation.type),
                 @"target":conversation.target,
                 @"line":@(conversation.line),
                 @"content_type":@(5),
                 @"content_media_type":@(4),
                 @"content_remote_url":mediaUrl,
                 @"content_searchable":fileName,
                 @"content":[NSString stringWithFormat:@"%lld", size]
          }
       success:successBlock
         error:errorBlock];
}

- (void)uploadFiles:(NSString *)file
          mediaType:(int)mediaType
          fullImage:(BOOL)fullImage
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
              error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
        for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies]) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
        }
        
        NSString *url = [APP_SERVER_ADDRESS stringByAppendingFormat:@"/media/upload/%d", mediaType];
    
        [manager
         POST:url
         parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSString *fileName = [[NSURL URLWithString:file] lastPathComponent];

            if (mediaType == 1 && !fullImage) {
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:file]]];
                image = [ShareUtility generateThumbnail:image withWidth:1024 withHeight:1024];
                NSData *imgData = UIImageJPEGRepresentation(image, 0.85);
                
                [formData appendPartWithFileData:imgData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            } else {
                NSData *logData = [NSData dataWithContentsOfURL:[NSURL URLWithString:file]];
                if (!logData.length) {
                    logData = [@"empty" dataUsingEncoding:NSUTF8StringEncoding];
                }
                
                [formData appendPartWithFileData:logData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            }
        }
         progress:^(NSProgress * progress) {
            if (progressBlock) {
                progressBlock((int)progress.completedUnitCount, (int)progress.totalUnitCount);
            }
        }
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)responseObject;
                if([dict[@"code"] intValue] == 0) {
                    NSDictionary *result = dict[@"result"];
                    if (result && result[@"url"]) {
                        successBlock(result[@"url"]);
                        return;
                    }
                    
                }
            }
            errorBlock(@"服务器响应错误");
        }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"上传失败：%@", error);
            errorBlock(error.localizedFailureReason);
        }];
    });
}

- (void)post:(NSString *)path data:(id)data success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
    NSString *authToken = [sharedDefaults objectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    
#define AUTHORIZATION_HEADER @"authToken"
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies]) {
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
                      if(successBlock) successBlock(dict[@"result"]);
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

- (BOOL)isLogin {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];

    return [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookiesForURL:[NSURL URLWithString:APP_SERVER_ADDRESS]].count > 0 || [sharedDefaults objectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
}
@end
