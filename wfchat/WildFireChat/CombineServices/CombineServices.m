//
//  CombineServices.m
//  WildFireChat
//
//  combine-server 统一业务服务（单类）：实现 WFCUPollService / WFCUPanService /
//  WFCUCollectionService / WFCUOrgServiceProvider 全部 4 个 UIKit 业务协议。
//
//  自 WFCConfig 迁入的运行时逻辑：
//    - 统一登录与会话状态（authToken / features，存于 NSUserDefaults）；
//    - 业务请求统一网络核心（JSON POST，无 token 自动登录，401/13 自动清 token 触发重登）。
//  WFCConfig 仅保留 COMBINE_SERVER_ADDRESS 配置常量。
//

#import <WFChatUIKit/WFCUPoll.h>
#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCNetworkService.h>
#import "CombineServices.h"
#import "WFCConfig.h"
#import <WFChatUIKit/WFCUCollection.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import <WebKit/WebKit.h>

// combine 统一登录态存储 key（自 WFCConfig.m 迁入）
static NSString *const kCombineAuthTokenKey = @"WFC_COMBINE_AUTH_TOKEN";
static NSString *const kCombineFeaturesKey = @"WFC_COMBINE_FEATURES";
NSString *const WFCCombineFeaturesDidUpdateNotification = @"WFCCombineFeaturesDidUpdate";

static CombineServices *sharedCombineServices = nil;

@implementation CombineServices

#pragma mark - combine 统一登录与会话状态（自 WFCConfig 迁入）

+ (NSString *)authToken {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kCombineAuthTokenKey];
}

+ (NSArray *)features {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kCombineFeaturesKey];
}

+ (BOOL)isFeatureEnabled:(NSString *)code {
    NSArray *features = [CombineServices features];
    if (!features.count) {
        return YES; // features 尚未获取（未登录/登录中），先视为可用，登录后收敛
    }
    return [features containsObject:code];
}

+ (void)saveAuth:(NSString *)token features:(NSArray *)features {
    if (token.length) {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:kCombineAuthTokenKey];
    }
    if (features) {
        [[NSUserDefaults standardUserDefaults] setObject:features forKey:kCombineFeaturesKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearAuth {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCombineAuthTokenKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCombineFeaturesKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)ensureLogin:(void(^)(BOOL ok))completion {
    if ([CombineServices authToken].length) {
        if (completion) completion(YES);
        return;
    }
    if (!COMBINE_SERVER_ADDRESS.length) {
        if (completion) completion(NO);
        return;
    }
    // IM authCode 换 combine 全局 authToken（user_login），响应附 features 一并保存
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:
            [NSURL URLWithString:[COMBINE_SERVER_ADDRESS stringByAppendingString:@"/api/user_login"]]];
        req.HTTPMethod = @"POST";
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *body = [NSString stringWithFormat:@"{\"authCode\":\"%@\"}", authCode ?: @""];
        req.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
        req.timeoutInterval = 10;
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            BOOL ok = NO;
            if (!error && data) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSDictionary class]] && [json[@"code"] intValue] == 0 && [json[@"data"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *d = json[@"data"];
                    NSString *token = d[@"token"];
                    NSArray *features = d[@"features"];
                    if (token.length) {
                        [CombineServices saveAuth:token features:features];
                        ok = YES;
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(ok);
            });
        }] resume];
    } error:^(int error_code) {
        if (completion) completion(NO);
    }];
}

+ (CombineServices *)sharedInstance {
    if (sharedCombineServices == nil) {
        @synchronized (self) {
            if (sharedCombineServices == nil) {
                sharedCombineServices = [[CombineServices alloc] init];
            }
        }
    }
    return sharedCombineServices;
}

- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - WFCUPollService

