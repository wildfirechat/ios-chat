//
//  WFMClientJsonClient.h
//  WFMomentClient
//
//  Created by Rain on 2023/9/18.
//  Copyright © 2023 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString *kReceiveComments;
extern NSString *kReceiveFeeds;
extern NSString *kClearUnreadComments;

@protocol WFMomentJsonReceiveMessageDelegate <NSObject>
- (void)onReceiveNewComment:(NSDictionary *)commentContent;
- (void)onReceiveMentionedFeed:(NSDictionary *)feedContent;
@end


@interface WFMClientJsonClient : NSObject
+ (instancetype)sharedService;
@property(nonatomic, weak)id<WFMomentJsonReceiveMessageDelegate> receiveMessageDelegate;

- (NSDictionary *)postFeeds:(int)type
                 text:(NSString *)text
               medias:(NSArray<NSDictionary *> *)medias
              toUsers:(NSArray<NSString *> *)toUsers
         excludeUsers:(NSArray<NSString *> *)excludeUsers
       mentionedUsers:(NSArray<NSString *> *)mentionedUsers
                extra:(NSString *)extra
              success:(void(^)(long long feedId, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock;

- (void)deleteFeed:(long long)feedId
               success:(void(^)(void))successBlock
                 error:(void(^)(int error_code))errorBlock;

- (void)getFeeds:(NSUInteger)fromIndex
            count:(NSInteger)count
        fromUser:(NSString *)user
         success:(void(^)(NSArray<NSDictionary *> *))successBlock
           error:(void(^)(int error_code))errorBlock;

- (void)getFeed:(long long)feedUid
        success:(void(^)(NSDictionary *))successBlock
          error:(void(^)(int error_code))errorBlock;


- (NSDictionary *)postComment:(int)type
                     feedId:(long long)feedId
               replyComment:(long long)commentId
                       text:(NSString *)text
                    replyTo:(NSString *)replyTo
                      extra:(NSString *)extra
                    success:(void(^)(long long commentId, long long timestamp))successBlock
                      error:(void(^)(int error_code))errorBlock;


- (void)deleteComments:(long long)commentId
                feedId:(long long)feedId
               success:(void(^)(void))successBlock
                 error:(void(^)(int error_code))errorBlock;

- (NSArray<NSDictionary *> *)getMessages:(long long)fromIndex isNew:(BOOL)isNew;

- (int)getUnreadCount;
- (void)clearUnreadStatus;

- (void)storeCache:(NSArray<NSDictionary *> *)feeds forUser:(NSString *)userId;

- (NSArray<NSDictionary *> *)restoreCache:(NSString *)userId;

- (void)getUserProfile:(NSString *)userId
               success:(void(^)(NSDictionary *profile))successBlock
                 error:(void(^)(int error_code))errorBlock;

- (void)updateUserProfile:(int)updateProfileType
                 strValue:(NSString *)strValue
                 intValue:(int)intValue
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock;

- (void)updateBlackOrBlockList:(BOOL)isBlock
                       addList:(NSArray<NSString *> *)addList
                    removeList:(NSArray<NSString *> *)removeList
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock;

- (void)updateLastReadTimestamp;
- (long long)getLastReadTimestamp;
@end


NS_ASSUME_NONNULL_END
