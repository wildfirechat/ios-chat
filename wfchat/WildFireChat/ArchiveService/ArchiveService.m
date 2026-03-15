//
//  ArchiveService.m
//  WildFireChat
//
//  Created by WF Chat on 2025/3/11.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import "ArchiveService.h"
#import "ArchivedMessage.h"
#import "ArchiveMessagePayload.h"
#import "ArchiveMessageResult.h"
#import "AFNetworking.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCConfig.h"

static ArchiveService *sharedSingleton = nil;

@interface ArchiveService ()
@property (nonatomic, assign) long long messageIdCounter;
@end

@implementation ArchiveService

+ (ArchiveService *)sharedService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[ArchiveService alloc] init];
            }
        }
    }
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 默认基础 URL
        //_baseUrl = @"http://localhost:8088";
        _messageIdCounter = 0;
    }
    return self;
}

#pragma mark - WFCUArchiveService

- (void)getArchivedMessages:(int)conversationType
                 convTarget:(NSString *)convTarget
                   startMid:(int64_t)startMid
                     before:(BOOL)before
                      limit:(int)limit
                    success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                      error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self getArchivedMessages:conversationType
                   convTarget:convTarget
                     convLine:0
                     startMid:startMid
                       before:before
                        limit:limit
                      success:successBlock
                        error:errorBlock];
}

- (void)getArchivedMessages:(int)conversationType
                 convTarget:(NSString *)convTarget
                   convLine:(int)convLine
                   startMid:(int64_t)startMid
                     before:(BOOL)before
                      limit:(int)limit
                    success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                      error:(void(^)(int errorCode, NSString *message))errorBlock {
    
    // 构建请求参数
    NSMutableDictionary *params = [@{
        @"convType": @(conversationType),
        @"convTarget": convTarget ?: @"",
        @"convLine": @(convLine),
        @"before": @(before),
        @"limit": @(MIN(limit, 100)),
        @"startMid":@(startMid)
    } mutableCopy];
    
    [self postWithAuth:@"/api/messages/fetch" data:params success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            ArchiveMessageResult *result = [self parseResultFromDictionary:dict[@"data"]];
            if (successBlock) successBlock(result.messages, result.hasMore, result.nextStartMid);
        } else {
            if (errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"] ?: @"Unknown error");
        }
    } error:^(NSError *error) {
        if (errorBlock) errorBlock((int)error.code, error.localizedDescription);
    }];
}

- (void)searchArchivedMessages:(NSString *)keyword
                         limit:(int)limit
                       success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self searchArchivedMessages:keyword
                conversationType:nil
                      convTarget:nil
                        convLine:nil
                        startMid:0
                          before:YES
                           limit:limit
                         success:successBlock
                           error:errorBlock];
}

- (void)searchArchivedMessages:(NSString *)keyword
              conversationType:(nullable NSNumber *)conversationType
                    convTarget:(nullable NSString *)convTarget
                      convLine:(nullable NSNumber *)convLine
                      startMid:(int64_t)startMid
                        before:(BOOL)before
                         limit:(int)limit
                       success:(void(^)(NSArray<WFCCMessage *> *messages, BOOL hasMore, int64_t nextStartMid))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock {
    
    NSMutableDictionary *params = [@{
        @"convType": conversationType,
        @"convTarget": convTarget ?: @"",
        @"convLine": convLine,
        @"keyword": keyword ?: @"",
        @"before": @(before),
        @"limit": @(MIN(limit, 100)),
        @"startMid":@(startMid)
    } mutableCopy];
    
    [self postWithAuth:@"/api/messages/search" data:params success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            ArchiveMessageResult *result = [self parseResultFromDictionary:dict[@"data"]];
            if (successBlock) successBlock(result.messages, result.hasMore, result.nextStartMid);
        } else {
            if (errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"] ?: @"Unknown error");
        }
    } error:^(NSError *error) {
        if (errorBlock) errorBlock((int)error.code, error.localizedDescription);
    }];
}

#pragma mark - Helper Methods

/**
 * 将归档服务返回的数据解析为 ArchiveMessageResult
 * 其中 messages 字段会被转换为 WFCCMessage 对象
 */
- (ArchiveMessageResult *)parseResultFromDictionary:(NSDictionary *)dict {
    ArchiveMessageResult *result = [[ArchiveMessageResult alloc] init];
    result.hasMore = [dict[@"hasMore"] boolValue];
    result.nextStartMid = [dict[@"nextStartMid"] isKindOfClass:NSNull.class]?0L:[dict[@"nextStartMid"] longLongValue];
    
    NSMutableArray *messages = [NSMutableArray array];
    NSArray *messageDicts = dict[@"messages"];
    if ([messageDicts isKindOfClass:[NSArray class]]) {
        for (NSDictionary *messageDict in messageDicts) {
            // 先将字典转为 ArchivedMessage
            ArchivedMessage *archivedMsg = [ArchivedMessage fromDictionary:messageDict];
            if (archivedMsg) {
                // 再转换为 WFCCMessage
                WFCCMessage *message = [self convertArchivedMessageToWFCCMessage:archivedMsg];
                if (message) [messages addObject:message];
            }
        }
    }
    result.messages = messages;
    
    return result;
}

