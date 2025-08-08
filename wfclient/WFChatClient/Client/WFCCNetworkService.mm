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
#import "WFAVEngineKit_Import.h"

#import "app_callback.h"
#include <baseevent/base_logic.h>
#include <xlog/xlogger.h>
#include <xlog/xloggerbase.h>
#include <xlog/appender.h>
#include <proto/proto.h>
#include <stn/stn_logic.h>
#include <list>
#import "WFCCIMService.h"
#import "WFCCNetworkStatus.h"
#import "WFCCRecallMessageContent.h"
#import "WFCCUserOnlineState.h"

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
NSString *kUserOnlineStateUpdated = @"kUserOnlineStateUpdated";
NSString *kSecretChatStateUpdated = @"kSecretChatStateUpdated";
NSString *kSecretMessageStartBurning = @"kSecretMessageStartBurning";
NSString *kSecretMessageBurned = @"kSecretMessageBurned";
NSString *kDomainInfoUpdated = @"kDomainInfoUpdated";


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
- (void)onFriendListUpdated:(NSArray<NSString *> *)friendIds;
@end

@protocol RefreshFriendRequestDelegate <NSObject>
- (void)onFriendRequestUpdated:(NSArray<NSString *> *)newFriendRequests;
@end

@protocol RefreshSettingDelegate <NSObject>
- (void)onSettingUpdated;
@end

@protocol SecretChatStateDelegate <NSObject>
- (void)onSecretChatStateChanged:(NSString *)targetId newState:(WFCCSecretChatState)state;
@end

@protocol SecretMessageBurnStateDelegate <NSObject>
- (void)onSecretMessageStartBurning:(NSString *)targetId playedMessageId:(long)messageId;
- (void)onSecretMessageBurned:(NSArray<NSNumber *> *)messageIds;
@end

@protocol RefreshDomainInfoDelegate <NSObject>
- (void)onDomainInfoUpdated:(WFCCDomainInfo *)updatedDomainInfo;
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

class CTSCB : public mars::stn::NotifyConnectToServerCallback {
public:
    CTSCB(id<ConnectToServerDelegate> delegate) : m_delegate(delegate) {
  }
    void OnConnectToServer(const std::string &host, const std::string &ip, int port) {
    if (m_delegate) {
        [m_delegate onConnectToServer:[NSString stringWithUTF8String:host.c_str()] ip:[NSString stringWithUTF8String:ip.c_str()] port:port];
    }
  }
    
    void OnConnected(const std::string &host, const std::string &ip, int port, bool mainNW) {
        if (m_delegate) {
            [m_delegate onConnected:[NSString stringWithUTF8String:host.c_str()] ip:[NSString stringWithUTF8String:ip.c_str()] port:port mainNw:mainNW];
        }
    }
  id<ConnectToServerDelegate> m_delegate;
};

class TDCB : public mars::stn::TrafficDataCallback {
public:
    TDCB(id<TrafficDataDelegate> delegate) : m_delegate(delegate) {
  }
    void OnTrafficData(int64_t send, int64_t recv) {
    if (m_delegate) {
        [m_delegate onTrafficData:send recv:recv];
    }
  }
  id<TrafficDataDelegate> m_delegate;
};

class TECB : public mars::stn::ErrorEventCallback {
public:
    void OnErrorEvent(int errorType, const std::string &errMsg) {
        NSLog(@"on protocol error %d, %@", errorType, [[NSString alloc] initWithUTF8String:errMsg.c_str()]);
    }
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

class OECB : public mars::stn::OnlineEventCallback {
public:
    OECB(id<OnlineEventDelegate> delegate) : m_delegate(delegate) {
  }
  void onOnlineEvent(const std::list<mars::stn::TUserOnlineState> &events) {
    if (m_delegate) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (std::list<mars::stn::TUserOnlineState>::const_iterator i = events.begin(); i != events.end(); ++i) {
            const mars::stn::TUserOnlineState &event = *i;
            WFCCUserOnlineState *state = [[WFCCUserOnlineState alloc] init];
            state.userId = [NSString stringWithUTF8String:event.userId.c_str()];
            state.customState = [[WFCCUserCustomState alloc] init];
            state.customState.state = event.customState;
            if(!event.customText.empty()) {
                state.customState.text = [NSString stringWithUTF8String:event.customText.c_str()];
            }
            NSMutableArray *array = [[NSMutableArray alloc] init];
            for (std::list<mars::stn::TOnlineState>::const_iterator it = event.states.begin(); it != event.states.end(); ++it) {
                WFCCClientState *onlineState = [[WFCCClientState alloc] init];
                onlineState.platform = it->platform;
                onlineState.state = it->state;
                onlineState.lastSeen = it->lastSeen;
                [array addObject:onlineState];
            }
            state.clientStates = array;
            [arr addObject:state];
        }
        
        [m_delegate onOnlineEvent:arr];
    }
  }
    