- (void)createPoll:(NSString *)groupId
             title:(NSString *)title
       description:(nullable NSString *)description
           options:(NSArray<NSString *> *)options
        visibility:(int)visibility
              type:(int)type
         maxSelect:(int)maxSelect
         anonymous:(int)anonymous
          endTime:(long long)endTime
        showResult:(int)showResult
           success:(void(^)(WFCUPoll *poll))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls
    NSString *path = @"/api/polls";
    NSMutableDictionary *param = [@{
        @"groupId": groupId ?: @"",
        @"title": title ?: @"",
        @"options": options ?: @[],
        @"visibility": @(visibility),
        @"type": @(type),
        @"maxSelect": @(maxSelect),
        @"anonymous": @(anonymous),
        @"showResult": @(showResult)
    } mutableCopy];
    
    if (description.length) {
        param[@"description"] = description;
    }
    if (endTime > 0) {
        param[@"endTime"] = @(endTime);
    }
    
    [self postWithAuth:path data:param success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUPoll *poll = [WFCUPoll fromDictionary:dict[@"data"]];
            if(successBlock) successBlock(poll);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getPoll:(long long)pollId
        success:(void(^)(WFCUPoll *poll))successBlock
          error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/{pollId}
    NSString *path = [NSString stringWithFormat:@"/api/polls/%lld", pollId];
    
    [self postWithAuth:path data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            WFCUPoll *poll = [WFCUPoll fromDictionary:dict[@"data"]];
            if(successBlock) successBlock(poll);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)vote:(long long)pollId
     optionIds:(NSArray<NSNumber *> *)optionIds
       success:(void(^)(void))successBlock
         error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/{pollId}/vote
    NSString *path = [NSString stringWithFormat:@"/api/polls/%lld/vote", pollId];
    NSDictionary *param = @{
        @"optionIds": optionIds ?: @[]
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

- (void)closePoll:(long long)pollId
          success:(void(^)(void))successBlock
            error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/{pollId}/close
    NSString *path = [NSString stringWithFormat:@"/api/polls/%lld/close", pollId];
    
    [self postWithAuth:path data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)deletePoll:(long long)pollId
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/{pollId}/delete
    NSString *path = [NSString stringWithFormat:@"/api/polls/%lld/delete", pollId];
    
    [self postWithAuth:path data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)exportPollDetails:(long long)pollId
                  success:(void(^)(NSArray<WFCUPollVoterDetail *> *details))successBlock
                    error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/{pollId}/export
    NSString *path = [NSString stringWithFormat:@"/api/polls/%lld/export", pollId];
    
    [self postWithAuth:path data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *details = [NSMutableArray array];
            NSArray *detailDicts = dict[@"data"];
            if ([detailDicts isKindOfClass:[NSArray class]]) {
                for (NSDictionary *detailDict in detailDicts) {
                    WFCUPollVoterDetail *detail = [WFCUPollVoterDetail fromDictionary:detailDict];
                    if (detail) [details addObject:detail];
                }
            }
            if(successBlock) successBlock(details);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getMyPollsWithSuccess:(void(^)(NSArray<WFCUPoll *> *polls))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock {
    // POST /api/polls/my
    NSString *path = @"/api/polls/my";
    
    [self postWithAuth:path data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *polls = [NSMutableArray array];
            NSArray *pollDicts = dict[@"data"];
            if ([pollDicts isKindOfClass:[NSArray class]]) {
                for (NSDictionary *pollDict in pollDicts) {
                    WFCUPoll *poll = [WFCUPoll fromDictionary:pollDict];
                    if (poll) [polls addObject:poll];
                }
            }
            if(successBlock) successBlock(polls);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
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


#pragma mark - WFCUOrgServiceProvider（组织通讯录协议 + 解析辅助）


- (void)getRelationship:(NSString *)employeeId
                success:(void(^)(NSArray<WFCUOrgRelationship *> *))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/relationship/employee" data:@{@"employeeId":employeeId} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            NSArray *arr = dict[@"result"];
            [arr enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrgRelationship *rs = [self relationshipFromDict:obj];
                [result addObject:rs];
            }];
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (WFCUOrganization *)organizationFromDict:(NSDictionary *)obj {
    WFCUOrganization *org = [[WFCUOrganization alloc] init];
    org.organizationId = [obj[@"id"] intValue];
    org.parentId = [obj[@"parentId"] intValue];
    org.managerId = obj[@"managerId"];
    org.name = obj[@"name"];
    org.desc = obj[@"desc"];
    org.portraitUrl = obj[@"portraitUrl"];
    org.tel = obj[@"tel"];
    org.office = obj[@"office"];
    org.groupId = obj[@"groupId"];
    org.memberCount = [obj[@"memberCount"] intValue];
    org.sort = [obj[@"sort"] intValue];
    org.updateDt = [obj[@"updateDt"] longLongValue];
    org.createDt = [obj[@"createDt"] longLongValue];
    return org;
}

- (WFCUEmployee *)employeeFromDict:(NSDictionary *)obj {
    WFCUEmployee *emp = [[WFCUEmployee alloc] init];
    emp.employeeId = obj[@"employeeId"];
    emp.organizationId = [obj[@""] intValue];
    emp.name = obj[@"name"];
    emp.title = obj[@"title"];
    emp.level = [obj[@"level"] intValue];
    emp.mobile = obj[@"mobile"];
    emp.email = obj[@"email"];
    emp.ext = obj[@"ext"];
    emp.office = obj[@"office"];
    emp.city = obj[@"city"];
    emp.portraitUrl = obj[@"portraitUrl"];
    if(!emp.portraitUrl.length || ![emp.portraitUrl hasPrefix:@"http"]) {
        if([WFCCNetworkService sharedInstance].defaultPortraitProvider && [[WFCCNetworkService sharedInstance].defaultPortraitProvider respondsToSelector:@selector(userDefaultPortrait:)]) {
            emp.portraitUrl = [[WFCCNetworkService sharedInstance].defaultPortraitProvider nameDefaultPortrait:emp.name];
        }
    }
    emp.jobNumber = obj[@"jobNumber"];
    emp.joinTime = obj[@"joinTime"];
    emp.type = [obj[@"type"] intValue];
    emp.gender = [obj[@"gender"] intValue];
    emp.sort = [obj[@"sort"] intValue];
    emp.createDt = [obj[@"createDt"] longLongValue];
    emp.updateDt = [obj[@"updateDt"] longLongValue];
    return emp;
}

- (WFCUOrgRelationship *)relationshipFromDict:(NSDictionary *)obj {
    WFCUOrgRelationship *rs = [[WFCUOrgRelationship alloc] init];
    rs.employeeId = obj[@"employeeId"];
    rs.organizationId = [obj[@"organizationId"] intValue];
    rs.depth = [obj[@"depth"] intValue];
    rs.bottom = [obj[@"bottom"] boolValue];
    rs.parentOrganizationId = [obj[@"parentOrganizationId"] intValue];
    return rs;
}

- (void)getRootOrganization:(void(^)(NSArray<WFCUOrganization *> *))successBlock
                      error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/organization/root" data:nil success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSMutableArray *result = [[NSMutableArray alloc] init];
            NSArray *arr = dict[@"result"];
            [arr enumerateObjectsUsingBlock:^(NSDictionary  *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrganization *org = [self organizationFromDict:obj];
                [result addObject:org];
            }];
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrganizationEx:(NSInteger)organizationId
                success:(void(^)(WFCUOrganizationEx *ex))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/organization/query_ex" data:@{@"id":@(organizationId)} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *d = dict[@"result"];
            WFCUOrganization *org = [self organizationFromDict:d[@"organization"]];
            
            NSMutableArray *subOrgs = [[NSMutableArray alloc] init];
            if(d[@"subOrganizations"]) {
                NSArray *arr = d[@"subOrganizations"];
                [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    WFCUOrganization *org = [self organizationFromDict:obj];
                    [subOrgs addObject:org];
                }];
            }
            
            NSMutableArray *employees = [[NSMutableArray alloc] init];
            if(d[@"employees"]) {
                NSArray *arr = d[@"employees"];
                [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    WFCUEmployee *emp = [self employeeFromDict:obj];
                    [employees addObject:emp];
                }];
            }
            WFCUOrganizationEx *ex = [[WFCUOrganizationEx alloc] init];
            ex.organizationId = organizationId;
            ex.organization = org;
            ex.subOrganizations = subOrgs;
            ex.employees = employees;
            if(successBlock) successBlock(ex);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrganizations:(NSArray<NSNumber *> *)organizationIds
                 success:(void(^)(NSArray<WFCUOrganization *> *organizations))successBlock
                   error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/organization/query_list" data:@{@"ids":organizationIds} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            NSMutableArray *orgs = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrganization *org = [self organizationFromDict:obj];
                [orgs addObject:org];
            }];
            if(successBlock) successBlock(orgs);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getBatchOrgEmployees:(NSArray<NSNumber *> *)orgIds
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                       error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/organization/batch_employees" data:@{@"ids":orgIds} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            if(successBlock) successBlock(arr);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getOrgEmployees:(NSInteger)orgId
                success:(void(^)(NSArray<NSString *> *employeeIds))successBlock
                  error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/organization/employees" data:@{@"id":@(orgId)} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSArray *arr = dict[@"result"];
            if(successBlock) successBlock(arr);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getEmployee:(NSString *)employeeId
                 success:(void(^)(WFCUEmployee *employee))successBlock
              error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/employee/query" data:@{@"employeeId":employeeId} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *emp = dict[@"result"];
            WFCUEmployee *employee = [self employeeFromDict:emp];
            if(successBlock) successBlock(employee);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}


