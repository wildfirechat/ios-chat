//
//  WFMomentService.h
//  WFMomentClient
//
//  Created by Heavyrain Lee on 2019/6/7.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFMFeed.h"
#import "WFMComment.h"
#import "WFMomentDefine.h"
#import "WFMomentProfiles.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *kReceiveComments;
extern NSString *kReceiveFeeds;

@class WFCCMessageContent;
@protocol WFMomentReceiveMessageDelegate <NSObject>
- (void)onReceiveNewComment:(WFMCommentMessageContent *)commentContent;
- (void)onReceiveMentionedFeed:(WFMFeedMessageContent *)feedContent;
@end

typedef NS_ENUM(NSInteger, WFMUpdateUserProfileType) {
    WFMUpdateUserProfileType_BackgroudUrl,
    WFMUpdateUserProfileType_StrangerVisiableCount,
    WFMUpdateUserProfileType_VisiableScope
};

@interface WFMomentService : NSObject
+ (instancetype)sharedService;
@property(nonatomic, weak)id<WFMomentReceiveMessageDelegate> receiveMessageDelegate;

- (WFMFeed *)postFeeds:(WFMContentType)type
                 text:(NSString *)text
               medias:(NSArray<WFMFeedEntry *> *)medias
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
         success:(void(^)(NSArray<WFMFeed *> *))successBlock
           error:(void(^)(int error_code))errorBlock;

- (void)getFeed:(long long)feedUid
        success:(void(^)(WFMFeed *))successBlock
          error:(void(^)(int error_code))errorBlock;


- (WFMComment *)postComment:(WFMCommentType)type
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

- (NSArray<WFCCMessage *> *)getMessages:(BOOL)isNew;

- (int)getUnreadCount;
- (void)clearUnreadStatus;

- (void)storeCache:(NSMutableArray<WFMFeed *> *)feeds forUser:(NSString *)userId;

- (NSMutableArray<WFMFeed *> *)restoreCache:(NSString *)userId;

- (void)getUserProfile:(NSString *)userId
               success:(void(^)(WFMomentProfiles *profile))successBlock
                 error:(void(^)(int error_code))errorBlock;

- (void)updateUserProfile:(WFMUpdateUserProfileType)updateProfileType
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
//use protubuf. default is true
@property(nonatomic, assign)BOOL usePB;
@end

NS_ASSUME_NONNULL_END