  id<OnlineEventDelegate> m_delegate;
};


WFCCUserInfo* convertUserInfo(const mars::stn::TUserInfo &tui) {
    WFCCUserInfo *userInfo = [[WFCCUserInfo alloc] init];
    userInfo.userId = [NSString stringWithUTF8String:tui.uid.c_str()];
    userInfo.name = [NSString stringWithUTF8String:tui.name.c_str()];
    userInfo.portrait = [NSString stringWithUTF8String:tui.portrait.c_str()];
    if (userInfo.portrait.length && [WFCCNetworkService sharedInstance].urlRedirector) {
        userInfo.portrait = [[WFCCNetworkService sharedInstance].urlRedirector redirect:userInfo.portrait];
    }
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
    if(!userInfo.portrait.length && [WFCCNetworkService sharedInstance].defaultPortraitProvider && [[WFCCNetworkService sharedInstance].defaultPortraitProvider respondsToSelector:@selector(userDefaultPortrait:)]) {
        userInfo.portrait = [[WFCCNetworkService sharedInstance].defaultPortraitProvider userDefaultPortrait:userInfo];
    }
    
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
    if (!tfeed.mentionedUsers.empty()) {
        NSMutableArray *entrys = [[NSMutableArray alloc] init];
        for (std::list<std::string>::const_iterator it2 = tfeed.mentionedUsers.begin(); it2 != tfeed.mentionedUsers.end(); ++it2) {
            [entrys addObject:[NSString stringWithUTF8String:it2->c_str()]];
        }
        [dataDict setObject:entrys forKey:@"mu"];
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
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            for (std::list<std::string>::const_iterator it = friendIdList.begin(); it != friendIdList.end(); ++it) {
                [arr addObject:[NSString stringWithUTF8String:it->c_str()]];
            }
            [m_delegate onFriendListUpdated:arr];
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

class SCSCB : public mars::stn::SecretChatStateCallback {
public:
    SCSCB(id<SecretChatStateDelegate> delegate) : m_delegate(delegate) {}
    void onStateChanged(const std::string &targetId, int state) {
        [m_delegate onSecretChatStateChanged:[NSString stringWithUTF8String:targetId.c_str()] newState:(WFCCSecretChatState)state];
    }
    id<SecretChatStateDelegate> m_delegate;
};

class SMBSCB : public mars::stn::SecretMessageBurnStateCallback {
public:
    SMBSCB(id<SecretMessageBurnStateDelegate> delegate) : m_delegate(delegate) {}
    void onSecretMessageStartBurning(const std::string &targetId, long playedMessageId) {
        [m_delegate onSecretMessageStartBurning:[NSString stringWithUTF8String:targetId.c_str()] playedMessageId:playedMessageId];
    }
    void onSecretMessageBurned(const std::list<long> &messageIds) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        for (std::list<long>::const_iterator it = messageIds.begin(); it != messageIds.end(); ++it) {
            [arr addObject:@(*it)];
        }
        [m_delegate onSecretMessageBurned:arr];
    }
    id<SecretMessageBurnStateDelegate> m_delegate;
};

class GDCB : public mars::stn::GetDomainInfoCallback {
  public:
    GDCB(id<RefreshDomainInfoDelegate> delegate) : m_delegate(delegate) {}
  
  void onSuccess(const mars::stn::TDomainInfo &domain) {
      if(m_delegate) {
          WFCCDomainInfo *domainInfo = [[WFCCDomainInfo alloc] init];
          domainInfo.domainId = [NSString stringWithUTF8String:domain.domainId.c_str()];
          domainInfo.name = [NSString stringWithUTF8String:domain.name.c_str()];
          domainInfo.desc = [NSString stringWithUTF8String:domain.desc.c_str()];
          domainInfo.email = [NSString stringWithUTF8String:domain.email.c_str()];
          domainInfo.tel = [NSString stringWithUTF8String:domain.tel.c_str()];
          domainInfo.address = [NSString stringWithUTF8String:domain.address.c_str()];
          domainInfo.extra = [NSString stringWithUTF8String:domain.extra.c_str()];
          domainInfo.updateDt = domain.updateDt;
          [m_delegate onDomainInfoUpdated:domainInfo];
      }
  }
  void onFalure(int errorCode) {
    
  }
  id<RefreshDomainInfoDelegate> m_delegate;
};

class CSACB : public mars::stn::CustomSortAddressCallback {
  public:
    bool sortAddress(bool longLink, std::vector<std::pair<std::string, int>> &ipPorts) {
        bool changed = false;
// 当有多个可连网络时，这里可以进行排序。只能排序和删除，不能添加。
//        for(int i = 1; i < ipPorts.size(); i++) {
//            if(ipPorts[i].second == 1886) {
//                std::pair<std::string, int> temp = ipPorts[0];
//                ipPorts[0] = ipPorts[i];
//                ipPorts[i] = temp;
//                changed = true;
//                break;
//            }
//        }
        return changed;
    }
};

@interface WFCCNetworkService () <ConnectionStatusDelegate, ReceiveMessageDelegate, RefreshUserInfoDelegate, RefreshGroupInfoDelegate, WFCCNetworkStatusDelegate, RefreshFriendListDelegate, RefreshFriendRequestDelegate, RefreshSettingDelegate, RefreshChannelInfoDelegate, RefreshGroupMemberDelegate, ConferenceEventDelegate, ConnectToServerDelegate, TrafficDataDelegate, OnlineEventDelegate, SecretChatStateDelegate, SecretMessageBurnStateDelegate, RefreshDomainInfoDelegate>
@property(nonatomic, assign)ConnectionStatus currentConnectionStatus;
@property (nonatomic, strong)NSString *userId;
@property (nonatomic, strong)NSString *passwd;

@property(nonatomic, strong)NSString *serverHost;

@property(nonatomic, assign)UIBackgroundTaskIdentifier bgTaskId;
@property(nonatomic, strong)NSTimer *forceConnectTimer;
@property(nonatomic, strong)NSTimer *suspendTimer;
@property(nonatomic, strong)NSTimer *endBgTaskTimer;
@property(nonatomic, strong)NSString *deviceToken;
@property(nonatomic, assign)int pushType;
@property(nonatomic, strong)NSString *voipDeviceToken;

@property(nonatomic, assign)BOOL requestProxying;
@property(nonatomic, strong) NSMutableArray *messageFilterList;

@property(nonatomic, assign)BOOL deviceTokenUploaded;
@property(nonatomic, assign)BOOL voipDeviceTokenUploaded;
- (void)reportEvent_OnForeground:(BOOL)isForeground;

@property(nonatomic, assign)NSUInteger backgroudRunTime;

@property(nonatomic, assign)BOOL firstTimeResume;

@property (nonatomic, assign)BOOL connectedToMainNetwork;
@property (nonatomic, assign)int doubleNetworkStrategy;
@end

@implementation WFCCNetworkService

const static NSString *WFCC_LOG_PREFIX = @"wfclient";

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
    appender_open(kAppednerAsync, [logPath UTF8String], [WFCC_LOG_PREFIX UTF8String], NULL);
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
        if (!isDir && isExist) {
            if ([path containsString:[NSString stringWithFormat:@"%@_", WFCC_LOG_PREFIX]]) {
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

- (NSArray<WFCCMessage *> *)filterReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
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
    return [messageList copy];
}

- (void)onReceiveMessage:(NSArray<WFCCMessage *> *)messages hasMore:(BOOL)hasMore {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray<WFCCMessage *> *messageList = [self filterReceiveMessage:messages hasMore:hasMore];
        [[NSNotificationCenter defaultCenter] postNotificationName:kReceiveMessages object:messageList userInfo:@{@"hasMore":@(hasMore)}];
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

- (void)onOnlineEvent:(NSArray<WFCCUserOnlineState *> *)events {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WFCCIMService sharedWFCIMService] putUseOnlineStates:events];
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserOnlineStateUpdated object:nil userInfo:@{@"states":events}];
        [self.onlineEventDelegate onOnlineEvent:events];
    });
}

