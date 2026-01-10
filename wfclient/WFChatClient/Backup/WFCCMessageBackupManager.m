//
//  WFCCMessageBackupManager.m
//  WFChatClient
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCMessageBackupManager.h"
#import "WFCCBackupCrypto.h"
#import "WFCCIMService.h"
#import "WFCCMessageContent.h"
#import "WFCCConversation.h"
#import "WFCCConversationInfo.h"
#import "WFCCNetworkService.h"
#import "WFCCMessage.h"
#import "WFCCImageMessageContent.h"
#import "WFCCUtilities.h"

// 常量定义
static NSString * const kBackupVersion = @"1";
static NSString * const kBackupFormat = @"directory";
static NSString * const kBackupAppType = @"ios-chat";
static NSString * const kBackupModeMessageWithMedia = @"message_with_media";
static NSString * const kBackupEncryptionAlgorithm = @"AES-256-CBC";
static NSString * const kBackupKeyDerivation = @"PBKDF2-SHA256";

static const NSInteger kDefaultMessageBatchSize = -100;
static const CGFloat kThumbnailCompressionQuality = 0.45;

@interface WFCCMessageBackupManager ()

@property (atomic, assign) BOOL isCancelled;
@property (nonatomic, strong) NSString *currentBackupDirectory;

@end

@implementation WFCCMessageBackupManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static WFCCMessageBackupManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isCancelled = NO;
    }
    return self;
}

#pragma mark - 取消操作

- (void)cancelCurrentOperation {
    self.isCancelled = YES;
    NSLog(@"[WFCCMessageBackupManager] Operation cancelled");
}

// 清理不完整的备份目录
- (void)cleanupIncompleteBackup {
    if (self.currentBackupDirectory && self.currentBackupDirectory.length > 0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDirectory;
        if ([fileManager fileExistsAtPath:self.currentBackupDirectory isDirectory:&isDirectory] && isDirectory) {
            NSError *error;
            BOOL removed = [fileManager removeItemAtPath:self.currentBackupDirectory error:&error];
            if (removed) {
                NSLog(@"[WFCCMessageBackupManager] Cleaned up incomplete backup: %@", self.currentBackupDirectory);
            } else {
                NSLog(@"[WFCCMessageBackupManager] Failed to cleanup backup directory: %@, error: %@", self.currentBackupDirectory, error.localizedDescription);
            }
        }
        self.currentBackupDirectory = nil;
    }
}

#pragma mark - 辅助方法

// 安全地添加字符串值（跳过空字符串）
- (void)safelySetString:(NSString *)string forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    if (string && string.length > 0) {
        dict[key] = string;
    }
}

// 安全地添加数组值（跳过空数组）
- (void)safelySetArray:(NSArray *)array forKey:(NSString *)key inDictionary:(NSMutableDictionary *)dict {
    if (array && array.count > 0) {
        dict[key] = array;
    }
}

// 编码会话信息
- (NSDictionary *)encodeConversationInfo:(WFCCConversationInfo *)convInfo {
    WFCCConversation *conversation = convInfo.conversation;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"type"] = @(conversation.type);
    [self safelySetString:conversation.target forKey:@"target" inDictionary:dict];
    dict[@"line"] = @(conversation.line);
    dict[@"isTop"] = @(convInfo.isTop);
    dict[@"isSilent"] = @(convInfo.isSilent);
    [self safelySetString:convInfo.draft forKey:@"draft" inDictionary:dict];

    return [dict copy];
}

