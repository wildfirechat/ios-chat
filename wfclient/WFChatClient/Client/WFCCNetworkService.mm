//
//  WFCCNetworkService.mm
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#include "WFCCNetworkService.h"
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

#import "app_callback.h"
#include <mars/baseevent/base_logic.h>
#include <mars/xlog/xlogger.h>
#include <mars/xlog/xloggerbase.h>
#include <mars/xlog/appender.h>
#include <mars/proto/proto.h>
#include <mars/stn/stn_logic.h>
#include <list>
#import "WFCCIMService.h"
#import "WFCCNetworkStatus.h"
#import "WFCCRecallMessageContent.h"

const NSString *SDKVERSION = @"0.1";
extern NSMutableArray* convertProtoMessageList(const std::list<mars::stn::TMessage> &messageList, BOOL reverse);
extern NSMutableArray* convertProtoDeliveryList(const std::map<std::string, int64_t> &userReceived);
extern NSMutableArray* convertProtoReadedList(const std::list<mars::stn::TReadEntry> &userReceived);

NSString *kGroupInfoUpdated = @"kGroupInfoUpdated";
NSString *kGroupMemberUpdated = @"kGroupMemberUpdated";
NSString *kUserInfoUpdated = @"kUserInfoUpdated";
NSString *kFriendListUpdated = @"kFriendListUpdated";
NSString *kFriendRequestUpdated = @"kFriendRequestUpdated";
NSString *kSettingUpdated = @"kSettingUpdated";
NSString *kChannelInfoUpdated = @"kChannelInfoUpdated";

@protocol RefreshGroupInfoDelegate <NSObject>
- (void)onGroupInfoUpdated:(NSArray<WFCCGroupInfo *> *)updatedGroupInfo;
@end

@protocol RefreshGroupMemberDelegate <NSObject>
- (void)onGroupMemberUpdated:(NSString *)groupId members:(NSArray<WFCCGroupMember *> *)updatedGroupMembers;
@end

@protocol RefreshChannelInfoDelegate <NSObject>
- (void)onChannelInfoUpdated:(NSArray<WFCCChannelInfo *> *)updatedChannelInfo;
@end

@protocol RefreshUserInfoDelegate <NSObject>
- (void)onUserInfoUpdated:(NSArray<WFCCUserInfo *> *)updatedUserInfo;
@end

@protocol RefreshFriendListDelegate <NSObject>
- (void)onFriendListUpdated;
@end

@protocol RefreshFriendRequestDelegate <NSObject>
- (void)onFriendRequestUpdated:(NSArray<NSString *> *)newFriendRequests;
@end

@protocol RefreshSettingDelegate <NSObject>
- (void)onSettingUpdated;
@end



class CSCB : public mars::stn::ConnectionStatusCallback {
public:
  CSCB(id<ConnectionStatusDelegate> delegate) : m_delegate(delegate) {
  }
  void onConnectionStatusChanged(mars::stn::ConnectionStatus connectionStatus) {
    if (m_delegate) {
      [m_delegate onConnectionStatusChanged:(ConnectionStatus)connectionStatus];
    }
  }
  id<ConnectionStatusDelegate> m_delegate;
};



class RPCB : public mars::stn::ReceiveMessageCallback {
public:
    RPCB(id<ReceiveMessageDelegate> delegate) : m_delegate(delegate) {}
    
    void onReceiveMessage(const std::list<mars::stn::TMessage> &messageList, bool hasMore) {
        if (m_delegate && !messageList.empty()) {
            NSMutableArray *messages = convertProtoMessageList(messageList, NO);
            [m_delegate onReceiveMessage:messages hasMore:hasMore];
        }
    }
    
    void onRecallMessage(const std::string &operatorId, long long messageUid) {
        if (m_delegate) {
            [m_delegate onRecallMessage:messageUid];
        }
    }
    
    void onDeleteMessage(long long messageUid) {
        if (m_delegate) {
            [m_delegate onDeleteMessage:messageUid];
        }
    }
    
    void onUserReceivedMessage(const std::map<std::string, int64_t> &userReceived) {
        if (m_delegate && !userReceived.empty()) {
            NSMutableArray *ds = convertProtoDeliveryList(userReceived);
            [m_delegate onMessageDelivered:ds];
        }
    }
    
    void onUserReadedMessage(const std::list<mars::stn::TReadEntry> &userReceived) {
        if (m_delegate && !userReceived.empty()) {
            NSMutableArray *ds = convertProtoReadedList(userReceived);
            [m_delegate onMessageReaded:ds];
        }
    }
    
    id<ReceiveMessageDelegate> m_delegate;
};

