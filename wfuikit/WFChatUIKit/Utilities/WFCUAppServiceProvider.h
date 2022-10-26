//
//  WFCUAppService.h
//  WFChatUIKit
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCUGroupAnnouncement.h"
#import "WFCUFavoriteItem.h"

NS_ASSUME_NONNULL_BEGIN

@class WFCCPCOnlineInfo;
@class WFZConferenceInfo;
@protocol WFCUAppServiceProvider <NSObject>
- (void)getGroupAnnouncement:(NSString *)groupId
                     success:(void(^)(WFCUGroupAnnouncement *))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)updateGroup:(NSString *)groupId
       announcement:(NSString *)announcement
            success:(void(^)(long timestamp))successBlock
              error:(void(^)(int error_code))errorBlock;

- (void)getGroupMembersForPortrait:(NSString *)groupId
                           success:(void(^)(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers))successBlock
                             error:(void(^)(int error_code))errorBlock;

- (void)showPCSessionViewController:(UIViewController *)baseController
                          pcClient:(WFCCPCOnlineInfo *)clientInfo;

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;


- (void)getFavoriteItems:(int )startId
                   count:(int)count
                     success:(void(^)(NSArray<WFCUFavoriteItem *> *items, BOOL hasMore))successBlock
                       error:(void(^)(int error_code))errorBlock;

- (void)addFavoriteItem:(WFCUFavoriteItem *)item
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;

- (void)removeFavoriteItem:(int)favId
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;

- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)createConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)updateConference:(WFZConferenceInfo *)conferenceInfo success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)recordConference:(NSString *)conferenceId record:(BOOL)record success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)focusConference:(NSString *)conferenceId userId:(NSString *)focusUserId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(WFZConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)getFavConferences:(void(^)(NSArray<WFZConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

@end

NS_ASSUME_NONNULL_END