// 编码消息
- (NSDictionary *)encodeMessage:(WFCCMessage *)message
                  includeMedia:(BOOL)includeMedia
                 mediaBaseDir:(NSString *)mediaBaseDir {

    // 编码基本信息
    NSMutableDictionary *msgDict = [NSMutableDictionary dictionary];
    msgDict[@"messageUid"] = @(message.messageUid);
    [self safelySetString:message.fromUser forKey:@"fromUser" inDictionary:msgDict];
    [self safelySetArray:message.toUsers forKey:@"toUsers" inDictionary:msgDict];
    msgDict[@"direction"] = @(message.direction);
    msgDict[@"status"] = @(message.status);
    msgDict[@"timestamp"] = @(message.serverTime);
    [self safelySetString:message.localExtra forKey:@"localExtra" inDictionary:msgDict];

    // 编码 payload
    WFCCMessagePayload *payload = [message.content encode];
    NSMutableDictionary *payloadDict = [NSMutableDictionary dictionary];

    payloadDict[@"contentType"] = @(payload.contentType);
    [self safelySetString:payload.searchableContent forKey:@"searchableContent" inDictionary:payloadDict];
    [self safelySetString:payload.pushContent forKey:@"pushContent" inDictionary:payloadDict];
    [self safelySetString:payload.pushData forKey:@"pushData" inDictionary:payloadDict];
    [self safelySetString:payload.content forKey:@"content" inDictionary:payloadDict];

    // 将 NSData 转换为 Base64 字符串（只有非空时才保存）
    if (payload.binaryContent && payload.binaryContent.length > 0) {
        payloadDict[@"binaryContent"] = [payload.binaryContent base64EncodedStringWithOptions:0];
    }

    [self safelySetString:payload.localContent forKey:@"localContent" inDictionary:payloadDict];
    payloadDict[@"mentionedType"] = @(payload.mentionedType);
    [self safelySetArray:payload.mentionedTargets forKey:@"mentionedTargets" inDictionary:payloadDict];
    [self safelySetString:payload.extra forKey:@"extra" inDictionary:payloadDict];
    payloadDict[@"notLoaded"] = @(payload.notLoaded);

    // 处理媒体消息
    if ([message.content isKindOfClass:NSClassFromString(@"WFCCMediaMessageContent")]) {
        // 获取媒体消息内容
        WFCCMessagePayload *mediaPayload = payload;
        if ([mediaPayload respondsToSelector:@selector(mediaType)]) {
            payloadDict[@"mediaType"] = @([(id)mediaPayload mediaType]);
        }
        if ([mediaPayload respondsToSelector:@selector(remoteMediaUrl)]) {
            [self safelySetString:[(id)mediaPayload remoteMediaUrl] forKey:@"remoteMediaUrl" inDictionary:payloadDict];
        }

        // 对于图片消息，确保缩略图数据被保存到 binaryContent
        // 如果 encode 方法没有保存缩略图（因为有 imageThumbPara），我们手动保存
        if ([message.content isKindOfClass:NSClassFromString(@"WFCCImageMessageContent")]) {
            if (!payload.binaryContent || payload.binaryContent.length == 0) {
                // 尝试从图片消息内容获取缩略图
                if ([message.content respondsToSelector:@selector(thumbnail)]) {
                    UIImage *thumbnailImage = [(id)message.content thumbnail];
                    if (thumbnailImage) {
                        // 将缩略图转换为 JPEG 数据
                        payload.binaryContent = UIImageJPEGRepresentation(thumbnailImage, kThumbnailCompressionQuality);
                        if (payload.binaryContent && payload.binaryContent.length > 0) {
                            // 更新 payloadDict，确保缩略图被保存
                            payloadDict[@"binaryContent"] = [payload.binaryContent base64EncodedStringWithOptions:0];
                        }
                    }
                }
            }
        }

        if (includeMedia && [mediaPayload respondsToSelector:@selector(localMediaPath)]) {
            NSString *localMediaPath = [(id)mediaPayload localMediaPath];
            if (localMediaPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:localMediaPath]) {
                // 计算 MD5 并验证结果
                NSString *md5 = [WFCCBackupCrypto calculateMD5ForFile:localMediaPath];
                if (md5 && md5.length >= 16) {
                    NSString *fileId = [md5 substringToIndex:16];
                    NSString *extension = [localMediaPath pathExtension];
                    NSString *fileName = [NSString stringWithFormat:@"media_%@.%@", fileId, extension];
                    // 相对路径直接使用文件名（不包含 media/ 子目录）
                    NSString *relativePath = fileName;
                    // 文件直接复制到 mediaBaseDir 下
                    NSString *targetPath = [mediaBaseDir stringByAppendingPathComponent:fileName];

                    // 复制文件
                    NSError *copyError;
                    [[NSFileManager defaultManager] copyItemAtPath:localMediaPath
                                                            toPath:targetPath
                                                             error:&copyError];
                    if (!copyError) {
                        // 保存媒体信息
                        long long fileSize = [self fileSizeAtPath:localMediaPath];

                        payloadDict[@"localMediaInfo"] = @{
                            @"relativePath": relativePath,
                            @"fileId": fileId,
                            @"fileSize": @(fileSize),
                            @"md5": md5 ?: @""
                        };

                        msgDict[@"mediaFileSize"] = @(fileSize);
                    }
                } else {
                    NSLog(@"[WFCCMessageBackupManager] Failed to calculate valid MD5 for file: %@", localMediaPath);
                }
            }
        }
    }

    msgDict[@"payload"] = payloadDict;
    return msgDict;
}