class CONFCB : public mars::stn::ConferenceEventCallback {
public:
  CONFCB(id<ConferenceEventDelegate> delegate) : m_delegate(delegate) {
  }
  void onConferenceEvent(const std::string &event) {
    if (m_delegate) {
        [m_delegate onConferenceEvent:[NSString stringWithUTF8String:event.c_str()]];
    }
  }
    
  id<ConferenceEventDelegate> m_delegate;
};


WFCCUserInfo* convertUserInfo(const mars::stn::TUserInfo &tui) {
    WFCCUserInfo *userInfo = [[WFCCUserInfo alloc] init];
    userInfo.userId = [NSString stringWithUTF8String:tui.uid.c_str()];
    userInfo.name = [NSString stringWithUTF8String:tui.name.c_str()];
    userInfo.portrait = [NSString stringWithUTF8String:tui.portrait.c_str()];
    
    userInfo.deleted = tui.deleted;
    if (tui.deleted) {
        userInfo.displayName = @"已删除用户";
    } else {
        userInfo.displayName = [NSString stringWithUTF8String:tui.displayName.c_str()];
        userInfo.gender = tui.gender;
        userInfo.social = [NSString stringWithUTF8String:tui.social.c_str()];
        userInfo.mobile = [NSString stringWithUTF8String:tui.mobile.c_str()];
        userInfo.email = [NSString stringWithUTF8String:tui.email.c_str()];
        userInfo.address = [NSString stringWithUTF8String:tui.address.c_str()];
        userInfo.company = [NSString stringWithUTF8String:tui.company.c_str()];
        userInfo.social = [NSString stringWithUTF8String:tui.social.c_str()];
    }
    userInfo.friendAlias = [NSString stringWithUTF8String:tui.friendAlias.c_str()];
    userInfo.groupAlias = [NSString stringWithUTF8String:tui.groupAlias.c_str()];
    userInfo.extra = [NSString stringWithUTF8String:tui.extra.c_str()];
    userInfo.updateDt = tui.updateDt;
    userInfo.type = tui.type;
    
    return userInfo;
}

NSArray<WFCCUserInfo *>* converUserInfos(const std::list<mars::stn::TUserInfo> &userInfoList) {
    NSMutableArray *out = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TUserInfo>::const_iterator it = userInfoList.begin(); it != userInfoList.end(); it++) {
        [out addObject:convertUserInfo(*it)];
    }
    return out;
}

extern WFCCChannelInfo *convertProtoChannelInfo(const mars::stn::TChannelInfo &tci);
extern WFCCGroupMember* convertProtoGroupMember(const mars::stn::TGroupMember &tm);
extern WFCCGroupInfo *convertProtoGroupInfo(const mars::stn::TGroupInfo &tgi);
NSArray<WFCCGroupInfo *>* convertGroupInfos(const std::list<mars::stn::TGroupInfo> &groupInfoList) {
    NSMutableArray *out = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TGroupInfo>::const_iterator it = groupInfoList.begin(); it != groupInfoList.end(); it++) {
        [out addObject:convertProtoGroupInfo(*it)];
    }
    return out;
}

NSArray<WFCCChannelInfo *>* convertChannelInfos(const std::list<mars::stn::TChannelInfo> &channelInfoList) {
    NSMutableArray *out = [[NSMutableArray alloc] init];
    for (std::list<mars::stn::TChannelInfo>::const_iterator it = channelInfoList.begin(); it != channelInfoList.end(); it++) {
        [out addObject:convertProtoChannelInfo(*it)];
    }
    return out;
}

NSMutableDictionary *convertTComment(const mars::stn::TMomentsComment &tcomment) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(tcomment.type) forKey:@"type"];
    
    if (tcomment.commentId) {
        [dict setObject:@(tcomment.commentId) forKey:@"commentId"];
    }
    
    if (tcomment.feedId) {
        [dict setObject:@(tcomment.feedId) forKey:@"feedId"];
    }
    if(tcomment.replyId) {
        [dict setObject:@(tcomment.replyId) forKey:@"replyId"];
    }
    if (!tcomment.sender.empty()) {
        [dict setObject:[NSString stringWithUTF8String:tcomment.sender.c_str()] forKey:@"sender"];
    }
    
    if (!tcomment.text.empty()) {
        [dict setObject:[NSString stringWithUTF8String:tcomment.text.c_str()] forKey:@"text"];
    }
    
    if (tcomment.serverTime) {
        [dict setObject:@(tcomment.serverTime) forKey:@"serverTime"];
    }
    
    
    if (!tcomment.replyTo.empty()) {
        [dict setObject:[NSString stringWithUTF8String:tcomment.replyTo.c_str()] forKey:@"replyTo"];
    }
    
    if (!tcomment.extra.empty()) {
        [dict setObject:[NSString stringWithUTF8String:tcomment.extra.c_str()] forKey:@"extra"];
    }
    return dict;
}

