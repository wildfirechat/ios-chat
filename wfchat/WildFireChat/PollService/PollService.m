//
//  PollService.m
//  WildFireChat
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "PollService.h"
#import "AFNetworking.h"
#import <WFChatUIKit/WFCUPoll.h>
#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCNetworkService.h>
#import "WFCConfig.h"

static PollService *sharedSingleton = nil;

@implementation PollService

+ (PollService *)sharedService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[PollService alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认基础 URL
        //_baseUrl = @"http://localhost:8081";
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

#pragma mark - HTTP Helper Methods

- (void)postWithAuth:(NSString *)path
                data:(nullable id)data
             success:(void(^)(NSDictionary *dict))successBlock
               error:(void(^)(NSError * _Nonnull error))errorBlock {
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        [self post:path data:data authCode:authCode success:successBlock error:errorBlock];
    } error:^(int error_code) {
        NSError *err = [NSError errorWithDomain:@"PollService" code:error_code userInfo:@{NSLocalizedDescriptionKey: @"Failed to get authCode"}];
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
                errorBlock([NSError errorWithDomain:@"PollService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}]);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorBlock(error);
        });
    }];
}

@end
