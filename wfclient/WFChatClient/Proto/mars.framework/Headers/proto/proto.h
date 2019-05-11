//
//  proto.h
//  proto
//
//  Created by WF Chat on 2017/11/8.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef proto_h
#define proto_h
#include <stdio.h>
#include <string>
#include <list>
#include <vector>


//Content Type. 1000以下为系统内置类型，自定义消息需要使用1000以上
//基本消息类型
#define MESSAGE_CONTENT_TYPE_TEXT 1
#define MESSAGE_CONTENT_TYPE_SOUND 2
#define MESSAGE_CONTENT_TYPE_IMAGE 3
#define MESSAGE_CONTENT_TYPE_LOCATION 4
#define MESSAGE_CONTENT_TYPE_FILE 5

//通知消息类型
#define MESSAGE_CONTENT_TYPE_CREATE_GROUP 104
#define MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER 105
#define MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER 106
#define MESSAGE_CONTENT_TYPE_QUIT_GROUP 107
#define MESSAGE_CONTENT_TYPE_DISMISS_GROUP 108
#define MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER 109

#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_NAME 110
#define MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS 111
#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_PORTRAIT 112

#if WFCHAT_PROTO_SERIALIZABLE
#include "rapidjson/rapidjson.h"
#include "rapidjson/writer.h"
#include "rapidjson/document.h"
using namespace wfchatjson;
#endif //WFCHAT_PROTO_SERIALIZABLE

namespace mars{
    namespace stn{
        //error code
        enum {
            //mars error code
            kEcMarsLocalTaskTimeout = -1,
            kEcMarsLocalTaskRetry = -2,
            kEcMarsLocalStartTaskFail = -3,
            kEcMarsLocalAntiAvalanche = -4,
            kEcMarsLocalChannelSelect = -5,
            kEcMarsLocalNoNet = -6,
            kEcMarsLocalCancel = -7,
            kEcMarsLocalClear = -8,
            kEcMarsLocalReset = -9,
            kEcMarsLocalTaskParam = -12,
            kEcMarsLocalCgiFrequcencyLimit = -13,
            kEcMarsLocalChannelID = -14,
        
            kEcMarsLongFirstPkgTimeout = -500,
            kEcMarsLongPkgPkgTimeout = -501,
            kEcMarsLongReadWriteTimeout = -502,
            kEcMarsLongTaskTimeout = -503,
        
            kEcMarsSocketNetworkChange = -10086,
            kEcMarsSocketMakeSocketPrepared = -10087,
            kEcMarsSocketWritenWithNonBlock = -10088,
            kEcMarsSocketReadOnce = -10089,
            kEcMarsSocketRecvErr = -10091,
            kEcMarsSocketSendErr = -10092,
            kEcMarsSocketNoopTimeout = -10093,
            kEcMarsSocketNoopAlarmTooLate = -10094,
            kEcMarsHttpSplitHttpHeadAndBody = -10194,
            kEcMarsHttpParseStatusLine = -10195,
            kEcMarsNetMsgXPHandleBufferErr = -10504,
            kEcMarsDnsMakeSocketPrepared = -10606,
            
            //proto error code
            kEcProtoCorruptData = -100001,
            kEcProtoInvalideParameter = -100002,
            
            //server error code
            kEcServerSecrectKeyMismatch = 1,
            kEcServerInvalidData = 2,
            kEcServerServerError = 4,
            kEcServerNotModified = 5,
            kEcServerTokenIncorrect = 6,
            kEcServerUserForbidden = 8,
            kEcServerNotInGroup = 9,
            kEcServerInvalidMessage = 10,
            kEcServerGroupAlreadyExist = 11,
            kEcServerPasswordIncorrect = 15,
            kEcServerFriendAlreadyRequested = 16,
            kEcServerFriendRequestOverFrequency = 17,
            kEcServerFriendRquestBlocked = 18,
            kEcServerFriendRequestOvertime = 19,
            kEcServerNotInChatroom = 20,
            kEcServerUserIsBlocked = 245,
            kEcServerInBlacklist = 246,
            kEcServerForbidden_send_msg = 247,
            kEcServerNotRight = 248,
            kEcServerTimeout = 249,
            kEcServerOverFrequence = 250,
            kEcServerInvalidParameter = 251,
            kEcServerNotExist = 253,
            kEcServerNotImplement = 254,
        };
        