NSMutableDictionary *convertTFeed(const mars::stn::TMomentsFeed &tfeed) {
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];

    [dataDict setObject:@(tfeed.type) forKey:@"type"];
    
    if (tfeed.feedId) {
        [dataDict setObject:@(tfeed.feedId) forKey:@"feedId"];
    }
    if (!tfeed.sender.empty()) {
        [dataDict setObject:[NSString stringWithUTF8String:tfeed.sender.c_str()] forKey:@"sender"];
    }
    if (!tfeed.text.empty()) {
        [dataDict setObject:[NSString stringWithUTF8String:tfeed.text.c_str()] forKey:@"text"];
    }
    
    if (tfeed.serverTime) {
        [dataDict setObject:@(tfeed.serverTime) forKey:@"timestamp"];
    }
    
    if (!tfeed.medias.empty()) {
        NSMutableArray *entrys = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TMomentsMedia>::const_iterator it2 = tfeed.medias.begin(); it2 != tfeed.medias.end(); it2++) {
            NSMutableDictionary *entryDict = [NSMutableDictionary dictionary];
            [entryDict setObject:[NSString stringWithUTF8String:it2->mediaUrl.c_str()] forKey:@"m"];
            [entryDict setObject:@(it2->width) forKey:@"w"];
            [entryDict setObject:@(it2->height) forKey:@"h"];
            if(!it2->thumbUrl.empty()) {
                [entryDict setObject:[NSString stringWithUTF8String:it2->thumbUrl.c_str()] forKey:@"t"];
            }
            [entrys addObject:entryDict];
        }
        [dataDict setObject:entrys forKey:@"medias"];
    }
    
    if (!tfeed.toUsers.empty()) {
        NSMutableArray *entrys = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it2 = tfeed.toUsers.begin(); it2 != tfeed.toUsers.end(); ++it2) {
            [entrys addObject:[NSString stringWithUTF8String:it2->c_str()]];
        }
        [dataDict setObject:entrys forKey:@"to"];
    }
    
    if (!tfeed.excludeUsers.empty()) {
        NSMutableArray *entrys = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it2 = tfeed.excludeUsers.begin(); it2 != tfeed.excludeUsers.end(); ++it2) {
            [entrys addObject:[NSString stringWithUTF8String:it2->c_str()]];
        }
        [dataDict setObject:entrys forKey:@"ex"];
    }
    
    if (!tfeed.extra.empty()) {
        [dataDict setObject:[NSString stringWithUTF8String:tfeed.extra.c_str()] forKey:@"extra"];
    }
    
    if (!tfeed.comments.empty()) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TMomentsComment>::const_iterator it2 = tfeed.comments.begin(); it2 != tfeed.comments.end(); it2++) {
            NSMutableDictionary *dict = convertTComment(*it2);
            [arr addObject:dict];
        }
        [dataDict setObject:arr forKey:@"comments"];
    }
    if(tfeed.hasMore) {
        [dataDict setObject:@(YES) forKey:@"hasMore"];
    }
    
    return dataDict;
}

class GUCB : public mars::stn::GetUserInfoCallback {
  public:
  GUCB(id<RefreshUserInfoDelegate> delegate) : m_delegate(delegate) {}
  
  void onSuccess(const std::list<mars::stn::TUserInfo> &userInfoList) {
      if(m_delegate && !userInfoList.empty()) {
          [m_delegate onUserInfoUpdated:converUserInfos(userInfoList)];
      }
  }
  void onFalure(int errorCode) {
    
  }
  id<RefreshUserInfoDelegate> m_delegate;
};

class GGCB : public mars::stn::GetGroupInfoCallback {
  public:
  GGCB(id<RefreshGroupInfoDelegate> delegate) : m_delegate(delegate) {}
  
  void onSuccess(const std::list<mars::stn::TGroupInfo> &groupInfoList) {
      if(m_delegate && !groupInfoList.empty()) {
          [m_delegate onGroupInfoUpdated:convertGroupInfos(groupInfoList)];
      }
  }
  void onFalure(int errorCode) {
  }
  id<RefreshGroupInfoDelegate> m_delegate;
};

class GGMCB : public mars::stn::GetGroupMembersCallback {
public:
    GGMCB(id<RefreshGroupMemberDelegate> delegate) : m_delegate(delegate) {}
    
