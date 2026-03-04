//
//  WFCUPanUploadManager.m
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import "WFCUPanUploadManager.h"
#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCMessageContent.h>
#import <CommonCrypto/CommonCrypto.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation WFCUPanUploadManager

+ (instancetype)sharedManager {
    static WFCUPanUploadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WFCUPanUploadManager alloc] init];
    });
    return instance;
}

- (void)uploadFile:(NSString *)filePath
          progress:(WFCUPanUploadProgressBlock)progressBlock
           success:(WFCUPanUploadSuccessBlock)successBlock
             error:(WFCUPanUploadErrorBlock)errorBlock {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        if (errorBlock) errorBlock(@"文件不存在");
        return;
    }
    
    // 获取文件属性
    NSError *error = nil;
    NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:&error];
    if (error) {
        if (errorBlock) errorBlock(@"获取文件信息失败");
        return;
    }
    
    int64_t fileSize = [attrs fileSize];
    NSString *fileName = [filePath lastPathComponent];
    NSString *md5 = [self md5ForFile:filePath];
    
    // 使用 WildFireChat SDK 上传文件
    // Media_Type_FILE = 4 用于通用文件上传
    [[WFCCIMService sharedWFCIMService] uploadMediaFile:filePath
                                               mediaType:Media_Type_PAN
                                                 success:^(NSString *remoteUrl) {
        // 上传成功，返回存储URL
        if (successBlock) {
            successBlock(remoteUrl, fileSize, md5);
        }
    } progress:^(long uploaded, long total) {
        // 上传进度回调
        if (progressBlock && total > 0) {
            CGFloat progress = (CGFloat)uploaded / (CGFloat)total;
            progressBlock(progress);
        }
    } error:^(int error_code) {
        // 上传失败
        if (errorBlock) {
            errorBlock([NSString stringWithFormat:@"上传失败(错误码:%d)", error_code]);
        }
    }];
}

- (NSString *)md5ForFile:(NSString *)filePath {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!handle) return nil;
    
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    
    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:4096];
        if ([fileData length] == 0) {
            done = YES;
        } else {
            CC_MD5_Update(&md5, [fileData bytes], (CC_LONG)[fileData length]);
        }
    }
    [handle closeFile];
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

- (NSString *)mimeTypeForFile:(NSString *)filePath {
    NSString *extension = [filePath pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, 
                                                            (__bridge CFStringRef)extension, 
                                                            NULL);
    if (uti) {
        CFStringRef mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mimeType) {
            NSString *result = (__bridge_transfer NSString *)mimeType;
            return result;
        }
    }
    return @"application/octet-stream";
}

@end