/**
 * 将归档消息转换为 WFCCMessage
 */
- (nullable WFCCMessage *)convertArchivedMessageToWFCCMessage:(ArchivedMessage *)archivedMsg {
    if (!archivedMsg) return nil;
    
    WFCCMessage *message = [[WFCCMessage alloc] init];
    //从远程同步回来的消息，没有消息ID，使用递减的负数确保唯一
    self.messageIdCounter--;
    message.messageId = self.messageIdCounter;
    message.messageUid = archivedMsg.mid;
    message.fromUser = archivedMsg.senderId;
    
    // 判断消息方向：如果是当前用户发送的就是发送的，否则就是收到的
    NSString *currentUserId = [WFCCNetworkService sharedInstance].userId;
    if (currentUserId && [currentUserId isEqualToString:archivedMsg.senderId]) {
        message.direction = MessageDirection_Send;
        // 发送的消息状态设为发送成功
        message.status = Message_Status_Sent;
    } else {
        message.direction = MessageDirection_Receive;
        // 接收的消息状态设为已读
        message.status = Message_Status_Readed;
    }
    
    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = archivedMsg.convType;
    conversation.target = archivedMsg.convTarget;
    conversation.line = archivedMsg.convLine;
    message.conversation = conversation;
    
    // 转换时间为毫秒时间戳
    NSDate *msgDate = [archivedMsg localMessageDate];
    message.serverTime = (long long)(msgDate.timeIntervalSince1970 * 1000);
    
    // 使用 payload 创建 SDK 的 WFCCMessagePayload
    WFCCMessagePayload *sdkPayload;
    if (archivedMsg.payload) {
        sdkPayload = [archivedMsg.payload toSDKPayload:archivedMsg.contentType];
    } else {
        // 如果没有 payload，创建一个空的 payload
        sdkPayload = [[WFCCMessagePayload alloc] init];
        sdkPayload.contentType = archivedMsg.contentType;
    }
    
    // 使用 IMService 解析消息内容
    WFCCMessageContent *content = [[WFCCIMService sharedWFCIMService] messageContentFromPayload:sdkPayload];
    if (!content) {
        content = [[WFCCUnknownMessageContent alloc] init];
    }
    message.content = content;
    
    return message;
}

#pragma mark - HTTP Helper Methods

- (void)postWithAuth:(NSString *)path
                data:(nullable id)data
             success:(void(^)(NSDictionary *dict))successBlock
               error:(void(^)(NSError *error))errorBlock {
    [[WFCCIMService sharedWFCIMService] getAuthCode:@"admin" type:2 host:IM_SERVER_HOST success:^(NSString *authCode) {
        [self post:path data:data authCode:authCode success:successBlock error:errorBlock];
    } error:^(int error_code) {
        NSError *err = [NSError errorWithDomain:@"ArchiveService" code:error_code userInfo:@{NSLocalizedDescriptionKey: @"Failed to get authCode"}];
        if (errorBlock) errorBlock(err);
    }];
}

- (void)post:(NSString *)path
        data:(nullable id)data
    authCode:(NSString *)authCode
     success:(void(^)(NSDictionary *dict))successBlock
       error:(void(^)(NSError *error))errorBlock {
    
    if (!self.baseUrl.length) {
        NSError *err = [NSError errorWithDomain:@"ArchiveService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Base URL not set"}];
        if (errorBlock) errorBlock(err);
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer.timeoutInterval = 30.0;
    
    if (authCode.length > 0) {
        [manager.requestSerializer setValue:authCode forHTTPHeaderField:@"authCode"];
    }
    
    NSString *url = [self.baseUrl stringByAppendingString:path];
    
    [manager POST:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                if (successBlock) successBlock((NSDictionary *)responseObject);
            } else {
                NSError *err = [NSError errorWithDomain:@"ArchiveService" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Invalid response"}];
                if (errorBlock) errorBlock(err);
            }
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            if (response.statusCode == 401) {
                NSError *err = [NSError errorWithDomain:@"ArchiveService" code:401 userInfo:@{NSLocalizedDescriptionKey: @"Authentication failed"}];
                if (errorBlock) errorBlock(err);
            } else {
                if (errorBlock) errorBlock(error);
            }
        });
    }];
}

@end