    void onSuccess(const std::string &groupId, const std::list<mars::stn::TGroupMember> &groupMemberList) {
        if(m_delegate && !groupMemberList.empty()) {
            NSMutableArray *output = [[NSMutableArray alloc] init];
            for(std::list<mars::stn::TGroupMember>::const_iterator it = groupMemberList.begin(); it != groupMemberList.end(); it++) {
                WFCCGroupMember *member = convertProtoGroupMember(*it);
                [output addObject:member];
            }
            
            [m_delegate onGroupMemberUpdated:[NSString stringWithUTF8String:groupId.c_str()] members:output];
        }
    }
    void onFalure(int errorCode) {
    }
    id<RefreshGroupMemberDelegate> m_delegate;
};

class GCHCB : public mars::stn::GetChannelInfoCallback {
public:
    GCHCB(id<RefreshChannelInfoDelegate> delegate) : m_delegate(delegate) {}
    
    void onSuccess(const std::list<mars::stn::TChannelInfo> &channelInfoList) {
        if(m_delegate && !channelInfoList.empty()) {
            [m_delegate onChannelInfoUpdated:convertChannelInfos(channelInfoList)];
        }
    }
    void onFalure(int errorCode) {
    }
    id<RefreshChannelInfoDelegate> m_delegate;
};

class GFLCB : public mars::stn::GetMyFriendsCallback {
public:
    GFLCB(id<RefreshFriendListDelegate> delegate) : m_delegate(delegate) {}
    void onSuccess(const std::list<std::string> &friendIdList) {
        if(m_delegate) {
            [m_delegate onFriendListUpdated];
        }
    }
    void onFalure(int errorCode) {
        
    }
    id<RefreshFriendListDelegate> m_delegate;
};

class GFRCB : public mars::stn::GetFriendRequestCallback {
public:
    GFRCB(id<RefreshFriendRequestDelegate> delegate) : m_delegate(delegate) {}
    void onSuccess(const std::list<std::string> &newRequests) {
        if(m_delegate) {
            NSMutableArray *requests = [[NSMutableArray alloc] init];
            for (std::list<std::string>::const_iterator it = newRequests.begin(); it != newRequests.end(); ++it) {
                NSString *r = [NSString stringWithUTF8String:it->c_str()];
                [requests addObject:r];
            }
            [m_delegate onFriendRequestUpdated:requests];
        }
    }
    void onFalure(int errorCode) {
        
    }
    id<RefreshFriendRequestDelegate> m_delegate;
};

class GSCB : public mars::stn::GetSettingCallback {
public:
  GSCB(id<RefreshSettingDelegate> delegate) : m_delegate(delegate) {}
  void onSuccess(bool hasNewRequest) {
    if(m_delegate && hasNewRequest) {
      [m_delegate onSettingUpdated];
    }
  }
  void onFalure(int errorCode) {
    
  }
  id<RefreshSettingDelegate> m_delegate;
};



@interface WFCCNetworkService () <ConnectionStatusDelegate, ReceiveMessageDelegate, RefreshUserInfoDelegate, RefreshGroupInfoDelegate, WFCCNetworkStatusDelegate, RefreshFriendListDelegate, RefreshFriendRequestDelegate, RefreshSettingDelegate, RefreshChannelInfoDelegate, RefreshGroupMemberDelegate, ConferenceEventDelegate>
@property(nonatomic, assign)ConnectionStatus currentConnectionStatus;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *passwd;

@property(nonatomic, strong)NSString *serverHost;

@property(nonatomic, assign)UIBackgroundTaskIdentifier bgTaskId;
@property(nonatomic, strong)NSTimer *forceConnectTimer;
@property(nonatomic, strong)NSTimer *suspendTimer;
@property(nonatomic, strong)NSTimer *endBgTaskTimer;
@property(nonatomic, strong)NSString *deviceToken;
@property(nonatomic, strong)NSString *voipDeviceToken;

@property(nonatomic, assign)BOOL requestProxying;
@property(nonatomic, strong) NSMutableArray *messageFilterList;

@property(nonatomic, assign)BOOL deviceTokenUploaded;
@property(nonatomic, assign)BOOL voipDeviceTokenUploaded;
- (void)reportEvent_OnForeground:(BOOL)isForeground;

@property(nonatomic, assign)NSUInteger backgroudRunTime;
@end

@implementation WFCCNetworkService

static WFCCNetworkService * sharedSingleton = nil;
+ (void)startLog {
    NSString* logPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/log"];
    
    // set do not backup for logpath
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    setxattr([logPath UTF8String], attrName, &attrValue, sizeof(attrValue), 0, 0);
    
    // init xlog
#if DEBUG
    xlogger_SetLevel(kLevelVerbose);
    appender_set_console_log(true);
#else
    xlogger_SetLevel(kLevelInfo);
    appender_set_console_log(false);
#endif
    appender_open(kAppednerAsync, [logPath UTF8String], "Test", NULL);
}

+ (void)stopLog {
    appender_close();
}