// 解码 payload
- (WFCCMessagePayload *)decodePayloadDict:(NSDictionary *)dict {
    WFCCMessagePayload *payload = [[WFCCMediaMessagePayload alloc] init];

    payload.contentType = [dict[@"contentType"] intValue];
    payload.searchableContent = dict[@"searchableContent"];
    payload.pushContent = dict[@"pushContent"];
    payload.pushData = dict[@"pushData"];
    payload.content = dict[@"content"];

    // 将 Base64 字符串转换回 NSData（包含缩略图数据）
    NSString *binaryContentStr = dict[@"binaryContent"];
    if (binaryContentStr && binaryContentStr.length > 0) {
        payload.binaryContent = [[NSData alloc] initWithBase64EncodedString:binaryContentStr options:0];
    } else {
        payload.binaryContent = nil;
    }

    payload.localContent = dict[@"localContent"];
    payload.mentionedType = [dict[@"mentionedType"] intValue];
    payload.mentionedTargets = dict[@"mentionedTargets"];
    payload.extra = dict[@"extra"];
    payload.notLoaded = [dict[@"notLoaded"] boolValue];

    // 媒体消息特有字段
    if (dict[@"mediaType"]) {
        if ([payload respondsToSelector:@selector(setMediaType:)]) {
            [(id)payload setMediaType:[dict[@"mediaType"] intValue]];
        }
        if ([payload respondsToSelector:@selector(setRemoteMediaUrl:)]) {
            [(id)payload setRemoteMediaUrl:dict[@"remoteMediaUrl"]];
        }
        // 注意：localMediaPath 需要在调用方通过 localMediaInfo 设置
    }

    return payload;
}

// 生成统计信息
- (NSDictionary *)generateStatisticsForBackup:(NSDictionary *)backupData {
    int totalConversations = 0;
    int totalMessages = 0;
    long long firstTime = LLONG_MAX;
    long long lastTime = 0;

    for (NSDictionary *conv in backupData[@"conversations"]) {
        totalConversations++;
        NSArray *messages = conv[@"messages"];
        totalMessages += messages.count;

        for (NSDictionary *msg in messages) {
            long long timestamp = [msg[@"timestamp"] longLongValue];
            if (timestamp < firstTime) firstTime = timestamp;
            if (timestamp > lastTime) lastTime = timestamp;
        }
    }

    // 计算文件大小（仅消息）
    long long backupSize = 0;

    return @{
        @"totalConversations": @(totalConversations),
        @"totalMessages": @(totalMessages),
        @"backupSize": @(backupSize),
        @"mediaFileCount": @0,
        @"mediaTotalSize": @0,
        @"timeRange": @{
            @"firstMessageTime": @(firstTime),
            @"lastMessageTime": @(lastTime)
        }
    };
}

// 验证备份数据
- (BOOL)validateBackupData:(NSDictionary *)backupData {
    if (![backupData isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    NSArray *requiredFields = @[@"version", @"backupTime", @"userId", @"backupMode", @"conversations"];
    for (NSString *field in requiredFields) {
        if (!backupData[field]) {
            NSLog(@"[WFCCMessageBackupManager] Missing required field: %@", field);
            return NO;
        }
    }

    if (![backupData[@"conversations"] isKindOfClass:[NSArray class]]) {
        return NO;
    }

    return YES;
}

// 获取文件大小
- (long long)fileSizeAtPath:(NSString *)filePath {
    NSError *error;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) return 0;
    return [attrs fileSize];
}

// 获取当前时间戳
+ (NSString *)getCurrentTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z";
    formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    return [formatter stringFromDate:[NSDate date]];
}

#pragma mark - 目录备份（新格式 v2.0）

