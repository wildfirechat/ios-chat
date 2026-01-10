//
//  WFCCMessageBackupManager.h
//  WFChatClient
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCConversationInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class NSProgress;

// 备份模式
typedef NS_ENUM(NSInteger, BackupMode) {
    BackupMode_MessageOnly,          // 仅备份消息
    BackupMode_MessageWithMedia       // 备份消息和媒体文件
};

// 备份错误码
typedef NS_ENUM(NSInteger, BackupError) {
    BackupError_NoError = 0,
    BackupError_FileNotFound = 1001,
    BackupError_InvalidFormat = 1002,
    BackupError_IOError = 1003,
    BackupError_OutOfSpace = 1004,
    BackupError_Cancelled = 1005,
    BackupError_EncryptionFailed = 3001,
    BackupError_DecryptionFailed = 3002,
    BackupError_WrongPassword = 3003,
    BackupError_InvalidPassword = 3004,
    BackupError_NotEncrypted = 3006,
    BackupError_RestoreFailed = 4001
};

/**
 * 消息备份管理器
 * 负责聊天消息的备份和恢复功能
 */
@interface WFCCMessageBackupManager : NSObject

#pragma mark - 单例

/**
 * 获取单例
 */
+ (instancetype)sharedManager;

#pragma mark - 创建备份

/**
 * 创建基于目录的备份（v2.0格式）
 * 每个会话独立存储，只加密消息JSON文件，媒体文件保持明文
 * @param directoryPath 备份文件夹路径
 * @param conversations 要备份的会话列表（如果为nil则备份所有会话）
 * @param password 加密密码（传nil表示不加密messages.json）
 * @param passwordHint 密码提示（可选）
 * @param progress 进度回调
 * @param success 成功回调，返回备份文件夹路径、消息数、媒体数、媒体总大小
 * @param error 失败回调
 */
- (void)createDirectoryBasedBackup:(NSString *)directoryPath
                      conversations:(nullable NSArray<WFCCConversationInfo *> *)conversations
                          password:(nullable NSString *)password
                      passwordHint:(nullable NSString *)passwordHint
                           progress:(nullable void(^)(NSProgress *progress))progress
                            success:(void(^)(NSString *backupPath, int msgCount, int mediaCount, long long mediaSize))success
                              error:(void(^)(int errorCode))error;

#pragma mark - 恢复备份

/**
 * 从目录备份恢复（v2.0格式）
 * @param directoryPath 备份文件夹路径
 * @param password 解密密码（如果备份未加密则传 nil）
 * @param overwriteExisting 是否覆盖已存在的消息
 * @param progress 进度回调
 * @param success 成功回调，返回恢复的消息数和媒体数
 * @param error 失败回调
 */
- (void)restoreFromBackup:(NSString *)directoryPath
                 password:(nullable NSString *)password
       overwriteExisting:(BOOL)overwriteExisting
                progress:(nullable void(^)(NSProgress *progress))progress
                 success:(void(^)(int msgCount, int mediaCount))success
                   error:(void(^)(int errorCode))error;

#pragma mark - 查询和验证

/**
 * 获取目录备份信息
 * @param directoryPath 备份文件夹路径
 * @return 备份信息字典
 */
- (nullable NSDictionary *)getDirectoryBackupInfo:(NSString *)directoryPath;

#pragma mark - 取消操作

/**
 * 取消当前正在进行的备份或恢复操作
 */
- (void)cancelCurrentOperation;

@end

NS_ASSUME_NONNULL_END
