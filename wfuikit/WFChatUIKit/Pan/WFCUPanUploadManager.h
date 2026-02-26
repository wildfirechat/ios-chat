//
//  WFCUPanUploadManager.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WFCUPanUploadProgressBlock)(CGFloat progress);
typedef void(^WFCUPanUploadSuccessBlock)(NSString *storageUrl, int64_t size, NSString *md5);
typedef void(^WFCUPanUploadErrorBlock)(NSString *errorMessage);

@interface WFCUPanUploadManager : NSObject

+ (instancetype)sharedManager;

/// 上传文件到对象存储
/// @param filePath 本地文件路径
/// @param progressBlock 进度回调
/// @param successBlock 成功回调，返回存储URL、文件大小和MD5
/// @param errorBlock 失败回调
- (void)uploadFile:(NSString *)filePath
          progress:(WFCUPanUploadProgressBlock)progressBlock
           success:(WFCUPanUploadSuccessBlock)successBlock
             error:(WFCUPanUploadErrorBlock)errorBlock;

/// 计算文件MD5
- (NSString *)md5ForFile:(NSString *)filePath;

/// 获取文件MIME类型
- (NSString *)mimeTypeForFile:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