+ (NSArray<NSString *> *)getLogFilesPath {
    NSString* logPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/log"];
    
    NSFileManager *myFileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [myFileManager enumeratorAtPath:logPath];

    BOOL isDir = NO;
    BOOL isExist = NO;

    NSMutableArray *output = [[NSMutableArray alloc] init];
    for (NSString *path in myDirectoryEnumerator.allObjects) {
        isExist = [myFileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@", logPath, path] isDirectory:&isDir];
        if (!isDir) {
            if ([path containsString:@"Test_"]) {
                [output addObject:[NSString stringWithFormat:@"%@/%@", logPath, path]];
            }
        }
    }

    return output;
}

- (void)onRecallMessage:(long long)messageUid {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecallMessages object:@(messageUid)];
        if ([self.receiveMessageDelegate respondsToSelector:@selector(onRecallMessage:)]) {
            [self.receiveMessageDelegate onRecallMessage:messageUid];
        }
    });
}
- (void)onDeleteMessage:(long long)messageUid {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeleteMessages object:@(messageUid)];
        if ([self.receiveMessageDelegate respondsToSelector:@selector(onDeleteMessage:)]) {
            [self.receiveMessageDelegate onDeleteMessage:messageUid];
        }
    });
}
- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *messageList = [messages mutableCopy];
        for (WFCCMessage *message in messages) {
            for (id<ReceiveMessageFilter> filter in self.messageFilterList) {
                @try {
                    if ([filter onReceiveMessage:message]) {
                        [messageList removeObject:message];
                        break;
                    }
                } @catch (NSException *exception) {
                    NSLog(@"%@", exception);
                    break;
                }
                
            }
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:messageList];
        [self.receiveMessageDelegate onReceiveMessage:messageList hasMore:hasMore];
    });
}

- (void)onMessageReaded:(NSArray<WFCCReadReport *> *)readeds {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageReaded object:readeds];
        
        if ([self.receiveMessageDelegate respondsToSelector:@selector(onMessageReaded:)]) {
            [self.receiveMessageDelegate onMessageReaded:readeds];
        }
    });
}

- (void)onMessageDelivered:(NSArray<WFCCDeliveryReport *> *)delivereds {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kMessageDelivered object:delivereds];
        
        if ([self.receiveMessageDelegate respondsToSelector:@selector(onMessageDelivered:)]) {
            [self.receiveMessageDelegate onMessageDelivered:delivereds];
        }
    });
}

- (void)onConferenceEvent:(NSString *)event {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.conferenceEventDelegate onConferenceEvent:event];
    });
}

- (void)addReceiveMessageFilter:(id<ReceiveMessageFilter>)filter {
    [self.messageFilterList addObject:filter];
}

- (void)removeReceiveMessageFilter:(id<ReceiveMessageFilter>)filter {
    [self.messageFilterList removeObject:filter];
}

- (void)onDisconnected {
  mars::baseevent::OnDestroy();
}

- (void)setCurrentConnectionStatus:(ConnectionStatus)currentConnectionStatus {
    NSLog(@"Connection status changed to (%ld)", (long)currentConnectionStatus);
    if (_currentConnectionStatus != currentConnectionStatus) {
        _currentConnectionStatus = currentConnectionStatus;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kConnectionStatusChanged object:@(_currentConnectionStatus)];
        
        if (_connectionStatusDelegate) {
            [_connectionStatusDelegate onConnectionStatusChanged:currentConnectionStatus];
        }
    }
}
- (void)onConnectionStatusChanged:(ConnectionStatus)status {
  if (!_logined || kConnectionStatusRejected == status) {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
      [self disconnect:YES clearSession:YES];
    });
    return;
  }
    if((int)status == (int)mars::stn::kConnectionStatusServerDown) {
        status = kConnectionStatusUnconnected;
    }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.currentConnectionStatus = status;
    if (status == kConnectionStatusConnected) {
        if (self.deviceToken.length && !self.deviceTokenUploaded) {
            [self setDeviceToken:self.deviceToken];
        }
        
        if (self.voipDeviceToken.length && !self.voipDeviceTokenUploaded) {
            [self setVoipDeviceToken:self.voipDeviceToken];
        }
    }
  });
    
}

+ (WFCCNetworkService *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCCNetworkService alloc] init];
            }
        }
    }
    
    return sharedSingleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentConnectionStatus = kConnectionStatusLogout;
        _messageFilterList = [[NSMutableArray alloc] init];
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onAppSuspend)
                                                   name:UIApplicationDidEnterBackgroundNotification
                                                 object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onAppResume)
                                                   name:UIApplicationDidBecomeActiveNotification
                                                 object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onAppTerminate)
                                                   name:UIApplicationWillTerminateNotification
                                                 object:nil];
    }
    return self;
}

