# 备份系统设计文档

## 概述

本文档描述了野火IM iOS客户端的备份系统架构和实现细节。备份系统支持将聊天消息和媒体文件备份到本地存储，并支持从备份中恢复数据。

**版本信息**
- v1: 目录结构格式（当前版本）
- 版本号直接使用 "1" 而非 "1.0" 或 "2.0"

## 系统架构

### 核心组件

1. **WFCCMessageBackupManager** - 备份管理器
   - 负责备份和恢复的核心逻辑
   - 单例模式，提供统一的API接口

2. **WFCCBackupCrypto** - 加密工具
   - 提供AES-256-CBC加密
   - PBKDF2-SHA256密钥派生

3. **UI组件**
   - WFCBackupAndRestoreViewController - 主界面
   - WFCConversationSelectViewController - 会话选择
   - WFCBackupOptionsViewController - 备份选项
   - WFCBackupProgressViewController - 进度显示
   - WFCBackupListViewController - 备份列表
   - WFCRestoreOptionsViewController - 恢复选项

## 备份格式 v1

### 目录结构

```
backup_2025-01-09_14-30-45/              # 备份文件夹（时间戳命名）
├── metadata.json                         # 元数据文件（不加密）
└── conversations/                        # 会话子目录
    ├── conv_type1_userA_line0/          # 单个会话目录
    │   ├── messages.json                # 加密消息文件
    │   └── media/                       # 媒体文件目录（不加密）
    │       ├── {md5前16位}.jpg
    │       └── {md5前16位}.mp4
    ├── conv_type2_groupB_line0/
    │   ├── messages.json
    │   └── media/
    └── ...
```

### 会话目录命名规则

格式：`conv_{type}_{target}_{line}`

示例：
- 单聊: `conv_type1_user123_line0`
- 群聊: `conv_type2_group456_line0`
- 频道: `conv_type3_channel789_line0`

**注意**: target字段经过URL编码以处理特殊字符

### metadata.json 结构

```json
{
  "version": "1",
  "format": "directory",
  "backupTime": "2025-01-09T14:30:45Z",
  "userId": "user123",
  "appType": "ios-chat",
  "backupMode": "message_with_media",
  "encryption": {
    "enabled": true,
    "algorithm": "AES-256-CBC",
    "keyDerivation": "PBKDF2-SHA256",
    "passwordHint": "密码提示"
  },
  "statistics": {
    "totalConversations": 15,
    "totalMessages": 3250,
    "mediaFileCount": 48,
    "mediaTotalSize": 52428800,
    "timeRange": {
      "firstMessageTime": 1704800000000,
      "lastMessageTime": 1704809445000
    }
  },
  "conversations": [
    {
      "conversationId": "conv_type1_userA_line0",
      "type": 1,
      "target": "userA",
      "line": 0,
      "messageCount": 120,
      "mediaCount": 5,
      "directory": "conv_type1_userA_line0"
    }
  ]
}
```

### messages.json 结构（加密）

```json
{
  "version": "1",
  "conversation": {
    "type": 1,
    "target": "userA",
    "line": 0
  },
  "settings": {
    "isTop": 0,
    "isSilent": false,
    "draft": "草稿内容"
  },
  "messages": [
    {
      "messageUid": 1704800000000001,
      "fromUser": "userA",
      "toUsers": ["userB"],
      "direction": 0,
      "status": 0,
      "timestamp": 1704800000000,
      "localExtra": "",
      "payload": {
        "contentType": 1,
        "searchableContent": "消息内容",
        "pushContent": "",
        "content": "",
        "binaryContent": "base64编码数据",
        "localContent": "",
        "mentionedType": 0,
        "mentionedTargets": [],
        "extra": "",
        "notLoaded": false,
        "mediaType": 0,
        "remoteMediaUrl": "https://...",
        "localMediaInfo": {
          "relativePath": "media/abc123.jpg",
          "fileId": "abc123def456",
          "fileSize": 102400,
          "md5": "hash值"
        }
      }
    }
  ]
}
```

## 加密策略

### 加密范围

**加密文件**：
- `conversations/{conv_id}/messages.json`

**不加密文件**：
- `metadata.json`
- `conversations/{conv_id}/media/*`

### 加密算法

- **算法**: AES-256-CBC
- **密钥派生**: PBKDF2-SHA256
- **迭代次数**: 100,000
- **Salt**: 16字节随机
- **IV**: 16字节随机

