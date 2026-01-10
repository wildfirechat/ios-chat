//
//  WFCCBackupCrypto.m
//  WFChatClient
//
//  Created by Claude on 2025-01-09.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCCBackupCrypto.h"
#import <Security/Security.h>

@implementation WFCCBackupCrypto

#pragma mark - Constants

static const NSUInteger kKeySize = kCCKeySizeAES256;           // 32 bytes
static const NSUInteger kSaltSize = 16;                       // 128 bits
static const NSUInteger kIVSize = kCCBlockSizeAES128;         // 16 bytes for AES128
static const NSUInteger kPBKDF2Iterations = 100000;           // 推荐值

#pragma mark - Key Derivation

+ (NSData *)deriveKeyFromPassword:(NSString *)password
                            salt:(NSData *)salt
                      iterations:(NSUInteger)iterations {

    if (!password || !salt || password.length == 0 || salt.length == 0) {
        return nil;
    }

    // 将密码转换为 UTF8 数据
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    if (!passwordData) {
        return nil;
    }

    // 分配密钥存储空间
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kKeySize];

    // PBKDF2 派生
    int result = CCKeyDerivationPBKDF(
        kCCPBKDF2,                        // 算法
        passwordData.bytes,                // 密码
        passwordData.length,               // 密码长度
        salt.bytes,                        // 盐
        salt.length,                       // 盐长度
        kCCPRFHmacAlgSHA256,               // 伪随机函数
        (unsigned int)iterations,          // 迭代次数
        derivedKey.mutableBytes,           // 输出密钥
        derivedKey.length                  // 密钥长度
    );

    if (result != kCCSuccess) {
        NSLog(@"[WFCCBackupCrypto] Key derivation failed: %d", result);
        return nil;
    }

    return [derivedKey copy];
}

#pragma mark - Encryption

+ (NSDictionary *)encryptData:(NSData *)data
                    password:(NSString *)password
                       error:(NSError **)error {

    if (!data || !password || password.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid parameters"}];
        }
        return nil;
    }

    // 1. 生成随机 Salt
    NSData *salt = [self generateRandomDataOfSize:kSaltSize];
    if (!salt) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to generate salt"}];
        }
        return nil;
    }

    // 2. 派生密钥
    NSData *key = [self deriveKeyFromPassword:password
                                        salt:salt
                                  iterations:kPBKDF2Iterations];
    if (!key) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:1003
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to derive key"}];
        }
        return nil;
    }

    // 3. 生成随机 IV
    NSData *iv = [self generateRandomDataOfSize:kIVSize];
    if (!iv) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:1004
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to generate IV"}];
        }
        return nil;
    }

    // 4. 使用 AES-256-CBC 加密
    size_t bufferSize = data.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t dataOutMoved = 0;
    CCCryptorStatus status = CCCrypt(
        kCCEncrypt,                          // 加密
        kCCAlgorithmAES,                     // AES 算法
        kCCOptionPKCS7Padding,               // PKCS7 填充
        key.bytes,                           // 密钥
        key.length,                          // 密钥长度
        iv.bytes,                            // IV
        data.bytes,                          // 输入数据
        data.length,                         // 输入长度
        buffer,                              // 输出缓冲区
        bufferSize,                          // 输出缓冲区大小
        &dataOutMoved                        // 实际输出长度
    );

    if (status != kCCSuccess) {
        free(buffer);
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: @"Encryption failed"}];
        }
        return nil;
    }

    NSData *encryptedData = [NSData dataWithBytes:buffer length:dataOutMoved];
    free(buffer);

    // 5. 返回加密结果
    return @{
        @"salt": [salt base64EncodedStringWithOptions:0],
        @"iv": [iv base64EncodedStringWithOptions:0],
        @"data": [encryptedData base64EncodedStringWithOptions:0],
        @"iterations": @(kPBKDF2Iterations)
    };
}