- (void)startBackgroundTask {
    if (!_logined) {
        return;
    }
    
    if (_bgTaskId !=  UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTaskId];
    }
    __weak typeof(self) ws = self;
    _bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (ws.suspendTimer) {
            [ws.suspendTimer invalidate];
            ws.suspendTimer = nil;
        }
        
        if(ws.endBgTaskTimer) {
            [ws.endBgTaskTimer invalidate];
            ws.endBgTaskTimer = nil;
        }
        if(ws.forceConnectTimer) {
            [ws.forceConnectTimer invalidate];
            ws.forceConnectTimer = nil;
        }
        
        ws.bgTaskId = UIBackgroundTaskInvalid;
    }];
}

- (void)onAppSuspend {
    if (!_logined) {
        return;
    }
    
    [self reportEvent_OnForeground:NO];
    
    
    self.backgroudRunTime = 0;
    [self startBackgroundTask];
    
    [self checkBackGroundTask];
}

- (void)checkBackGroundTask {
    if(_suspendTimer) {
        [_suspendTimer invalidate];
    }
    if(_endBgTaskTimer) {
        [_endBgTaskTimer invalidate];
        _endBgTaskTimer = nil;
    }
    
    NSTimeInterval timeInterval = 3;
    
    _suspendTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                     target:self
                                                   selector:@selector(suspend)
                                                   userInfo:nil
                                                    repeats:NO];

}
- (void)suspend {
  if(_bgTaskId != UIBackgroundTaskInvalid) {
      self.backgroudRunTime += 3;
      BOOL inCall = NO;
      Class cls = NSClassFromString(@"WFAVEngineKit");
      
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
      if (cls && [cls respondsToSelector:@selector(isCallActive)] && [cls performSelector:@selector(isCallActive)]) {
          inCall = YES;
      }
#pragma clang diagnostic pop
      
      if ((mars::stn::GetTaskCount() > 0 && self.backgroudRunTime < 60) || (inCall && self.backgroudRunTime < 1800)) {
          [self checkBackGroundTask];
      } else {
          mars::stn::ClearTasks();
          _endBgTaskTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(endBgTask)
                                                     userInfo:nil
                                                      repeats:NO];
      }
  }
}
- (void)endBgTask {
  if(_bgTaskId !=  UIBackgroundTaskInvalid) {
    [[UIApplication sharedApplication] endBackgroundTask:_bgTaskId];
    _bgTaskId =  UIBackgroundTaskInvalid;
  }
  
  if (_suspendTimer) {
    [_suspendTimer invalidate];
    _suspendTimer = nil;
  }
  
  if(_endBgTaskTimer) {
    [_endBgTaskTimer invalidate];
    _endBgTaskTimer = nil;
  }
    
    if (_forceConnectTimer) {
        [_forceConnectTimer invalidate];
        _forceConnectTimer = nil;
    }
    
    self.backgroudRunTime = 0;
}

- (void)onAppResume {
  if (!_logined) {
    return;
  }
  [self reportEvent_OnForeground:YES];
  mars::baseevent::OnNetworkChange();
  mars::stn::MakesureLonglinkConnected();
  [self endBgTask];
}

- (void)onAppTerminate {
    mars::stn::AppWillTerminate();
}

- (void)dealloc {
    
}

- (void) createMars {
  mars::app::SetCallback(mars::app::AppCallBack::Instance());
  mars::stn::setConnectionStatusCallback(new CSCB(self));
  mars::stn::setReceiveMessageCallback(new RPCB(self));
    mars::stn::setConferenceEventCallback(new CONFCB(self));
  mars::stn::setRefreshUserInfoCallback(new GUCB(self));
  mars::stn::setRefreshGroupInfoCallback(new GGCB(self));
    mars::stn::setRefreshGroupMemberCallback(new GGMCB(self));
  mars::stn::setRefreshChannelInfoCallback(new GCHCB(self));
  mars::stn::setRefreshFriendListCallback(new GFLCB(self));
    mars::stn::setRefreshFriendRequestCallback(new GFRCB(self));
  mars::stn::setRefreshSettingCallback(new GSCB(self));
  mars::baseevent::OnCreate();
}
- (BOOL)connect:(NSString *)host {
    bool newDB = mars::stn::Connect([host UTF8String]);
    
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
          [self onAppSuspend];
        }
      });
    }
  });
    
    [self reportEvent_OnForeground:YES];
    mars::stn::MakesureLonglinkConnected();
    
    if (newDB) {
        return YES;
    }
    return NO;
}

- (void)forceConnectTimeOut {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self onAppSuspend];
    }
}