### 加密流程

1. 生成16字节随机salt
2. 使用密码 + salt 通过PBKDF2派生32字节密钥
3. 生成16字节随机IV
4. 使用AES-256-CBC加密数据
5. 返回包含salt、IV、密文的字典

## API 接口

### 创建备份

```objc
// 创建基于目录的备份（v1格式）
- (void)createDirectoryBasedBackup:(NSString *)directoryPath
                      conversations:(nullable NSArray<WFCCConversationInfo *> *)conversations
                          password:(nullable NSString *)password
                      passwordHint:(nullable NSString *)passwordHint
                           progress:(nullable void(^)(NSProgress *progress))progress
                            success:(void(^)(NSString *backupPath, int msgCount, int mediaCount, long long mediaSize))success
                              error:(void(^)(int errorCode))error;
```

**参数说明**:
- `directoryPath`: 备份文件夹路径（自动创建）
- `conversations`: 要备份的会话列表（传nil则备份所有会话）
- `password`: 加密密码（传nil表示不加密messages.json）
- `passwordHint`: 密码提示
- `progress`: 进度回调，0.0-1.0
- `success`: 成功回调，返回备份文件夹路径、消息数、媒体数、媒体总大小
- `error`: 失败回调，返回错误码

### 恢复备份

```objc
// 从目录备份恢复（v1格式）
- (void)restoreFromBackup:(NSString *)directoryPath
                 password:(nullable NSString *)password
       overwriteExisting:(BOOL)overwriteExisting
                progress:(nullable void(^)(NSProgress *progress))progress
                 success:(void(^)(int msgCount, int mediaCount))success
                   error:(void(^)(int errorCode))error;
```

**参数说明**:
- `directoryPath`: 备份文件夹路径
- `password`: 解密密码（如果备份未加密则传 nil）
- `overwriteExisting`: 是否覆盖已存在的消息
- `progress`: 进度回调
- `success`: 返回恢复的消息数和媒体数
- `error`: 失败回调

### 获取备份信息

```objc
// 获取目录备份信息（v1格式）
- (nullable NSDictionary *)getDirectoryBackupInfo:(NSString *)directoryPath;
```

**返回字段**:
```objc
@{
  @"format": @"directory",           // 格式类型
  @"isEncrypted": @YES,              // 是否加密
  @"version": @"1",                  // 版本号
  @"backupTime": @"2025-01-09...",   // 备份时间
  @"userId": @"user123",             // 用户ID
  @"totalConversations": @15,        // 会话总数
  @"totalMessages": @3250,           // 消息总数
  @"mediaFileCount": @48,            // 媒体文件数
  @"mediaTotalSize": @52428800,      // 媒体文件总大小
  @"hasPasswordHint": @YES           // 是否有密码提示
}
```

## 错误码

```objc
typedef NS_ENUM(NSInteger, BackupError) {
    BackupError_NoError = 0,
    BackupError_FileNotFound = 1001,       // 文件未找到
    BackupError_InvalidFormat = 1002,      // 格式无效
    BackupError_IOError = 1003,            // IO错误
    BackupError_OutOfSpace = 1004,         // 磁盘空间不足
    BackupError_Cancelled = 1005,          // 用户取消
    BackupError_EncryptionFailed = 3001,   // 加密失败
    BackupError_DecryptionFailed = 3002,   // 解密失败
    BackupError_WrongPassword = 3003,      // 密码错误
    BackupError_InvalidPassword = 3004,    // 密码无效
    BackupError_NotEncrypted = 3006,       // 备份未加密
    BackupError_RestoreFailed = 4001       // 恢复失败
};
```

## 使用示例

### 创建备份

```objc
// 1. 生成备份路径
NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
NSString *folderName = [NSString stringWithFormat:@"backup_%@",
                       [formatter stringFromDate:[NSDate date]]];

NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                NSUserDomainMask,
                                                                YES).firstObject;
NSString *backupPath = [documentsPath stringByAppendingPathComponent:@"Backups"];
backupPath = [backupPath stringByAppendingPathComponent:folderName];

// 2. 选择要备份的会话（可选，传nil则备份所有）
NSArray<WFCCConversationInfo *> *selectedConversations = nil; // 或指定具体会话

// 3. 开始备份
[[WFCCMessageBackupManager sharedManager] createDirectoryBasedBackup:backupPath
                                                      conversations:selectedConversations
                                                          password:@"myPassword"
                                                      passwordHint:@"我的生日"
                                                           progress:^(NSProgress *progress) {
    NSLog(@"备份进度: %.0f%%", progress.fractionCompleted * 100);
} success:^(NSString *backupPath, int msgCount, int mediaCount, long long mediaSize) {
    NSLog(@"备份成功: %@", backupPath);
    NSLog(@"消息数: %d, 媒体数: %d, 大小: %lld bytes", msgCount, mediaCount, mediaSize);
} error:^(int errorCode) {
    NSLog(@"备份失败: %d", errorCode);
}];
```

