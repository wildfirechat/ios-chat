//
//  PanService.m
//  WildFireChat
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "PanService.h"
#import "AFNetworking.h"
#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCNetworkService.h>
#import "WFCConfig.h"

static PanService *sharedSingleton = nil;

@implementation PanService

+ (PanService *)sharedService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[PanService alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - WFCUPanService

- (void)getSpacesWithSuccess:(void(^)(NSArray<WFCUPanSpace *> *spaces))successBlock
                       error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/spaces/list";
    
    [self postWithAuth:path data:@{} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *spaces = [NSMutableArray array];
            NSArray *spaceDicts = dict[@"data"];
            if ([spaceDicts isKindOfClass:[NSArray class]]) {
                for (NSDictionary *spaceDict in spaceDicts) {
                    WFCUPanSpace *space = [WFCUPanSpace fromDictionary:spaceDict];
                    if (space) [spaces addObject:space];
                }
            }
            if(successBlock) successBlock(spaces);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getMySpacesWithSuccess:(void(^)(NSArray<WFCUPanSpace *> *spaces))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/spaces/my";
    
    [self postWithAuth:path data:@{} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *spaces = [NSMutableArray array];
            NSArray *spaceDicts = dict[@"data"];
            if ([spaceDicts isKindOfClass:[NSArray class]]) {
                for (NSDictionary *spaceDict in spaceDicts) {
                    WFCUPanSpace *space = [WFCUPanSpace fromDictionary:spaceDict];
                    if (space) [spaces addObject:space];
                }
            }
            if(successBlock) successBlock(spaces);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getUserPublicSpace:(NSString *)userId
                   success:(void(^)(WFCUPanSpace *space))successBlock
                     error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/spaces/user/public";
    NSDictionary *params = @{@"targetUserId": userId ?: @""};
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *spaceDict = dict[@"data"];
            WFCUPanSpace *space = nil;
            if ([spaceDict isKindOfClass:[NSDictionary class]]) {
                space = [WFCUPanSpace fromDictionary:spaceDict];
            }
            if(successBlock) successBlock(space);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getSpaceFiles:(NSInteger)spaceId
             parentId:(NSInteger)parentId
              success:(void(^)(NSArray<WFCUPanFile *> *files))successBlock
                error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/spaces/files";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"spaceId"] = @(spaceId);
    if (parentId > 0) {
        params[@"parentId"] = @(parentId);
    } else {
        params[@"parentId"] = @(0);
    }
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *files = [NSMutableArray array];
            NSArray *fileDicts = dict[@"data"];
            if ([fileDicts isKindOfClass:[NSArray class]]) {
                for (NSDictionary *fileDict in fileDicts) {
                    WFCUPanFile *file = [WFCUPanFile fromDictionary:fileDict];
                    if (file) [files addObject:file];
                }
            }
            if(successBlock) successBlock(files);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)createFolder:(NSInteger)spaceId
            parentId:(NSInteger)parentId
                name:(NSString *)name
             success:(void(^)(WFCUPanFile *file))successBlock
               error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/folder";
    NSDictionary *params = @{
        @"spaceId": @(spaceId),
        @"parentId": parentId > 0 ? @(parentId) : [NSNull null],
        @"name": name ?: @""
    };
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUPanFile *file = [WFCUPanFile fromDictionary:dict[@"data"]];
            if(successBlock) successBlock(file);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)createFile:(NSInteger)spaceId
          parentId:(NSInteger)parentId
              name:(NSString *)name
              size:(int64_t)size
          mimeType:(NSString *)mimeType
               md5:(NSString *)md5
        storageUrl:(NSString *)storageUrl
              copy:(BOOL)copy
           success:(void(^)(WFCUPanFile *file))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files";
    NSMutableDictionary *params = [@{
        @"spaceId": @(spaceId),
        @"name": name ?: @"",
        @"size": @(size),
        @"storageUrl": storageUrl ?: @"",
        @"copy": @(copy)
    } mutableCopy];
    
    if (parentId > 0) {
        params[@"parentId"] = @(parentId);
    }
    if (mimeType) {
        params[@"mimeType"] = mimeType;
    }
    if (md5) {
        params[@"md5"] = md5;
    }
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUPanFile *file = [WFCUPanFile fromDictionary:dict[@"data"]];
            if(successBlock) successBlock(file);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)deleteFile:(NSInteger)fileId
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/delete";
    NSDictionary *params = @{@"fileId": @(fileId)};
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)renameFile:(NSInteger)fileId
           newName:(NSString *)newName
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/rename";
    NSDictionary *params = @{
        @"fileId": @(fileId),
        @"newName": newName ?: @""
    };
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getFileDownloadUrl:(NSInteger)fileId
                   success:(void(^)(NSString *url))successBlock
                     error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/url";
    NSDictionary *params = @{@"fileId": @(fileId)};
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *data = dict[@"data"];
            NSString *url = data[@"storageUrl"];
            if(successBlock) successBlock(url);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)checkSpaceWritePermission:(NSInteger)spaceId
                          success:(void(^)(BOOL hasPermission))successBlock
                            error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/check-permission";
    NSDictionary *params = @{@"spaceId": @(spaceId)};
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSNumber *data = dict[@"data"];
            BOOL hasPermission = [data boolValue];
            if(successBlock) successBlock(hasPermission);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)checkUploadPermission:(NSInteger)spaceId
                      success:(void(^)(BOOL hasPermission))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self checkSpaceWritePermission:spaceId success:successBlock error:errorBlock];
}

- (void)moveFile:(NSInteger)fileId
         toSpace:(NSInteger)targetSpaceId
        parentId:(NSInteger)targetParentId
         success:(void(^)(void))successBlock
           error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/move";
    NSMutableDictionary *params = [@{
        @"fileId": @(fileId),
        @"targetSpaceId": @(targetSpaceId)
    } mutableCopy];
    
    if (targetParentId > 0) {
        params[@"targetParentId"] = @(targetParentId);
    } else {
        params[@"targetParentId"] = @(0);
    }
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)copyFile:(NSInteger)fileId
         toSpace:(NSInteger)targetSpaceId
        parentId:(NSInteger)targetParentId
         success:(void(^)(void))successBlock
           error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/api/v1/files/copy";
    NSMutableDictionary *params = [@{
        @"fileId": @(fileId),
        @"targetSpaceId": @(targetSpaceId)
    } mutableCopy];
    
    if (targetParentId > 0) {
        params[@"targetParentId"] = @(targetParentId);
    } else {
        params[@"targetParentId"] = @(0);
    }
    
    [self postWithAuth:path data:params success:^(NSDictionary *dict) {
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
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        [self post:path data:data authCode:authCode success:successBlock error:errorBlock];
    } error:^(int error_code) {
        NSError *err = [NSError errorWithDomain:@"PanService" code:error_code userInfo:@{NSLocalizedDescriptionKey: @"Failed to get authCode"}];
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
    
    if (authCode.length > 0) {
        [manager.requestSerializer setValue:authCode forHTTPHeaderField:@"authCode"];
    }
    
    NSString *url = [self.baseUrl stringByAppendingString:path];
    
    [manager POST:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                successBlock((NSDictionary *)responseObject);
            } else {
                errorBlock([NSError errorWithDomain:@"PanService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

@end
