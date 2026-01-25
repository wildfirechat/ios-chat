//
//  WFCCBackupCrypto.h
//  WFChatClient
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 备份加密工具类
 * 提供备份文件的加密和解密功能
 */
@interface WFCCBackupCrypto : NSObject

/**
 * 从密码派生加密密钥
 * @param password 用户密码
 * @param salt 盐值（随机生成）
 * @param iterations PBKDF2 迭代次数
 * @return 派生的密钥数据（32字节，用于 AES-256）
 */
+ (NSData *)deriveKeyFromPassword:(NSString *)password
                            salt:(NSData *)salt
                      iterations:(NSUInteger)iterations;

/**
 * 加密数据
 * @param data 明文数据
 * @param password 用户密码
 * @param error 错误输出
 * @return 加密结果字典，包含 salt、iv、data、authTag
 */
+ (nullable NSDictionary *)encryptData:(NSData *)data
                            password:(NSString *)password
                               error:(NSError **)error;

/**
 * 解密数据
 * @param encryptedData 加密数据字典（包含 salt, iv, data, authTag）
 * @param password 用户密码
 * @param error 错误输出
 * @return 解密后的明文数据
 */
+ (nullable NSData *)decryptData:(NSDictionary *)encryptedData
                       password:(NSString *)password
                          error:(NSError **)error;

/**
 * 验证密码
 * @param encryptedData 加密数据字典
 * @param password 用户密码
 * @return 密码是否正确
 */
+ (BOOL)verifyPassword:(NSDictionary *)encryptedData
              password:(NSString *)password;

/**
 * 生成随机数据
 * @param size 数据大小（字节数）
 * @return 随机数据
 */
+ (NSData *)generateRandomDataOfSize:(NSUInteger)size;

/**
 * 计算文件的 MD5
 * @param filePath 文件路径
 * @return MD5 字符串（32位十六进制）
 */
+ (nullable NSString *)calculateMD5ForFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
