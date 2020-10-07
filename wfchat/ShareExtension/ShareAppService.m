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
    
}

- (void)post:(NSString *)path data:(id)data success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSString *message))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
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

@end
