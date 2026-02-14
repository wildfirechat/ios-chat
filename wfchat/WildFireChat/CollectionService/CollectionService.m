//
//  CollectionService.m
//  WildFireChat
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "CollectionService.h"
#import "AFNetworking.h"
#import <WFChatUIKit/WFCUCollection.h>
#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCNetworkService.h>
#import "WFCConfig.h"

static CollectionService *sharedSingleton = nil;

@implementation CollectionService

+ (CollectionService *)sharedService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[CollectionService alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认基础 URL，可在 AppDelegate 中设置
        //_baseUrl = @"http://localhost:8081";
    }
    return self;
}

#pragma mark - WFCUCollectionService

- (void)createCollection:(NSString *)groupId
                   title:(NSString *)title
                    desc:(nullable NSString *)desc
                template:(nullable NSString *)template
              expireType:(int)expireType
                expireAt:(long)expireAt
         maxParticipants:(int)maxParticipants
                 success:(void(^)(WFCUCollection *collection))successBlock
                   error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/collections
    NSString *path = @"/api/collections";
    NSMutableDictionary *param = [@{
        @"groupId": groupId ?: @"",
        @"title": title ?: @"",
        @"expireType": @(expireType),
        @"maxParticipants": @(maxParticipants)
    } mutableCopy];

    if (desc.length) {
        param[@"description"] = desc;
    }
    if (template.length) {
        param[@"template"] = template;
    }
    if (expireType == 1 && expireAt > 0) {
        param[@"expireAt"] = @(expireAt);
    }

    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUCollection *collection = [WFCUCollection fromDictionary:dict[@"result"]];
            if(successBlock) successBlock(collection);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getCollection:(long)collectionId
              groupId:(NSString *)groupId
              success:(void(^)(WFCUCollection *collection))successBlock
                error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/collections/{collectionId}/detail
    NSString *path = [NSString stringWithFormat:@"/api/collections/%ld/detail", collectionId];
    NSDictionary *param = @{
        @"groupId": groupId ?: @""
    };

    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUCollection *collection = [WFCUCollection fromDictionary:dict[@"data"]];
            if(successBlock) successBlock(collection);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)joinOrUpdateCollection:(long)collectionId
                       groupId:(NSString *)groupId
                       content:(NSString *)content
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/collections/{collectionId}/join
    NSString *path = [NSString stringWithFormat:@"/api/collections/%ld/join", collectionId];
    NSDictionary *param = @{
        @"groupId": groupId ?: @"",
        @"content": content ?: @""
    };

    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)deleteCollectionEntry:(long)collectionId
                      groupId:(NSString *)groupId
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/collections/{collectionId}/delete
    NSString *path = [NSString stringWithFormat:@"/api/collections/%ld/delete", collectionId];
    NSDictionary *param = @{
        @"groupId": groupId ?: @""
    };

    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)closeCollection:(long)collectionId
                groupId:(NSString *)groupId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/collections/{collectionId}/close
    NSString *path = [NSString stringWithFormat:@"/api/collections/%ld/close", collectionId];
    NSDictionary *param = @{
        @"groupId": groupId ?: @""
    };

    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - HTTP Helper Methods

- (void)postWithAuth:(NSString *)path
                data:(nullable id)data
             success:(void(^)(NSDictionary *dict))successBlock
               error:(void(^)(NSError * _Nonnull error))errorBlock {
    // 异步获取 authCode
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        [self post:path data:data authCode:authCode success:successBlock error:errorBlock];
    } error:^(int error_code) {
        NSError *err = [NSError errorWithDomain:@"CollectionService" code:error_code userInfo:@{NSLocalizedDescriptionKey: @"Failed to get authCode"}];
        if(errorBlock) errorBlock(err);
    }];
}

- (void)post:(NSString *)path
        data:(nullable id)data
    authCode:(NSString *)authCode
     success:(void(^)(NSDictionary *dict))successBlock
       error:(void(^)(NSError * _Nonnull error))errorBlock {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];

    // 添加 authCode 到请求头
    if (authCode.length > 0) {
        [manager.requestSerializer setValue:authCode forHTTPHeaderField:@"authCode"];
    }

    NSString *url = [self.baseUrl stringByAppendingString:path];

    [manager POST:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                successBlock((NSDictionary *)responseObject);
            } else {
                errorBlock([NSError errorWithDomain:@"CollectionService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

@end