// 生成会话目录名
- (NSString *)getConversationDirectoryName:(WFCCConversationInfo *)convInfo {
    WFCCConversation *conversation = convInfo.conversation;
    // 格式：conv_{type}_{target}_{line}
    // 对 target 进行 URL 编码以避免特殊字符问题
    NSString *encodedTarget = [conversation.target stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [NSString stringWithFormat:@"conv_type%ld_%@_line%ld",
            (long)conversation.type,
            encodedTarget ?: @"unknown",
            (long)conversation.line];
}

// 加密 messages.json 文件
- (BOOL)encryptMessagesFile:(NSString *)messagesJsonPath password:(NSString *)password {
    // 1. 读取原始 JSON
    NSData *jsonData = [NSData dataWithContentsOfFile:messagesJsonPath];
    if (!jsonData) {
        return NO;
    }

    // 2. 使用 WFCCBackupCrypto 加密
    NSError *error;
    NSDictionary *encryptedResult = [WFCCBackupCrypto encryptData:jsonData
                                                         password:password
                                                            error:&error];
    if (!encryptedResult) {
        NSLog(@"[WFCCMessageBackupManager] Failed to encrypt messages.json: %@", error);
        return NO;
    }

    // 3. 将加密结果转换为 JSON 并保存
    NSData *encryptedJsonData = [NSJSONSerialization dataWithJSONObject:encryptedResult
                                                                 options:NSJSONWritingPrettyPrinted
                                                                   error:&error];
    if (!encryptedJsonData) {
        NSLog(@"[WFCCMessageBackupManager] Failed to serialize encrypted data: %@", error);
        return NO;
    }

    // 4. 保存加密后的数据
    BOOL success = [encryptedJsonData writeToFile:messagesJsonPath atomically:YES];
    if (!success) {
        NSLog(@"[WFCCMessageBackupManager] Failed to write encrypted messages.json");
    }

    return success;
}

// 创建 metadata.json
- (void)createMetadataJSONForDirectory:(NSString *)directoryPath
                          withPassword:(NSString *)password
                        passwordHint:(NSString *)passwordHint
                      conversations:(NSArray *)conversationMetadata
                        totalMessages:(int)totalMessages
                      totalMediaFiles:(int)totalMediaFiles
                       totalMediaSize:(long long)totalMediaSize
                     firstMessageTime:(long long)firstMessageTime
                      lastMessageTime:(long long)lastMessageTime {

    NSMutableDictionary *metadata = [NSMutableDictionary dictionary];

    metadata[@"version"] = kBackupVersion;
    metadata[@"format"] = kBackupFormat;
    metadata[@"backupTime"] = [[self class] getCurrentTimestamp];
    metadata[@"userId"] = [WFCCNetworkService sharedInstance].userId;
    metadata[@"appType"] = kBackupAppType;
    metadata[@"backupMode"] = kBackupModeMessageWithMedia;

    // 加密信息
    NSMutableDictionary *encryptionInfo = [NSMutableDictionary dictionary];
    encryptionInfo[@"enabled"] = @(password && password.length > 0);
    if (password && password.length > 0) {
        encryptionInfo[@"algorithm"] = kBackupEncryptionAlgorithm;
        encryptionInfo[@"keyDerivation"] = kBackupKeyDerivation;
        [self safelySetString:passwordHint forKey:@"passwordHint" inDictionary:encryptionInfo];
    }
    metadata[@"encryption"] = encryptionInfo;

    // 统计信息
    metadata[@"statistics"] = @{
        @"totalConversations": @(conversationMetadata.count),
        @"totalMessages": @(totalMessages),
        @"mediaFileCount": @(totalMediaFiles),
        @"mediaTotalSize": @(totalMediaSize),
        @"timeRange": @{
            @"firstMessageTime": @(firstMessageTime),
            @"lastMessageTime": @(lastMessageTime)
        }
    };

    // 会话清单
    metadata[@"conversations"] = conversationMetadata;

    // 保存到文件
    NSString *metadataPath = [directoryPath stringByAppendingPathComponent:@"metadata.json"];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:metadata
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (jsonData) {
        [jsonData writeToFile:metadataPath atomically:YES];
    } else {
        NSLog(@"[WFCCMessageBackupManager] Failed to create metadata.json: %@", error);
    }
}

// 从目录备份数据恢复消息
// 返回值：恢复的消息数量
// 通过指针参数返回媒体文件数量
- (int)restoreMessagesFromDirectoryData:(NSDictionary *)convData
                      overwriteExisting:(BOOL)overwriteExisting
                           mediaBaseDir:(NSString *)mediaBaseDir
                        mediaCountOut:(int *)mediaCountOut {

    // 解析会话信息
    NSDictionary *convDict = convData[@"conversation"];
    int type = [convDict[@"type"] intValue];
    NSString *target = convDict[@"target"];
    int line = [convDict[@"line"] intValue];

    WFCCConversation *conversation = [[WFCCConversation alloc] init];
    conversation.type = type;
    conversation.target = target;
    conversation.line = line;

    // 解析设置
    NSDictionary *settings = convData[@"settings"];
    BOOL isTop = [settings[@"isTop"] boolValue];
    BOOL isSilent = [settings[@"isSilent"] boolValue];
    NSString *draft = settings[@"draft"];

    // 更新会话设置（TODO: 实现会话设置的恢复）

    // 恢复消息
    NSArray *messages = convData[@"messages"];
    int restoredCount = 0;
    int restoredMediaCount = 0;

    for (NSDictionary *msgDict in messages) {
        @autoreleasepool {
            if (![msgDict isKindOfClass:[NSDictionary class]]) {
                NSLog(@"[WFCCMessageBackupManager] Invalid message data, skipping");
                continue;
            }

            // 解码消息
            WFCCMessage *message = [self decodeMessageFromDict:msgDict
                                               forConversation:conversation
                                                 mediaBaseDir:mediaBaseDir];
            if (message) {
                // 插入到数据库
                long msgId = [[WFCCIMService sharedWFCIMService] insertMessage:message];
                if (msgId > 0) {
                    restoredCount++;

                    // 统计是否有媒体文件
                    if (msgDict[@"payload"][@"localMediaInfo"]) {
                        restoredMediaCount++;
                    }
                }
            }
        }
    }

    // 通过指针参数返回媒体数量
    if (mediaCountOut) {
        *mediaCountOut = restoredMediaCount;
    }

    return restoredCount;
}

// 从字典解码消息
- (WFCCMessage *)decodeMessageFromDict:(NSDictionary *)msgDict
                      forConversation:(WFCCConversation *)conversation
                          mediaBaseDir:(NSString *)mediaBaseDir {

    // 创建消息对象
    WFCCMessage *message = [[WFCCMessage alloc] init];
    message.messageUid = [msgDict[@"messageUid"] unsignedLongLongValue];
    message.fromUser = msgDict[@"fromUser"];
    message.toUsers = msgDict[@"toUsers"];
    message.direction = [msgDict[@"direction"] intValue];
    message.status = [msgDict[@"status"] intValue];
    message.serverTime = [msgDict[@"timestamp"] longLongValue];
    message.localExtra = msgDict[@"localExtra"];
    message.conversation = conversation;

    // 解码 payload
    NSDictionary *payloadDict = msgDict[@"payload"];
    WFCCMessagePayload *payload = [self decodePayloadDict:payloadDict];

    // 处理本地媒体文件恢复
    if (payloadDict[@"localMediaInfo"]) {
        NSDictionary *mediaInfo = payloadDict[@"localMediaInfo"];
        NSString *relativePath = mediaInfo[@"relativePath"];
        NSString *fileId = mediaInfo[@"fileId"];

        if (relativePath && fileId && mediaBaseDir) {
            // 1. 从备份目录中找到媒体文件
            // relativePath 现在直接是文件名（如 "media_xxx.jpg"）
            NSString *backupFilePath = [mediaBaseDir stringByAppendingPathComponent:relativePath];

            if ([[NSFileManager defaultManager] fileExistsAtPath:backupFilePath]) {
                // 2. 生成新的媒体文件存储路径（使用 sendbox 目录）
                NSString *mediaDir = [WFCCUtilities getDocumentPathWithComponent:@"sendbox"];
                NSString *extension = [relativePath pathExtension];
                NSString *newFileName = [NSString stringWithFormat:@"%@.%@", fileId, extension];
                NSString *newFilePath = [mediaDir stringByAppendingPathComponent:newFileName];

                // 3. 复制文件到应用的媒体目录
                NSError *copyError;
                [[NSFileManager defaultManager] copyItemAtPath:backupFilePath
                                                        toPath:newFilePath
                                                         error:&copyError];
                if (!copyError) {
                    // 4. 设置正确的 localPath
                    if ([payload respondsToSelector:@selector(setLocalMediaPath:)]) {
                        [(id)payload setLocalMediaPath:newFilePath];
                    }
                    NSLog(@"[WFCCMessageBackupManager] Restored media file: %@", newFileName);
                } else {
                    NSLog(@"[WFCCMessageBackupManager] Failed to copy media file: %@", copyError);
                }
            } else {
                NSLog(@"[WFCCMessageBackupManager] Backup media file not found: %@", backupFilePath);
            }
        }
    }

    // 从 payload 创建消息内容
    message.content = [[WFCCIMService sharedWFCIMService] messageContentFromPayload:payload];

    return message;
}

- (void)createDirectoryBasedBackup:(NSString *)directoryPath
                      conversations:(nullable NSArray<WFCCConversationInfo *> *)conversations
                          password:(NSString *)password
                      passwordHint:(NSString *)passwordHint
                           progress:(void(^)(NSProgress *))progress
                            success:(void(^)(NSString *, int, int, long long))success
                              error:(void(^)(int))error {

    // 参数验证
    if (!directoryPath || directoryPath.length == 0) {
        if (error) {
            error(BackupError_InvalidFormat);
        }
        return;
    }

    // 如果提供了密码，必须非空
    if (password && password.length == 0) {
        if (error) {
            error(BackupError_InvalidPassword);
        }
        return;
    }

    // 重置取消标志并记录备份路径
    self.isCancelled = NO;
    self.currentBackupDirectory = directoryPath;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 创建备份根目录和 conversations 子目录
        NSError *fmError;
        NSFileManager *fileManager = [NSFileManager defaultManager];

        BOOL created = [fileManager createDirectoryAtPath:directoryPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&fmError];
        if (!created) {
            self.currentBackupDirectory = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_IOError);
            });
            return;
        }

        NSString *conversationsDir = [directoryPath stringByAppendingPathComponent:@"conversations"];
        [fileManager createDirectoryAtPath:conversationsDir
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:nil];

        // 2. 获取要备份的会话（如果未传入则加载所有会话）
        NSArray<WFCCConversationInfo *> *backupConversations = conversations;
        if (!backupConversations || backupConversations.count == 0) {
            NSArray *conversationTypes = @[@(Single_Type), @(Group_Type), @(Channel_Type)];
            backupConversations = [[WFCCIMService sharedWFCIMService] getConversationInfos:conversationTypes
                                                                                      lines:@[@0]];
        }

        if (self.isCancelled) {
            [self cleanupIncompleteBackup];
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_Cancelled);
            });
            return;
        }

        NSProgress *parentProgress = [NSProgress progressWithTotalUnitCount:backupConversations.count];
        parentProgress.completedUnitCount = 0;

        // 收集所有会话的元数据
        NSMutableArray *conversationMetadata = [NSMutableArray array];
        int totalMessages = 0;
        int totalMediaFiles = 0;
        long long totalMediaSize = 0;
        long long firstMessageTime = LLONG_MAX;
        long long lastMessageTime = 0;

        // 3. 遍历每个会话
        for (WFCCConversationInfo *convInfo in backupConversations) {
            @autoreleasepool {
                if (self.isCancelled) break;

                // 3.1 创建会话目录
                NSString *convDirName = [self getConversationDirectoryName:convInfo];
                NSString *convDir = [conversationsDir stringByAppendingPathComponent:convDirName];

                [fileManager createDirectoryAtPath:convDir
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:nil];

                // 3.2 创建 media 子目录
                NSString *mediaDir = [convDir stringByAppendingPathComponent:@"media"];
                [fileManager createDirectoryAtPath:mediaDir
                      withIntermediateDirectories:YES
                                       attributes:nil
                                            error:nil];

                // 3.3 获取该会话的所有消息
                NSMutableArray *messagesArray = [NSMutableArray array];
                WFCCConversation *conversation = convInfo.conversation;
                long fromIndex = 0;
                int batchSize = kDefaultMessageBatchSize;
                int convMessageCount = 0;
                int convMediaCount = 0;

                while (YES) {
                    if (self.isCancelled) break;

                    @autoreleasepool {
                        NSArray<WFCCMessage *> *messages = [[WFCCIMService sharedWFCIMService]
                            getMessages:conversation
                            contentTypes:nil
                            from:fromIndex
                            count:batchSize
                            withUser:nil];

                        if (messages.count == 0) break;

                        for (WFCCMessage *msg in messages) {
                            if (self.isCancelled) break;

                            NSDictionary *msgDict = [self encodeMessage:msg
                                                           includeMedia:YES
                                                          mediaBaseDir:mediaDir];
                            [messagesArray addObject:msgDict];
                            convMessageCount++;

                            // 统计媒体文件（只有在确实备份了媒体文件时才统计）
                            if (msgDict[@"payload"][@"localMediaInfo"]) {
                                convMediaCount++;
                                totalMediaSize += [msgDict[@"mediaFileSize"] longLongValue];
                            }

                            // 统计时间范围
                            long long msgTime = msg.serverTime;
                            if (msgTime < firstMessageTime) firstMessageTime = msgTime;
                            if (msgTime > lastMessageTime) lastMessageTime = msgTime;
                        }

                        fromIndex = messages.firstObject.messageId;
                    }
                }

                if (self.isCancelled) {
                    [self cleanupIncompleteBackup];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        error(BackupError_Cancelled);
                    });
                    return;
                }

                // 3.4 保存 messages.json
                NSString *messagesJsonPath = [convDir stringByAppendingPathComponent:@"messages.json"];
                NSDictionary *messagesData = @{
                    @"version": kBackupVersion,
                    @"conversation": [self encodeConversationInfo:convInfo],
                    @"settings": @{
                        @"isTop": @(convInfo.isTop),
                        @"isSilent": @(convInfo.isSilent),
                        @"draft": convInfo.draft ?: @""
                    },
                    @"messages": messagesArray
                };

                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:messagesData
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&fmError];
                if (jsonData) {
                    [jsonData writeToFile:messagesJsonPath atomically:YES];

                    // 3.5 如果提供了密码，加密 messages.json
                    if (password && password.length > 0) {
                        [self encryptMessagesFile:messagesJsonPath password:password];
                    }
                }

                // 3.6 收集会话元数据
                totalMessages += convMessageCount;
                totalMediaFiles += convMediaCount;

                [conversationMetadata addObject:@{
                    @"conversationId": convDirName,
                    @"type": @(conversation.type),
                    @"target": conversation.target,
                    @"line": @(conversation.line),
                    @"messageCount": @(convMessageCount),
                    @"mediaCount": @(convMediaCount),
                    @"directory": convDirName
                }];

                parentProgress.completedUnitCount++;
                if (progress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progress(parentProgress);
                    });
                }
            }
        }

        if (self.isCancelled) {
            [self cleanupIncompleteBackup];
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_Cancelled);
            });
            return;
        }

        // 4. 创建 metadata.json
        [self createMetadataJSONForDirectory:directoryPath
                                withPassword:password
                              passwordHint:passwordHint
                            conversations:conversationMetadata
                              totalMessages:totalMessages
                            totalMediaFiles:totalMediaFiles
                             totalMediaSize:totalMediaSize
                           firstMessageTime:firstMessageTime
                            lastMessageTime:lastMessageTime];

        // 备份成功，清空备份路径
        self.currentBackupDirectory = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            success(directoryPath, totalMessages, totalMediaFiles, totalMediaSize);
        });
    });
}

