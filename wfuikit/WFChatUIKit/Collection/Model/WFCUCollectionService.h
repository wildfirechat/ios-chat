//
//  WFCUCollectionService.h
//  WFChat UIKit
//
//  Created by WF Chat on 2025/2/14.
//  Copyright © 2025年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUCollection.h"

NS_ASSUME_NONNULL_BEGIN

@class WFCUCollection;

@protocol WFCUCollectionService <NSObject>

/**
 * 创建接龙
 * POST /api/collections
 * @param groupId 群ID
 * @param title 接龙标题
 * @param desc 接龙描述（可选）
 * @param template 模板（可选）
 * @param expireType 过期类型 0=无限期 1=有限期
 * @param expireAt 过期时间戳（可选）
 * @param maxParticipants 最大参与人数（0表示无限制）
 * @param successBlock 成功回调，返回创建的接龙对象
 * @param errorBlock 失败回调
 */
- (void)createCollection:(NSString *)groupId
                   title:(NSString *)title
                    desc:(nullable NSString *)desc
                template:(nullable NSString *)template
              expireType:(int)expireType
                expireAt:(long)expireAt
         maxParticipants:(int)maxParticipants
                 success:(void(^)(WFCUCollection *collection))successBlock
                   error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 获取接龙详情
 * POST /api/collections/{collectionId}/detail
 * @param collectionId 接龙ID
 * @param groupId 群ID（用于校验）
 * @param successBlock 成功回调
 * @param errorBlock 失败回调
 */
- (void)getCollection:(long)collectionId
              groupId:(NSString *)groupId
              success:(void(^)(WFCUCollection *collection))successBlock
                error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 参与或编辑接龙
 * POST /api/collections/{collectionId}/join
 * @param collectionId 接龙ID
 * @param groupId 群ID（用于校验）
 * @param content 参与内容
 * @param successBlock 成功回调
 * @param errorBlock 失败回调
 */
- (void)joinOrUpdateCollection:(long)collectionId
                       groupId:(NSString *)groupId
                       content:(NSString *)content
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 删除自己的参与
 * POST /api/collections/{collectionId}/delete
 * @param collectionId 接龙ID
 * @param groupId 群ID（用于校验）
 * @param successBlock 成功回调
 * @param errorBlock 失败回调
 */
- (void)deleteCollectionEntry:(long)collectionId
                      groupId:(NSString *)groupId
                      success:(void(^)(void))successBlock
                        error:(void(^)(int errorCode, NSString *message))errorBlock;

/**
 * 关闭接龙（仅创建者可操作）
 * POST /api/collections/{collectionId}/close
 * @param collectionId 接龙ID
 * @param groupId 群ID（用于校验）
 * @param successBlock 成功回调
 * @param errorBlock 失败回调
 */
- (void)closeCollection:(long)collectionId
                groupId:(NSString *)groupId
                success:(void(^)(void))successBlock
                  error:(void(^)(int errorCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