- (void)getEmployeeEx:(NSString *)employeeId
              success:(void(^)(WFCUEmployeeEx *employeeEx))successBlock
                error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/employee/query_ex" data:@{@"employeeId":employeeId} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *exDict = dict[@"result"];
            WFCUEmployee *employee = [self employeeFromDict:exDict[@"employee"]];
            NSArray *arr = exDict[@"relationships"];
            NSMutableArray *result = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUOrgRelationship *rs = [self relationshipFromDict:obj];
                [result addObject:rs];
            }];
            WFCUEmployeeEx *empEx = [[WFCUEmployeeEx alloc] init];
            empEx.employeeId = employeeId;
            empEx.employee = employee;
            empEx.relationships = result;
            
            if(successBlock) successBlock(empEx);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)searchEmployee:(NSInteger)organizationId
               keyword:(NSString *)keyword
               success:(void(^)(NSArray<WFCUEmployee *> *employees))successBlock
                 error:(void(^)(int error_code))errorBlock {
    [self postWithAuth:@"/api/employee/search" data:@{@"keyword":keyword, @"organizationId":@(organizationId), @"count":@(50), @"page":@(0)} success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *exDict = dict[@"result"];
            NSArray<NSDictionary *> *arr = exDict[@"contents"];
            NSMutableArray *result = [[NSMutableArray alloc] init];
            [arr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                WFCUEmployee *rs = [self employeeFromDict:obj];
                [result addObject:rs];
            }];
            
            if(successBlock) successBlock(result);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)clearAuthInfos {
    [CombineServices clearAuth]; // 清空 combine 全局登录态（token + features）
    // 清业务本地缓存（组织通讯录）
    [[WFCUOrganizationCache sharedCache] clearCaches];
}