- (void)onSecretChatStateChanged:(NSString *)targetId newState:(WFCCSecretChatState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSecretChatStateUpdated object:targetId userInfo:@{@"state":@(state)}];
    });
}

- (void)onSecretMessageStartBurning:(NSString *)targetId playedMessageId:(long)messageId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSecretMessageStartBurning object:targetId userInfo:@{@"messageId":@(messageId)}];
    });
}

- (void)onSecretMessageBurned:(NSArray<NSNumber *> *)messageIds {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSecretMessageBurned object:nil userInfo:@{@"messageIds":messageIds}];
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

        [[NSNotificationCenter defaultCenter] postNotificationName:kConnectionStatusChanged object:@(self.currentConnectionStatus)];
        
        if (self.connectionStatusDelegate) {
            [self.connectionStatusDelegate onConnectionStatusChanged:currentConnectionStatus];
        }
    }
}
- (void)onConnectionStatusChanged:(ConnectionStatus)status {
    if((int)status == (int)mars::stn::kConnectionStatusServerDown) {
        status = kConnectionStatusUnconnected;
    }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.currentConnectionStatus = status;
    if (status == kConnectionStatusConnected) {
        if (self.deviceToken.length && !self.deviceTokenUploaded) {
            [self setDeviceToken:self.deviceToken pushType:self.pushType];
        }
        
        if (self.voipDeviceToken.length && !self.voipDeviceTokenUploaded) {
            [self setVoipDeviceToken:self.voipDeviceToken];
        }
    }
  });
    
}