- (void)forceConnect:(NSUInteger)second {
    __weak typeof(self)ws = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (ws.logined &&[UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self onAppResume];
        [self startBackgroundTask];
        ws.forceConnectTimer = [NSTimer scheduledTimerWithTimeInterval:second
                                                         target:self
                                                       selector:@selector(forceConnectTimeOut)
                                                       userInfo:nil
                                                        repeats:NO];
    }
  });
}

- (void)cancelForceConnect {
    __weak typeof(self)ws = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ws.forceConnectTimer) {
            [ws.forceConnectTimer invalidate];
            ws.forceConnectTimer = nil;
        }
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self onAppSuspend];
    }
    });
}

- (long long)serverDeltaTime {
    return mars::stn::getServerDeltaTime();
}

- (void)useSM4 {
    mars::stn::useEncryptSM4();
}

#define WFC_CLIENT_ID @"wfc_client_id"
- (NSString *)getClientId {
    //当应用在appstore上架后，开发者账户下的所有应用在同一个手机上具有相同的vendor id。详情请参考(IDFV(identifierForVendor)使用陷阱)https://easeapi.com/blog/blog/63-ios-idfv.html
    //这样如果同一个IM服务有多个应用，多个应用安装到同一个手机上，这样所有应用将具有相同的clientId，导致互踢现象产生。
    //处理办法就是不使用identifierForVendor，随机生成UUID，然后固定使用这个UUID就行了，请参考下面注释掉的代码
    /*
    NSString *clientId = [[NSUserDefaults standardUserDefaults] objectForKey:WFC_CLIENT_ID];
    if(!clientId.length) {
        CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
        clientId = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
        CFRelease(uuidObject);
        [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:WFC_CLIENT_ID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return clientId;
     */
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

- (BOOL)connect:(NSString *)userId token:(NSString *)token {
    if (_logined) {
        for (int i = 0; i < 10; i++) {
            xerror2(TSF"Error: 使用错误，已经connect过了，不能再次connect。如果切换用户请先disconnect，再connect。请修正改错误");
        }
#if DEBUG
        exit(-1);
#endif
        return NO;
    }
    
  _logined = YES;
    self.deviceTokenUploaded = NO;
    self.voipDeviceTokenUploaded = NO;
    mars::app::AppCallBack::Instance()->SetAccountUserName([userId UTF8String]);
    [self createMars];
    self.userId = userId;
    self.passwd = token;
    if(!mars::stn::setAuthInfo([userId cStringUsingEncoding:NSUTF8StringEncoding], [token cStringUsingEncoding:NSUTF8StringEncoding])) {
        return NO;
    }
    
    self.currentConnectionStatus = kConnectionStatusConnecting;
    [[WFCCNetworkStatus sharedInstance] Start:[WFCCNetworkService sharedInstance]];
    
    return [self connect:self.serverHost];
}

- (void)disconnect:(BOOL)disablePush clearSession:(BOOL)clearSession {
    if(!_logined) {
        return;
    }
    
    _logined = NO;
    self.userId = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentConnectionStatus = kConnectionStatusLogout;
    });
    [[WFCCNetworkStatus sharedInstance] Stop];
    int flag = 0;
    if (clearSession) {
        flag = 8;
    } else if(disablePush) {
        flag = 1;
    }
    
  if (mars::stn::getConnectionStatus() != mars::stn::kConnectionStatusConnected && mars::stn::getConnectionStatus() != mars::stn::kConnectionStatusReceiving) {
    mars::stn::Disconnect(flag);
    [self destroyMars];
  } else {
    mars::stn::Disconnect(flag);
  }
}

- (void)setServerAddress:(NSString *)host {
    self.serverHost = host;
}

- (NSString *)getHost {
    return [NSString stringWithUTF8String:mars::stn::GetHost().c_str()];
}

- (NSString *)getHostEx {
    return [NSString stringWithUTF8String:mars::stn::GetHostEx().c_str()];
}

- (void)destroyMars {
  [[WFCCNetworkStatus sharedInstance] Stop];
    mars::baseevent::OnDestroy();
}


// event reporting
- (void)reportEvent_OnForeground:(BOOL)isForeground {
    mars::baseevent::OnForeground(isForeground);
}

- (void)setDeviceToken:(NSString *)token {
    if (token.length == 0) {
        return;
    }

    _deviceToken = token;

    if (!self.isLogined || self.currentConnectionStatus != kConnectionStatusConnected) {
        self.deviceTokenUploaded = NO;
        return;
    }
  
    NSString *appName =
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    mars::stn::setDeviceToken([appName UTF8String], [token UTF8String], mars::app::AppCallBack::Instance()->GetPushType());
    self.deviceTokenUploaded =YES;
}
- (void)setBackupAddressStrategy:(int)strategy {
    mars::stn::setBackupAddressStrategy(strategy);
}
- (void)setBackupAddress:(NSString *)host port:(int)port {
    mars::stn::setBackupAddress([host UTF8String], port);
}