#pragma mark - HTTP Helper Methods（统一网络核心封装）

- (void)postWithAuth:(NSString *)path
                data:(nullable id)data
             success:(void(^)(NSDictionary *dict))successBlock
               error:(void(^)(NSError * _Nonnull error))errorBlock {
    [self post:path data:data success:successBlock error:errorBlock];
}

- (void)post:(NSString *)path
        data:(nullable id)data
     success:(void(^)(NSDictionary *dict))successBlock
       error:(void(^)(NSError * _Nonnull error))errorBlock {
    // 统一网络核心（自 WFCCombinePost 迁入）：JSON POST 到 combine 单地址，
    // 自动注入全局 authToken；无 token 先 ensureLogin；token 失效（HTTP 401 / code 401 / code 13）时清除登录态。
    if (!COMBINE_SERVER_ADDRESS.length) {
        if (errorBlock) errorBlock([NSError errorWithDomain:@"Combine" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"未配置 combine 服务地址"}]);
        return;
    }
    void(^send)(void) = ^{
        NSString *url = [COMBINE_SERVER_ADDRESS stringByAppendingString:path ?: @""];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        req.HTTPMethod = @"POST";
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        NSString *tok = [CombineServices authToken];
        if (tok.length) {
            [req setValue:tok forHTTPHeaderField:@"authToken"];
        }
        NSError *serr = nil;
        req.HTTPBody = [NSJSONSerialization dataWithJSONObject:(data ?: @{}) options:0 error:&serr];
        req.timeoutInterval = 15;
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *respData, NSURLResponse *resp, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (err) {
                    if (errorBlock) errorBlock(err);
                    return;
                }
                NSInteger status = ((NSHTTPURLResponse *)resp).statusCode;
                NSDictionary *json = respData ? [NSJSONSerialization JSONObjectWithData:respData options:0 error:nil] : nil;
                if (![json isKindOfClass:[NSDictionary class]]) {
                    if (errorBlock) errorBlock([NSError errorWithDomain:@"Combine" code:-2 userInfo:@{NSLocalizedDescriptionKey: @"服务响应异常"}]);
                    return;
                }
                int code = [json[@"code"] intValue];
                if (status == 401 || code == 401 || code == 13) {
                    [CombineServices clearAuth]; // token 失效：清除，后续请求会重新登录
                }
                if (successBlock) successBlock(json);
            });
        }] resume];
    };
    if (![CombineServices authToken].length) {
        [CombineServices ensureLogin:^(BOOL ok) {
            if (ok) {
                send();
            } else if (errorBlock) {
                errorBlock([NSError errorWithDomain:@"Combine" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"登录失败"}]);
            }
        }];
    } else {
        send();
    }
}

@end