- (void)onConnectToServer:(NSString *)host ip:(NSString *)ip port:(int)port {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.connectToServerDelegate onConnectToServer:host ip:ip port:port];
    });
}

- (void)onConnected:(NSString *)host ip:(NSString *)ip port:(int)port mainNw:(BOOL)mainNw {
    self.connectedToMainNetwork = mainNw;
    dispatch_async(dispatch_get_main_queue(), ^{
        if([self.connectToServerDelegate respondsToSelector:@selector(onConnected:ip:port:mainNw:)]) {
            [self.connectToServerDelegate onConnected:host ip:ip port:port mainNw:mainNw];
        }
    });
}

- (void)onTrafficData:(int64_t)send recv:(int64_t)recv {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.trafficDataDelegate onTrafficData:send recv:recv];
    });
}

+ (WFCCNetworkService *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCCNetworkService alloc] init];
                [sharedSingleton addReceiveMessageFilter:[WFCCIMService sharedWFCIMService]];
                sharedSingleton.firstTimeResume = YES;
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
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(userChangeClock:)
                                                   name:UIApplicationSignificantTimeChangeNotification object:nil];
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
    
  //首次启动也会有Resume事件，这里需要忽略，不然会启动后连接成功后再重新连接。
  if(_firstTimeResume) {
    _firstTimeResume = NO;
    return;
  }
    
  [self reportEvent_OnForeground:YES];
//  mars::baseevent::OnNetworkChange();
  mars::stn::MakesureLonglinkConnected();
  [self endBgTask];
}

- (void)onAppTerminate {
    mars::stn::AppWillTerminate();
}

- (void)userChangeClock:(NSNotification *)notify {
    if(self.currentConnectionStatus == kConnectionStatusConnected) {
        mars::baseevent::OnNetworkChange();
    }
}

- (void)dealloc {
    
}

- (void) createMars {
  mars::app::SetCallback(mars::app::AppCallBack::Instance());
  mars::stn::setConnectionStatusCallback(new CSCB(self));
  mars::stn::setNotifyConnectToServerCallback(new CTSCB(self));
  mars::stn::setTrafficDataCallback(new TDCB(self));
  mars::stn::setErrorEventCallback(new TECB());
  mars::stn::setReceiveMessageCallback(new RPCB(self));
  mars::stn::setConferenceEventCallback(new CONFCB(self));
  mars::stn::setOnlineEventCallback(new OECB(self));
  mars::stn::setRefreshUserInfoCallback(new GUCB(self));
  mars::stn::setRefreshGroupInfoCallback(new GGCB(self));
  mars::stn::setRefreshGroupMemberCallback(new GGMCB(self));
  mars::stn::setRefreshChannelInfoCallback(new GCHCB(self));
  mars::stn::setRefreshFriendListCallback(new GFLCB(self));
  mars::stn::setRefreshFriendRequestCallback(new GFRCB(self));
  mars::stn::setRefreshSettingCallback(new GSCB(self));
  mars::stn::setSecretChatStateCallback(new SCSCB(self));
  mars::stn::setSecretMessageBurnStateCallback(new SMBSCB(self));
  mars::stn::setGetDomainInfoCallback(new GDCB(self));
  mars::stn::setCustomSortAddressCallback(new CSACB());
  mars::baseevent::OnCreate();
}
- (int64_t)connect:(NSString *)host {
    int64_t lastActiveTime = mars::stn::Connect([host UTF8String]);
    
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
    
    return lastActiveTime;
}

