//
//  WFCUPanService.h
//  WFChatUIKit
//
//  Created by WF Chat on 2025/2/24.
//  Copyright © 2025 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUPanSpace.h"
#import "WFCUPanFile.h"

NS_ASSUME_NONNULL_BEGIN

@protocol WFCUPanService <NSObject>

/// 获取所有可访问的空间列表
- (void)getSpacesWithSuccess:(void(^)(NSArray<WFCUPanSpace *> *spaces))successBlock
                       error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 获取我的空间（只返回我自己的两个空间：公共+私有）
- (void)getMySpacesWithSuccess:(void(^)(NSArray<WFCUPanSpace *> *spaces))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 获取指定用户的公共空间
- (void)getUserPublicSpace:(NSString *)userId
                   success:(void(^)(WFCUPanSpace *space))successBlock
                     error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 获取空间内文件列表
- (void)getSpaceFiles:(NSInteger)spaceId
             parentId:(NSInteger)parentId
              success:(void(^)(NSArray<WFCUPanFile *> *files))successBlock
                error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 创建文件夹
- (void)createFolder:(NSInteger)spaceId
            parentId:(NSInteger)parentId
                name:(NSString *)name
             success:(void(^)(WFCUPanFile *file))successBlock
               error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 创建文件记录（上传完成后调用）
- (void)createFile:(NSInteger)spaceId
          parentId:(NSInteger)parentId
              name:(NSString *)name
              size:(int64_t)size
          mimeType:(NSString *)mimeType
               md5:(NSString *)md5
        storageUrl:(NSString *)storageUrl
              copy:(BOOL)copy
           success:(void(^)(WFCUPanFile *file))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 删除文件/文件夹
- (void)deleteFile:(NSInteger)fileId
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 获取文件下载URL
- (void)getFileDownloadUrl:(NSInteger)fileId
                   success:(void(^)(NSString *url))successBlock
                     error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 检查空间写入权限
- (void)checkSpaceWritePermission:(NSInteger)spaceId
                          success:(void(^)(BOOL hasPermission))successBlock
                            error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 检查上传权限（与 checkSpaceWritePermission 相同）
- (void)checkUploadPermission:(NSInteger)spaceId
                      success:(void(^)(BOOL hasPermission))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 移动文件/文件夹
- (void)moveFile:(NSInteger)fileId
         toSpace:(NSInteger)targetSpaceId
        parentId:(NSInteger)targetParentId
         success:(void(^)(void))successBlock
           error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 重命名文件/文件夹
- (void)renameFile:(NSInteger)fileId
           newName:(NSString *)newName
           success:(void(^)(void))successBlock
             error:(void(^)(int errorCode, NSString *message))errorBlock;

/// 复制文件/文件夹到其他空间（跨空间复制，不删除原文件）
- (void)copyFile:(NSInteger)fileId
         toSpace:(NSInteger)targetSpaceId
        parentId:(NSInteger)targetParentId
         success:(void(^)(void))successBlock
           error:(void(^)(int errorCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