        class TSerializable {
        public:
            TSerializable() {}
            virtual ~TSerializable() {}
            
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const = 0;
            virtual void Unserialize(const Value& value) = 0;
            bool fromJson(std::string jsonStr);
            std::string toJson() const;
            static std::string list2Json(std::list<std::string> &strs);
            static std::string list2Json(std::list<int> &is);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TGroupInfo : public TSerializable {
        public:
            TGroupInfo() : target(""), type(0), memberCount(0), updateDt(0) {}
            std::string target;
            std::string name;
            std::string portrait;
            std::string owner;
            int type;
            int memberCount;
            std::string extra;
            int64_t updateDt;
            virtual ~TGroupInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TGroupMember : public TSerializable {
        public:
            TGroupMember() : type(0), updateDt(0) {}
            std::string groupId;
            std::string memberId;
            std::string alias;
            int type;
            int64_t updateDt;
            virtual ~TGroupMember() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        
        class TUserInfo : public TSerializable {
        public:
            TUserInfo() : gender(0), updateDt(0), type(0) {}
            std::string uid;
            std::string name;
            std::string displayName;
            int gender;
            std::string portrait;
            std::string mobile;
            std::string email;
            std::string address;
            std::string company;
            std::string social;
            std::string extra;
            std::string friendAlias;
            std::string groupAlias;
            //0 normal; 1 robot; 2 thing;
            int type;
            int64_t updateDt;
            virtual ~TUserInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TChatroomInfo : public TSerializable {
        public:
            TChatroomInfo()  : title(""), desc(""), portrait(""), memberCount(0), createDt(0), updateDt(0), extra(""), state(0) {}
            std::string title;
            std::string desc;
            std::string portrait;
            int memberCount;
            int64_t createDt;
            int64_t updateDt;
            std::string extra;
            //0 normal; 1 not started; 2 end
            int state;
            virtual ~TChatroomInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TChatroomMemberInfo : public TSerializable {
        public:
            TChatroomMemberInfo()  : memberCount(0) {}
            int memberCount;
            std::list<std::string> olderMembers;
            virtual ~TChatroomMemberInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TChannelInfo : public TSerializable {
        public:
            TChannelInfo() : status(0), updateDt(0), automatic(0) {}
            std::string channelId;
            std::string name;
            std::string portrait;
            std::string owner;
            int status;
            std::string desc;
            std::string extra;
            std::string secret;
            std::string callback;
            int64_t updateDt;
            int automatic;
            virtual ~TChannelInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TMessageContent : public TSerializable {
        public:
            TMessageContent() : type(0), mediaType(0), mentionedType(0) {}
            TMessageContent(const TMessageContent &c) :
            type(c.type),
            searchableContent(c.searchableContent),
            pushContent(c.pushContent),
            content(c.content),
            binaryContent(c.binaryContent),
            localContent(c.localContent),
            mediaType(c.mediaType),
            remoteMediaUrl(c.remoteMediaUrl),
            localMediaPath(c.localMediaPath),
            mentionedType(c.mentionedType),
            mentionedTargets(c.mentionedTargets) {}
            
            TMessageContent operator=(const TMessageContent &c) {
                type = c.type;
                searchableContent = c.searchableContent;
                pushContent = c.pushContent;
                content = c.content;
                binaryContent = c.binaryContent;
                localContent = c.localContent;
                mediaType = c.mediaType;
                remoteMediaUrl = c.remoteMediaUrl;
                localMediaPath = c.localMediaPath;
                mentionedType = c.mentionedType;
                mentionedTargets = c.mentionedTargets;
                return *this;
            }
            int type;
            std::string searchableContent;
            std::string pushContent;
            std::string content;
            std::string binaryContent;
            std::string localContent;
            int mediaType;
            std::string remoteMediaUrl;
            std::string localMediaPath;
            
            int mentionedType;
            std::list<std::string> mentionedTargets;
            virtual ~TMessageContent(){
            }
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        typedef enum {
            Message_Status_Sending,
            Message_Status_Sent,
            Message_Status_Send_Failure,
            Message_Status_Mentioned,
            Message_Status_AllMentioned,
            Message_Status_Unread,
            Message_Status_Readed,
            Message_Status_Played
        } MessageStatus;
        
        class TMessage : public TSerializable {
        public:
            TMessage() : conversationType(0), line(0), messageId(-1), direction(0), status(Message_Status_Sending), messageUid(0), timestamp(0) {}
            
            int conversationType;
            std::string target;
            int line;
            
            std::string from;
            TMessageContent content;
            long messageId;
            int direction;
            MessageStatus status;
            int64_t messageUid;
            int64_t timestamp;
            std::list<std::string> to;
            virtual ~TMessage(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TUnreadCount : public TSerializable {
        public:
            TUnreadCount():unread(0),unreadMention(0),unreadMentionAll(0){}
            int unread;
            int unreadMention;
            int unreadMentionAll;
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TConversation : public TSerializable {
        public:
            TConversation() : conversationType(0), line(0), lastMessage() , timestamp(0), unreadCount(), isTop(false), isSilent(false) {}
            int conversationType;
            std::string target;
            int line;
            TMessage lastMessage;
            int64_t timestamp;
            std::string draft;
            TUnreadCount unreadCount;
            bool isTop;
            bool isSilent;
            virtual ~TConversation(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TConversationSearchresult : public TSerializable {
        public:
            TConversationSearchresult() : conversationType(0), line(0), marchedMessage(), timestamp(0), marchedCount(0)  {}
            int conversationType;
            std::string target;
            int line;
            //only marchedCount == 1, load the message
            TMessage marchedMessage;
            int64_t timestamp;
            int marchedCount;
            virtual ~TConversationSearchresult(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TGroupSearchResult : public TSerializable {
        public:
            TGroupSearchResult() : marchedType(-1)  {}
            TGroupInfo groupInfo;
            int marchedType;  //0 march name, 1 march group member, 2 both
            std::list<std::string> marchedMemberNames;
            virtual ~TGroupSearchResult(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class TFriendRequest : public TSerializable {
        public:
            TFriendRequest() : direction(0), status(0), readStatus(0), timestamp(0) {}
            int direction;
            std::string target;
            std::string reason;
            int status;
            int readStatus;
            int64_t timestamp;
            virtual ~TFriendRequest(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        enum UserSettingScope {
            kUserSettingConversationSilent = 1,
            kUserSettingGlobalSilent = 2,
            kUserSettingConversationTop = 3,
            kUserSettingHiddenNotificationDetail = 4,
            kUserSettinGroupHideNickname = 5,
            kUserSettingFavouriteGroup = 6,
            kUserSettingConversationSync = 7,
            kUserSettingMyChannels = 8,
            kUserSettingListenedChannels = 9,
            
            kUserSettingCustomBegin = 1000
        };

        
        class TUserSettingEntry : public TSerializable {
        public:
            TUserSettingEntry() : scope(kUserSettingCustomBegin), updateDt(0) {}
            UserSettingScope scope;
            std::string key;
            std::string value;
            int64_t updateDt;
            virtual ~TUserSettingEntry(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
        class GeneralStringCallback {
        public:
            virtual void onSuccess(std::string key) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GeneralStringCallback() {}
        };
        
        class UploadMediaCallback {
        public:
            virtual void onSuccess(std::string key) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual void onProgress(int current, int total) = 0;
            virtual ~UploadMediaCallback() {}
        };
        
        class SendMsgCallback {
        public:
            virtual void onPrepared(long messageId, int64_t savedTime) = 0;
            virtual void onMediaUploaded(std::string remoteUrl) = 0;
            virtual void onSuccess(long long messageUid, long long timestamp) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual void onProgress(int uploaded, int total) = 0;
            virtual ~SendMsgCallback() {}
        };
        
        class UpdateMediaCallback {
        public:
            virtual void onSuccess(const std::string &remoteUrl) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual void onProgress(int current, int total) = 0;
            virtual ~UpdateMediaCallback() {}
        };
        
        
        class SearchUserCallback {
        public:
            virtual void onSuccess(const std::list<TUserInfo> &users, const std::string &keyword, int page) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~SearchUserCallback() {}
        };
        
        class SearchChannelCallback {
        public:
            virtual void onSuccess(const std::list<TChannelInfo> &channels, const std::string &keyword) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~SearchChannelCallback() {}
        };
        
        class CreateGroupCallback {
        public:
            virtual void onSuccess(std::string groupId) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~CreateGroupCallback() {}
        };
        
        class CreateChannelCallback {
        public:
            virtual void onSuccess(const TChannelInfo &channelInfo) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~CreateChannelCallback() {}
        };
        
        class GeneralOperationCallback {
        public:
            virtual void onSuccess() = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GeneralOperationCallback() {}
        };
        
        class LoadRemoteMessagesCallback {
        public:
            virtual void onSuccess(const std::list<TMessage> &messageList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~LoadRemoteMessagesCallback() {}
        };
        
        class GetChatroomInfoCallback {
        public:
            virtual void onSuccess(const TChatroomInfo &info) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetChatroomInfoCallback() {}
        };
        
        class GetChatroomMemberInfoCallback {
        public:
            virtual void onSuccess(const TChatroomMemberInfo &info) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetChatroomMemberInfoCallback() {}
        };
        
        class GetGroupInfoCallback {
        public:
            virtual void onSuccess(const std::list<mars::stn::TGroupInfo> &groupInfoList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetGroupInfoCallback() {}
        };
        
        class GetGroupMembersCallback {
        public:
            virtual void onSuccess(const std::string &groupId, const std::list<mars::stn::TGroupMember> &groupMemberList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetGroupMembersCallback() {}
        };
        
        
        class GetChannelInfoCallback {
        public:
            virtual void onSuccess(const std::list<mars::stn::TChannelInfo> &channelInfoList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetChannelInfoCallback() {}
        };
        
        class GetUserInfoCallback {
        public:
            virtual void onSuccess(const std::list<TUserInfo> &userInfoList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetUserInfoCallback() {}
        };
        
        class GetMyFriendsCallback {
        public:
            virtual void onSuccess(std::list<std::string> friendIdList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetMyFriendsCallback() {}
        };

        class GetFriendRequestCallback {
        public:
            virtual void onSuccess(bool hasNewRequest) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetFriendRequestCallback() {}
        };
      
      class GetSettingCallback {
      public:
        virtual void onSuccess(bool hasNewRequest) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetSettingCallback() {}
      };
        enum ConnectionStatus {
            kConnectionStatusSecretKeyMismatch = -6,
            kConnectionStatusTokenIncorrect = -5,
            kConnectionStatusServerDown = -4,
            kConnectionStatusRejected = -3,
            kConnectionStatusLogout = -2,
            kConnectionStatusUnconnected = -1,
            kConnectionStatusConnecting = 0,
            kConnectionStatusConnected = 1,
            kConnectionStatusReceiving = 2
        };
        
        
        
        class ConnectionStatusCallback {
        public:
            virtual void onConnectionStatusChanged(ConnectionStatus connectionStatus) = 0;
        };
        
        class ReceiveMessageCallback {
        public:
            virtual void onReceiveMessage(const std::list<TMessage> &messageList, bool hasMore) = 0;
            virtual void onRecallMessage(const std::string operatorId, long long messageUid) = 0;
        };
        
        extern bool setAuthInfo(const std::string &userId, const std::string &token);
        extern void Disconnect(uint8_t flag);
        extern void (*Connect)(const std::string& host, uint16_t shortLinkPort);
        extern void setConnectionStatusCallback(ConnectionStatusCallback *callback);
        extern void setReceiveMessageCallback(ReceiveMessageCallback *callback);
        extern void setDNSResult(std::vector<std::string> serverIPs);
        extern void setRefreshUserInfoCallback(GetUserInfoCallback *callback);
        extern void setRefreshGroupInfoCallback(GetGroupInfoCallback *callback);
        extern void setRefreshGroupMemberCallback(GetGroupMembersCallback *callback);
        
        extern void setRefreshChannelInfoCallback(GetChannelInfoCallback *callback);
        extern void setRefreshFriendListCallback(GetMyFriendsCallback *callback);
        extern void setRefreshFriendRequestCallback(GetFriendRequestCallback *callback);
        extern void setRefreshSettingCallback(GetSettingCallback *callback);
        extern ConnectionStatus getConnectionStatus();
        
        extern int64_t getServerDeltaTime();
        extern void setDeviceToken(const std::string &appName, const std::string &deviceToken, int pushType);
        
        extern int (*sendMessage)(TMessage &tmsg, SendMsgCallback *callback, int expireDuration);
        
        
        extern void recallMessage(long long messageUid, GeneralOperationCallback *callback);
        
        extern void loadRemoteMessages(const TConversation &conv, long long beforeUid, int count, LoadRemoteMessagesCallback *callback);
        
        extern int uploadGeneralMedia(std::string mediaData, int mediaType, UpdateMediaCallback *callback);
        
        extern int modifyMyInfo(const std::list<std::pair<int, std::string>> &infos, GeneralOperationCallback *callback);
        
        extern int modifyUserSetting(int scope, const std::string &key, const std::string &value, GeneralOperationCallback *callback);
        
        extern void searchUser(const std::string &keyword, bool puzzy, int page, SearchUserCallback *callback);
        extern void sendFriendRequest(const std::string &userId, const std::string &reason, GeneralOperationCallback *callback);
        
        extern void loadFriendRequestFromRemote();
        extern void loadFriendFromRemote();
        extern void handleFriendRequest(const std::string &userId, bool accept, GeneralOperationCallback *callback);
        extern void deleteFriend(const std::string &userId, GeneralOperationCallback *callback);
        extern void setFriendAlias(const std::string &userId, const std::string &alias, GeneralOperationCallback *callback);
        
        extern void blackListRequest(const std::string &userId, bool blacked, GeneralOperationCallback *callback);
        
        extern void (*createGroup)(const std::string &groupId, const std::string &groupName, const std::string &groupPortrait, const std::list<std::string> &groupMembers, const std::list<int> &notifyLines, TMessageContent &content, CreateGroupCallback *callback);
        
        extern void (*addMembers)(const std::string &groupId, const std::list<std::string> &members, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*kickoffMembers)(const std::string &groupId, const std::list<std::string> &members, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*quitGroup)(const std::string &groupId, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*dismissGroup)(const std::string &groupId, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*getGroupInfo)(const std::list<std::pair<std::string, int64_t>> &groupIdList, GetGroupInfoCallback *callback);
        
        extern void (*modifyGroupInfo)(const std::string &groupId, int type, const std::string &newValue, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*modifyGroupAlias)(const std::string &groupId, const std::string &newAlias, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*getGroupMembers)(const std::string &groupId, int64_t updateDt);
        
        extern void (*transferGroup)(const std::string &groupId, const std::string &newOwner, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
        
        extern void (*getUserInfo)(const std::list<std::pair<std::string, int64_t>> &userReqList, GetUserInfoCallback *callback);
        
        extern void reloadGroupInfoFromRemote(const std::list<std::pair<std::string, int64_t>> &groupReqList);
        extern void reloadUserInfoFromRemote(const std::list<std::pair<std::string, int64_t>> &userReqList);
        extern void reloadGroupMembersFromRemote(const std::string &groupId, int64_t updateDt);
        extern void clearFriendRequestUnread(int64_t maxDt);
        extern std::string getJoinedChatroom();
        extern void joinChatroom(const std::string &chatroomId, GeneralOperationCallback *callback);
        extern void quitChatroom(const std::string &chatroomId, GeneralOperationCallback *callback);
        extern void getChatroomInfo(const std::string &chatroomId, int64_t lastUpdateDt, GetChatroomInfoCallback *callback);
        extern void getChatroomMemberInfo(const std::string &chatroomId, int maxCount, GetChatroomMemberInfoCallback *callback);
        
        extern void syncConversationReadDt(int conversatinType, const std::string &target, int ine, int64_t readedDt);
        
        
        extern void createChannel(const std::string &channelId, const std::string &channelName, const std::string &channelPortrait, int status, const std::string desc, const std::string &extra, const std::string &secret, const std::string &cb, CreateChannelCallback *callback);
        
        extern void modifyChannelInfo(const std::string &channelId, int type, const std::string &newValue, GeneralOperationCallback *callback);
        
        extern void transferChannel(const std::string &channelId, const std::string &newOwner, GeneralOperationCallback *callback);
        
        extern void destoryChannel(const std::string &channelId, GeneralOperationCallback *callback);
        
        
        extern void searchChannel(const std::string &keyword, bool puzzy, SearchChannelCallback *callback);
        
        extern void listenChannel(const std::string &channelId, bool listen, GeneralOperationCallback *callback);
    }
}




#endif /* proto_h */