- (void)setServerAddress:(NSString *)host {
    [self checkSDKHost:host];
    
    self.serverHost = host;
}

- (BOOL)checkSDKHost:(NSString *)host {
    if(NSClassFromString(@"WFAVEngineKit")) {
        WFAVEngineKit *avEngineKit = [NSClassFromString(@"WFAVEngineKit") performSelector:@selector(sharedEngineKit)];
        if([avEngineKit respondsToSelector:@selector(checkAddress:)]) {
            NSLog(@"音视频SDK是高级版");
            if(![avEngineKit checkAddress:host]) {
                NSLog(@"***********************");
                NSLog(@"错误，音视频SDK跟域名不匹配。请检查SDK的授权域名是否与当前使用的域名一致。");
                NSLog(@"***********************");
            }
        } else {
            NSLog(@"音视频SDK是普通版");
        }
    }
    
    
    if(NSClassFromString(@"WFMomentService")) {
        NSObject *momentClient = [NSClassFromString(@"WFMomentService") performSelector:@selector(sharedService)];
        if([momentClient respondsToSelector:@selector(checkAddress:)]) {
            if(![momentClient performSelector:@selector(checkAddress:) withObject:host]) {
                NSLog(@"***********************");
                NSLog(@"错误，朋友圈SDK跟域名不匹配。请检查SDK的授权域名是否与当前使用的域名一致。");
                NSLog(@"***********************");
                return NO;
            }
        }
        Class momentUIKitCls = NSClassFromString(@"SDTimeLineTableViewController");
        if(!momentUIKitCls) {
            NSLog(@"***********************");
            NSLog(@"错误，朋友圈SDK存在但UI代码不存在，请集成UI代码 https://github.com/wildfirechat/ios-momentkit。如果您自己来实现UI，请忽略掉此提示");
            NSLog(@"***********************");
        }
    }
    
    if(NSClassFromString(@"WFPttClient")) {
        NSObject *pttClient = [NSClassFromString(@"WFPttClient") performSelector:@selector(sharedClient)];
        if(![pttClient performSelector:@selector(checkAddress:) withObject:host]) {
            NSLog(@"***********************");
            NSLog(@"错误，对讲SDK跟域名不匹配。请检查SDK的授权域名是否与当前使用的域名一致。");
            NSLog(@"***********************");
            return NO;
        }
    }
    return YES;
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
        if(second > 0) {
            ws.forceConnectTimer = [NSTimer scheduledTimerWithTimeInterval:second
                                                         target:self
                                                       selector:@selector(forceConnectTimeOut)
                                                       userInfo:nil
                                                        repeats:NO];
        }
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

- (void)useAES256 {
    mars::stn::useEncryptAES256();
}

- (void)useTcpShortLink {
    mars::stn::setTcpShortLink();
}

- (BOOL)isTcpShortLink {
    return mars::stn::isTCPShortLink()?YES:NO;
}

- (void)noUseFts {
    mars::stn::noUseFts();
}

- (void)setLiteMode:(BOOL)isLiteMode {
    mars::stn::setLiteMode(isLiteMode ? true:false);
}

- (void)setHeartBeatInterval:(int)second {
    if (second >= 30 && second <= 300) {
        mars::stn::SetHeartBeatInterval(second);
    }
}

-(void)setTimeOffset:(int)timeOffset {
    _timeOffset = timeOffset;
    mars::stn::setTimeOffset(timeOffset);
}

- (BOOL)connectedToMainNetwork {
    if(self.doubleNetworkStrategy == 1) {
        return YES;
    } else if(self.doubleNetworkStrategy == 2) {
        return NO;
    } else {
        return _connectedToMainNetwork;
    }
}

#define WFC_CLIENT_ID @"wfc_client_id"
- (NSString *)getClientId {
    //当应用在appstore上架后，开发者账户下的所有应用在同一个手机上具有相同的vendor id。详情请参考(IDFV(identifierForVendor)使用陷阱)https://easeapi.com/blog/blog/63-ios-idfv.html
    //这样如果同一个IM服务有多个应用，多个应用安装到同一个手机上，这样所有应用将具有相同的clientId，导致互踢现象产生。
    //处理办法就是不使用identifierForVendor，随机生成UUID，然后固定使用这个UUID就行了.
    //下面这段代码会尝试兼容之前的vendorId，如果没有在userdefaults保持clientid，则去检查一下是否有以vendorId为子目录的数据库目录存在，如果存在就以vendorid为clientid，如果不存在就使用uuid。
    
    NSString *clientId = [[NSUserDefaults standardUserDefaults] objectForKey:WFC_CLIENT_ID];
    if(!clientId.length) {
        NSString *vendorId = [UIDevice currentDevice].identifierForVendor.UUIDString;
        if(mars::app::AppCallBack::Instance()->isDBAlreadyCreated([vendorId UTF8String])) {
            clientId = vendorId;
        } else {
            CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
            clientId = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
            CFRelease(uuidObject);
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:clientId forKey:WFC_CLIENT_ID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return clientId;
}

- (int64_t)connect:(NSString *)userId token:(NSString *)token {
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
        NSLog(@"本地和服务器端连接会话将被清除！！！必须再次获取token才能登录，您确认是要清除连接会话吗？！");
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
- (NSString *)getHost {
    return [NSString stringWithUTF8String:mars::stn::GetHost().c_str()];
}
- (int)getPort {
    return mars::stn::GetPort();
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
    [self setDeviceToken:token pushType:mars::app::AppCallBack::Instance()->GetPushType()];
}

- (void)setDeviceToken:(NSString *)token pushType:(int)pushType {
    if (token.length == 0) {
        return;
    }

    _deviceToken = token;
    _pushType = pushType;

    if (!self.isLogined || self.currentConnectionStatus != kConnectionStatusConnected) {
        self.deviceTokenUploaded = NO;
        return;
    }
  
    NSString *appName =
    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    mars::stn::setDeviceToken([appName UTF8String], [token UTF8String], pushType);
    self.deviceTokenUploaded =YES;
}

- (void)setBackupAddressStrategy:(int)strategy {
    self.doubleNetworkStrategy = strategy;
    if(strategy == 0) {
        self.connectedToMainNetwork = YES;
    }
    mars::stn::setBackupAddressStrategy(strategy);
}
- (void)setBackupAddress:(NSString *)host port:(int)port {
    mars::stn::setBackupAddress([host UTF8String], port);
}

- (ConnectedNetworkType)getConnectedNetworkType {
    return (ConnectedNetworkType)mars::stn::getConnectedNetworkType();
}

- (void)setProtoUserAgent:(NSString *)userAgent {
    mars::stn::setUserAgent([userAgent UTF8String]);
}

- (void)addHttpHeader:(NSString *)header value:(NSString *)value {
    mars::stn::addHttpHeader([header UTF8String], value.length ? [value UTF8String] : "");
}

- (void)setProxyInfo:(NSString *)host ip:(NSString *)ip port:(int)port username:(NSString *)username password:(NSString *)password {
    mars::stn::setProxyInfo(host?[host UTF8String]:"", ip?[ip UTF8String]:"", port, username?[username UTF8String]:"", password?[password UTF8String]:"");
}

- (NSString *)getProtoRevision {
    return [NSString stringWithUTF8String:mars::stn::getProtoRevision().c_str()];
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
      [[NSNotificationCenter defaultCenter] postNotificationName:kGroupInfoUpdated object:nil userInfo:@{@"groupInfoList":updatedGroupInfo}];
  });
}

- (void)onGroupMemberUpdated:(NSString *)groupId members:(NSArray<WFCCGroupMember *> *)updatedGroupMembers {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kGroupMemberUpdated object:groupId userInfo:@{@"members":updatedGroupMembers}];
    });
}

- (void)onChannelInfoUpdated:(NSArray<WFCCChannelInfo *> *)updatedChannelInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kChannelInfoUpdated object:nil userInfo:@{@"channelInfoList":updatedChannelInfo}];
    });
}

- (void)onUserInfoUpdated:(NSArray<WFCCUserInfo *> *)updatedUserInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kUserInfoUpdated object:nil userInfo:@{@"userInfoList":updatedUserInfo}];
  });
}

- (void)onDomainInfoUpdated:(WFCCDomainInfo *)updatedDomainInfo {
  dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kDomainInfoUpdated object:nil userInfo:@{@"domainInfo":updatedDomainInfo}];
  });
}

- (void)onFriendListUpdated:(NSArray<NSString *> *)friendIds {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kFriendListUpdated object:friendIds];
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