- (void)restoreFromBackup:(NSString *)directoryPath
                 password:(NSString *)password
       overwriteExisting:(BOOL)overwriteExisting
                progress:(void(^)(NSProgress *))progress
                 success:(void(^)(int, int))success
                   error:(void(^)(int))error {

    // 参数验证
    if (!directoryPath || directoryPath.length == 0) {
        if (error) {
            error(BackupError_FileNotFound);
        }
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 1. 读取 metadata.json
        NSString *metadataPath = [directoryPath stringByAppendingPathComponent:@"metadata.json"];
        NSData *metadataJson = [NSData dataWithContentsOfFile:metadataPath];
        if (!metadataJson) {
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_FileNotFound);
            });
            return;
        }

        NSError *jsonError;
        NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:metadataJson
                                                                options:0
                                                                  error:&jsonError];
        if (!metadata || jsonError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_InvalidFormat);
            });
            return;
        }

        // 2. 检查是否需要密码
        BOOL isEncrypted = [metadata[@"encryption"][@"enabled"] boolValue];
        if (isEncrypted && (!password || password.length == 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                error(BackupError_InvalidPassword);
            });
            return;
        }

        // 3. 遍历会话列表
        NSArray *convList = metadata[@"conversations"];
        NSProgress *parentProgress = [NSProgress progressWithTotalUnitCount:convList.count];

        int totalMessages = 0;
        int totalMedia = 0;

        for (NSDictionary *convInfo in convList) {
            @autoreleasepool {
                // 会话目录在 conversations/ 子目录下
                NSString *conversationsDir = [directoryPath stringByAppendingPathComponent:@"conversations"];
                NSString *convDir = [conversationsDir stringByAppendingPathComponent:convInfo[@"directory"]];
                NSString *messagesPath = [convDir stringByAppendingPathComponent:@"messages.json"];

                // 3.1 读取 messages.json
                NSData *messagesJsonData = [NSData dataWithContentsOfFile:messagesPath];
                if (!messagesJsonData) {
                    continue;
                }

                // 3.2 如果加密，先解密
                if (isEncrypted) {
                    // 3.2.1 先解析加密的 JSON 结构（包含 salt、iv、data）
                    NSError *parseError;
                    NSDictionary *encryptedDict = [NSJSONSerialization JSONObjectWithData:messagesJsonData
                                                                              options:0
                                                                                error:&parseError];
                    if (!encryptedDict || parseError) {
                        NSLog(@"[WFCCMessageBackupManager] Failed to parse encrypted messages for %@: %@",
                              convInfo[@"directory"], parseError);
                        continue;
                    }

                    // 3.2.2 解密数据
                    NSError *cryptoError;
                    messagesJsonData = [WFCCBackupCrypto decryptData:encryptedDict
                                                              password:password
                                                                 error:&cryptoError];
                    if (!messagesJsonData) {
                        NSLog(@"[WFCCMessageBackupManager] Failed to decrypt messages for %@: %@",
                              convInfo[@"directory"], cryptoError);
                        continue;
                    }
                }

                // 3.3 解析 JSON 得到消息数据
                NSError *jsonError;
                NSDictionary *convData = [NSJSONSerialization JSONObjectWithData:messagesJsonData
                                                                        options:0
                                                                          error:&jsonError];
                if (!convData || jsonError) {
                    NSLog(@"[WFCCMessageBackupManager] Failed to parse messages for %@: %@",
                          convInfo[@"directory"], jsonError);
                    continue;
                }

                // 3.4 恢复消息到数据库
                NSString *mediaDir = [convDir stringByAppendingPathComponent:@"media"];
                int mediaCount = 0;
                int msgCount = [self restoreMessagesFromDirectoryData:convData
                                                     overwriteExisting:overwriteExisting
                                                          mediaBaseDir:mediaDir
                                                       mediaCountOut:&mediaCount];
                totalMessages += msgCount;
                totalMedia += mediaCount; // 只统计实际有媒体文件的消息

                parentProgress.completedUnitCount++;
                if (progress) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progress(parentProgress);
                    });
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            success(totalMessages, totalMedia);
        });
    });
}