#pragma mark - Decryption

+ (NSData *)decryptData:(NSDictionary *)encryptedData
               password:(NSString *)password
                  error:(NSError **)error {

    // 1. 提取加密参数
    NSData *salt = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"salt"] options:0];
    NSData *iv = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"iv"] options:0];
    NSData *ciphertext = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"data"] options:0];
    NSUInteger iterations = [encryptedData[@"iterations"] unsignedIntegerValue];

    if (!salt || !iv || !ciphertext) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:2001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid encrypted data format"}];
        }
        return nil;
    }

    // 2. 派生密钥
    NSData *key = [self deriveKeyFromPassword:password
                                        salt:salt
                                  iterations:iterations];
    if (!key) {
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:2002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to derive key"}];
        }
        return nil;
    }

    // 3. 使用 AES-256-CBC 解密
    size_t bufferSize = ciphertext.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t dataOutMoved = 0;
    CCCryptorStatus status = CCCrypt(
        kCCDecrypt,                          // 解密
        kCCAlgorithmAES,                     // AES 算法
        kCCOptionPKCS7Padding,               // PKCS7 填充
        key.bytes,                           // 密钥
        key.length,                          // 密钥长度
        iv.bytes,                            // IV
        ciphertext.bytes,                    // 输入数据
        ciphertext.length,                   // 输入长度
        buffer,                              // 输出缓冲区
        bufferSize,                          // 输出缓冲区大小
        &dataOutMoved                        // 实际输出长度
    );

    if (status != kCCSuccess) {
        free(buffer);
        if (error) {
            *error = [NSError errorWithDomain:@"WFCCBackupCryptoError"
                                         code:2003
                                     userInfo:@{NSLocalizedDescriptionKey: @"Decryption failed"}];
        }
        return nil;
    }

    NSData *decryptedData = [NSData dataWithBytes:buffer length:dataOutMoved];
    free(buffer);

    return decryptedData;
}

#pragma mark - Password Verification

+ (BOOL)verifyPassword:(NSDictionary *)encryptedData
              password:(NSString *)password {

    if (!encryptedData || !password) {
        return NO;
    }

    // 尝试解密来验证密码
    NSData *salt = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"salt"] options:0];
    NSData *iv = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"iv"] options:0];
    NSData *ciphertext = [[NSData alloc] initWithBase64EncodedString:encryptedData[@"data"] options:0];
    NSUInteger iterations = [encryptedData[@"iterations"] unsignedIntegerValue];

    if (!salt || !iv || !ciphertext) {
        return NO;
    }

    // 派生密钥
    NSData *key = [self deriveKeyFromPassword:password
                                        salt:salt
                                  iterations:iterations];
    if (!key) {
        return NO;
    }

    // 尝试解密（只验证是否能成功解密）
    size_t bufferSize = ciphertext.length + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);

    size_t dataOutMoved = 0;
    CCCryptorStatus status = CCCrypt(
        kCCDecrypt,
        kCCAlgorithmAES,
        kCCOptionPKCS7Padding,
        key.bytes,
        key.length,
        iv.bytes,
        ciphertext.bytes,
        ciphertext.length,
        buffer,
        bufferSize,
        &dataOutMoved
    );

    free(buffer);

    return (status == kCCSuccess);
}

#pragma mark - Helper Methods

+ (NSData *)generateRandomDataOfSize:(NSUInteger)size {
    if (size == 0) {
        return nil;
    }

    NSMutableData *data = [NSMutableData dataWithLength:size];
    int result = SecRandomCopyBytes(kSecRandomDefault, size, data.mutableBytes);

    return (result == errSecSuccess) ? [data copy] : nil;
}

+ (NSString *)calculateMD5ForFile:(NSString *)filePath {
    if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return nil;
    }

    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        return nil;
    }

    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, md5Buffer);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", md5Buffer[i]];
    }

    return output;
}

@end