- (void)setVoipDeviceToken:(NSString *)token {
    if (token.length == 0) {
        return;
    }
    
    _voipDeviceToken = token;
    
    if (!self.isLogined || self.currentConnectionStatus != kConnectionStatusConnected) {
        self.voipDeviceTokenUploaded = NO;
        return;
    }
    
    NSString *appName =
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    mars::stn::setDeviceToken([appName UTF8String], [token UTF8String], 2);
    self.voipDeviceTokenUploaded = YES;
}

- (NSString *)encodedCid {
    return [NSString stringWithUTF8String:mars::stn::GetEncodedCid().c_str()];
}
- (void)onGroupInfoUpdated:(NSArray<WFCCGroupInfo *> *)updatedGroupInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    for (WFCCGroupInfo *groupInfo in updatedGroupInfo) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated object:groupInfo.target userInfo:@{@"groupInfo":groupInfo}];
    }
  });
}

- (void)onGroupMemberUpdated:(NSString *)groupId members:(NSArray<WFCCGroupMember *> *)updatedGroupMembers {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:groupId userInfo:@{@"members":updatedGroupMembers}];
    });
}

- (void)onChannelInfoUpdated:(NSArray<WFCCChannelInfo *> *)updatedChannelInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (WFCCChannelInfo *channelInfo in updatedChannelInfo) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kChannelInfoUpdated object:channelInfo.channelId userInfo:@{@"channelInfo":channelInfo}];
        }
    });
}

- (void)onUserInfoUpdated:(NSArray<WFCCUserInfo *> *)updatedUserInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
    for (WFCCUserInfo *userInfo in updatedUserInfo) {
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoUpdated object:userInfo.userId userInfo:@{@"userInfo":userInfo}];
    }
  });
}

- (void)onFriendListUpdated {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:nil];
    });
}

- (void)onFriendRequestUpdated:(NSArray<NSString *> *)newFriendRequests {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFriendRequestUpdated object:newFriendRequests];
    });
}

- (NSData *)encodeData:(NSData *)data {
    std::string encodeData = mars::stn::GetEncodeDataEx(std::string((char *)data.bytes, data.length));
    return [[NSData alloc] initWithBytes:encodeData.c_str() length:encodeData.length()];
}

- (void)onSettingUpdated {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingUpdated object:nil];
  });
}

- (NSData *)decodeData:(NSData *)data {
    std::string encodeData = mars::stn::GetDecodeData(std::string((char *)data.bytes, data.length));
    return [[NSData alloc] initWithBytes:encodeData.c_str() length:encodeData.length()];
}


- (NSData *)decodeData:(NSData *)data gzip:(BOOL)gzip type:(int)type {
    std::string strData((char *)data.bytes, data.length);
    if(type == 0) {
        std::list<mars::stn::TMomentsFeed> feeds;
        if(mars::stn::GetFeeds(strData, feeds, gzip?true:false)) {
            NSMutableArray<NSMutableDictionary *> *arr = [[NSMutableArray alloc] init];
            for (std::list<mars::stn::TMomentsFeed>::iterator it = feeds.begin(); it != feeds.end(); ++it) {
                NSMutableDictionary *dataDict = convertTFeed(*it);
                [arr addObject:dataDict];
            }
            return [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:nil];
        }
    } else if(type == 1) {
        mars::stn::TMomentsFeed feed;
        if(mars::stn::GetFeed(strData, feed, gzip?true:false)) {
            NSMutableDictionary *dataDict = convertTFeed(feed);
            return [NSJSONSerialization dataWithJSONObject:dataDict options:kNilOptions error:nil];
        }
    } else if(type == 2) {
        std::list<mars::stn::TMomentsComment> comments;
        if(mars::stn::GetComments(strData, comments, gzip?true:false)) {
            NSMutableArray<NSMutableDictionary *> *arr = [[NSMutableArray alloc] init];
            for (std::list<mars::stn::TMomentsComment>::iterator it = comments.begin(); it != comments.end(); ++it) {
                NSMutableDictionary *dataDict = convertTComment(*it);
                [arr addObject:dataDict];
            }
            return [NSJSONSerialization dataWithJSONObject:arr options:kNilOptions error:nil];
        }
    }
    
    return nil;
}

#pragma mark WFCCNetworkStatusDelegate
-(void) ReachabilityChange:(UInt32)uiFlags {
    if ((uiFlags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            mars::baseevent::OnNetworkChange();
    } else if(!uiFlags) {
        if(self.currentConnectionStatus == kConnectionStatusConnected)
            mars::baseevent::OnNetworkChange();
    }
}


@end