- (NSDictionary *)getDirectoryBackupInfo:(NSString *)directoryPath {
    if (!directoryPath) {
        return nil;
    }

    // 读取 metadata.json
    NSString *metadataPath = [directoryPath stringByAppendingPathComponent:@"metadata.json"];
    NSData *metadataJson = [NSData dataWithContentsOfFile:metadataPath];
    if (!metadataJson) {
        return nil;
    }

    NSError *error;
    NSDictionary *metadata = [NSJSONSerialization JSONObjectWithData:metadataJson
                                                            options:0
                                                              error:&error];
    if (!metadata || error) {
        return nil;
    }

    BOOL isEncrypted = [metadata[@"encryption"][@"enabled"] boolValue];

    return @{
        @"format": @"directory",
        @"isEncrypted": @(isEncrypted),
        @"version": metadata[@"version"],
        @"backupTime": metadata[@"backupTime"],
        @"userId": metadata[@"userId"],
        @"totalConversations": @([metadata[@"conversations"] count]),
        @"totalMessages": metadata[@"statistics"][@"totalMessages"] ?: @0,
        @"mediaFileCount": metadata[@"statistics"][@"mediaFileCount"] ?: @0,
        @"mediaTotalSize": metadata[@"statistics"][@"mediaTotalSize"] ?: @0,
        @"hasPasswordHint": @([metadata[@"encryption"][@"passwordHint"] length] > 0)
    };
}

@end