### 恢复备份

```objc
[[WFCCMessageBackupManager sharedManager] restoreFromBackup:backupPath
                                                 password:@"myPassword"
                                       overwriteExisting:YES
                                                progress:^(NSProgress *progress) {
    NSLog(@"恢复进度: %.0f%%", progress.fractionCompleted * 100);
} success:^(int msgCount, int mediaCount) {
    NSLog(@"恢复成功: %d条消息, %d个媒体文件", msgCount, mediaCount);
} error:^(int errorCode) {
    NSLog(@"恢复失败: %d", errorCode);
}];
```

## 取消操作

### 取消当前操作

```objc
// 取消正在进行的备份或恢复操作
[[WFCCMessageBackupManager sharedManager] cancelCurrentOperation];
```

**重要说明**：
- 取消备份时会自动清理已创建的不完整备份目录
- 清理操作会删除整个备份文件夹及其所有子目录
- UI层应提示用户"正在清理已创建的文件..."
- 取消恢复时不做回滚操作（已插入的消息会保留）

## 性能优化

### 内存管理

- 使用`@autoreleasepool`包裹循环体
- 批量处理消息（每批100条）
- 及时释放大块数据

### 进度报告

- 按会话数分派进度
- 避免频繁主线程切换
- 使用`NSProgress`父子进度机制

### 加密性能

- 每个会话单独加密（可并发）
- 使用MD5前16位命名媒体文件
- 避免重复加密metadata

## 安全考虑

1. **密码安全**
   - 密码不以明文形式存储
   - 使用PBKDF2增强密码强度
   - 支持密码提示（不包含实际密码信息）

2. **数据分离**
   - 敏感数据加密（消息内容）
   - 非敏感数据明文（元数据、媒体）
   - 便于查看备份基本信息

3. **文件完整性**
   - 媒体文件使用MD5校验
   - JSON格式验证
   - 加密数据完整性检查

## 故障恢复

### 备份损坏

如果备份文件损坏：

1. 检查metadata.json是否存在
2. 验证会话目录完整性
3. 逐个检查messages.json
4. 跳过损坏的会话，恢复其他会话

### 密码丢失

如果忘记密码：

1. 查看metadata.json中的passwordHint
2. 尝试常用密码
3. 无其他恢复方式（加密设计）

### 媒体文件缺失

如果媒体文件丢失：

1. messages.json仍可恢复
2. 媒体消息会显示下载失败
3. 可手动重新下载媒体文件

## 最佳实践

1. **定期备份**
   - 建议每周至少备份一次
   - 重要对话后立即备份

2. **密码管理**
   - 使用强密码
   - 记住密码提示
   - 不要丢失密码

3. **存储管理**
   - 定期清理旧备份
   - 保留多个备份副本
   - 考虑导出到iCloud或电脑

4. **验证备份**
   - 备份后验证完整性
   - 定期测试恢复流程
   - 检查媒体文件是否完整

## 未来扩展

### 可能的改进方向

1. **增量备份**
   - 只备份新增消息
   - 减少备份时间和空间

2. **云端备份**
   - 支持iCloud Drive
   - 支持WebDAV
   - 支持自定义服务器

3. **部分恢复**
   - 选择性恢复某些会话
   - 按时间范围恢复

4. **备份合并**
   - 合并多个备份
   - 去重消息

5. **压缩优化**
   - 使用zip格式
   - 压缩媒体文件

## 技术支持

如有问题或建议，请联系：

- **GitHub Issues**: https://github.com/wildfirechat/ios-chat/issues
- **论坛**: http://bbs.wildfirechat.cn/
- **邮箱**: support@wildfirechat.cn

---

**文档版本**: 2.0
**最后更新**: 2025-01-09
**维护者**: WildFireChat Team
