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
#include <map>
#include <vector>


//Content Type. Below 1000 are predefine types. Custom types should over than 1000
//Base message content type
#define MESSAGE_CONTENT_TYPE_TEXT 1
#define MESSAGE_CONTENT_TYPE_SOUND 2
#define MESSAGE_CONTENT_TYPE_IMAGE 3
#define MESSAGE_CONTENT_TYPE_LOCATION 4
#define MESSAGE_CONTENT_TYPE_FILE 5

//Notification message content type
#define MESSAGE_CONTENT_TYPE_CREATE_GROUP 104
#define MESSAGE_CONTENT_TYPE_ADD_GROUP_MEMBER 105
#define MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER 106
#define MESSAGE_CONTENT_TYPE_QUIT_GROUP 107
#define MESSAGE_CONTENT_TYPE_DISMISS_GROUP 108
#define MESSAGE_CONTENT_TYPE_TRANSFER_GROUP_OWNER 109

#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_NAME 110
#define MESSAGE_CONTENT_TYPE_MODIFY_GROUP_ALIAS 111
#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_PORTRAIT 112

#define MESSAGE_CONTENT_TYPE_CHANGE_MUTE 113
#define MESSAGE_CONTENT_TYPE_CHANGE_JOINTYPE 114
#define MESSAGE_CONTENT_TYPE_CHANGE_PRIVATECHAT 115
#define MESSAGE_CONTENT_TYPE_CHANGE_SEARCHABLE 116
#define MESSAGE_CONTENT_TYPE_SET_MANAGER 117
#define MESSAGE_CONTENT_TYPE_MUTE_MEMBER 118
#define MESSAGE_CONTENT_TYPE_ALLOW_MEMBER 119


//kickoff visiable notification message content type
//#define MESSAGE_CONTENT_TYPE_KICKOF_GROUP_MEMBER_VISIBLE_NOTIFICATION 120
//quit visiable notification message content type
//#define MESSAGE_CONTENT_TYPE_QUIT_GROUP_VISIBLE_NOTIFICATION 121

#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_EXTRA 122
#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_MEMBER_EXTRA 123
#define MESSAGE_CONTENT_TYPE_CHANGE_GROUP_SETTINGS 124


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
            kEcMarsLongLinkNotEstablished = -504,

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
            kEcServerKickedOff = 7,
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
            kEcServerNotLicensed = 22,
            kEcServerTimeInconsistent = 30,
            kEcServerUserNotPrepared = 238,
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
            TGroupInfo() : target(""), type(0), memberCount(0), updateDt(0), memberDt(0), mute(0), joinType(0), privateChat(0), searchable(0), historyMessage(0), maxMemberCount(0), superGroup(0), deleted(0) {}
            std::string target;
            std::string name;
            std::string portrait;
            std::string owner;
            int type;
            int memberCount;
            std::string extra;
            std::string remark;
            int64_t updateDt;
            int64_t memberDt;
            int mute;
            int joinType;
            int privateChat;
            int searchable;
            int historyMessage;
            int maxMemberCount;
            int superGroup;
            int deleted;
            virtual ~TGroupInfo() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };

        class TGroupMember : public TSerializable {
        public:
            TGroupMember() : type(0), updateDt(0), createDt(0) {}
            std::string groupId;
            std::string memberId;
            std::string alias;
            int type;
            int64_t updateDt;
            int64_t createDt;
            std::string extra;
            virtual ~TGroupMember() {}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };


        class TUserInfo : public TSerializable {
        public:
            TUserInfo() : gender(0), type(0), deleted(0), updateDt(0) {}
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
            int deleted;
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

        class TChannelMenu : public TSerializable {
        public:
            TChannelMenu() {}
            std::string menuId;
            std::string type;
            std::string name;
            std::string key;
            std::string url;
            std::string mediaId;
            std::string articleId;
            std::string appId;
            std::string appPage;
            std::string extra;
            std::vector<TChannelMenu> subMenus;
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
            std::vector<TChannelMenu> menus;
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };

        class TMessageContent : public TSerializable {
        public:
            TMessageContent() : type(0), mediaType(0), mentionedType(0), expireTime(0), notLoaded(false) {}
            TMessageContent(const TMessageContent &c) :
            type(c.type),
            searchableContent(c.searchableContent),
            pushContent(c.pushContent),
            pushData(c.pushData),
            content(c.content),
            binaryContent(c.binaryContent),
            localContent(c.localContent),
            mediaType(c.mediaType),
            remoteMediaUrl(c.remoteMediaUrl),
            localMediaPath(c.localMediaPath),
            mentionedType(c.mentionedType),
            mentionedTargets(c.mentionedTargets),
            extra(c.extra),
            expireTime(c.expireTime),
            notLoaded(c.notLoaded) {}

            TMessageContent operator=(const TMessageContent &c) {
                type = c.type;
                searchableContent = c.searchableContent;
                pushContent = c.pushContent;
                pushData = c.pushData;
                content = c.content;
                binaryContent = c.binaryContent;
                localContent = c.localContent;
                mediaType = c.mediaType;
                remoteMediaUrl = c.remoteMediaUrl;
                localMediaPath = c.localMediaPath;
                mentionedType = c.mentionedType;
                mentionedTargets = c.mentionedTargets;
                extra = c.extra;
                expireTime = c.expireTime;
                notLoaded = c.notLoaded;
                return *this;
            }
            int type;
            std::string searchableContent;
            std::string pushContent;
            std::string pushData;
            std::string content;
            std::string binaryContent;
            std::string localContent;
            int mediaType;
            std::string remoteMediaUrl;
            std::string localMediaPath;

            int mentionedType;
            std::list<std::string> mentionedTargets;
            std::string extra;
            int64_t expireTime;
            bool notLoaded;
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
            std::string localExtra;
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
            TConversation() : conversationType(0), line(0), lastMessage() , timestamp(0), unreadCount(), isTop(0), isSilent(false) {}
            int conversationType;
            std::string target;
            int line;
            TMessage lastMessage;
            int64_t timestamp;
            std::string draft;
            TUnreadCount unreadCount;
            int isTop;
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
            std::string extra;
            int status;
            int readStatus;
            int64_t timestamp;
            virtual ~TFriendRequest(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
    
        class TFriend : public TSerializable {
        public:
            TFriend() : timestamp(0) {}
            std::string userId;
            std::string alias;
            std::string extra;
            int64_t timestamp;
            virtual ~TFriend(){}
    #if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
    #endif //WFCHAT_PROTO_SERIALIZABLE
        };
    
    class TDomainInfo : public TSerializable {
    public:
        TDomainInfo() : updateDt(0) {}
        std::string domainId;
        std::string name;
        std::string desc;
        std::string email;
        std::string tel;
        std::string address;
        std::string extra;
        int64_t updateDt;
        virtual ~TDomainInfo(){}
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
            kUserSettingPCOnline = 10,
            kUserSettingConversationReaded = 11,
            kUserSettingWebOnline = 12,
            kUserSettingDisableRecipt = 13,
            kUserSettingFavouriteUser = 14,
            kUserSettingMuteWhenPCOnline = 15,
            kUserSettingLinesReaded = 16,
            kUserSettingNoDisturbing = 17,
            kUserSettingConversationClearMessage = 18,
            kUserSettingConversationDraft = 19,
            kUserSettingDisableSyncDraft = 20,
            kUserSettingVoipSilent = 21,
            kUserSettingPttReserved = 22,
            kUserSettingCustomState = 23,
            kUserSettingDisableSecretChat = 24,
            kUserSettingPttSilent = 25,
            kUserSettingGroupRemark = 26,

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
    
        class TReadEntry : public TSerializable {
        public:
            TReadEntry() : conversationType(0), line(0), readDt(0) {}
            std::string userId;
            int conversationType;
            std::string target;
            int line;
            int64_t readDt;
            virtual ~TReadEntry(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
    
        class TDeliveryEntry : public TSerializable {
        public:
            TDeliveryEntry() : rcvdDt(0) {}
            std::string userId;
            int64_t rcvdDt;
            virtual ~TDeliveryEntry(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
    
        class TFileRecord : public TSerializable {
        public:
            TFileRecord() : messageUid(0),conversationType(0), line(0),size(0),downloadCount(0), timestamp(0)  {}
            int64_t messageUid;
            std::string userId;
            int conversationType;
            std::string target;
            int line;
            std::string name;
            std::string url;
            int size;
            int downloadCount;
            long long timestamp;
            virtual ~TFileRecord(){}
#if WFCHAT_PROTO_SERIALIZABLE
            virtual void Serialize(void *writer) const;
            virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
        };
        
    class TMomentsMedia {
    public:
        TMomentsMedia():width(0), height(0) {}
        virtual ~TMomentsMedia() {}
        std::string mediaUrl;
        std::string thumbUrl;
        int width;
        int height;
    };
    
    class TMomentsComment {
    public:
        TMomentsComment():feedId(0), commentId(0), replyId(0), type(0), serverTime(0) {}
        virtual ~TMomentsComment() {}
        int64_t feedId;
        int64_t commentId;
        int64_t replyId;
        std::string sender;
        int type;
        std::string text;
        std::string replyTo;
        int64_t serverTime;
        std::string extra;
    };
    
    class TMomentsFeed {
    public:
        TMomentsFeed():feedId(0), type(0), serverTime(0), hasMore(0) {}
        virtual ~TMomentsFeed() {}
        int64_t feedId;
        std::string sender;
        int type;
        std::string text;
        std::list<TMomentsMedia> medias;
        std::list<std::string> mentionedUsers;
        std::list<std::string> toUsers;
        std::list<std::string> excludeUsers;
        int64_t serverTime;
        std::string extra;
        std::list<TMomentsComment> comments;
        int hasMore;
    };
    
    class TUploadMediaUrlEntry : public TSerializable {
    public:
        TUploadMediaUrlEntry():type(0) {}
        virtual ~TUploadMediaUrlEntry() {}
        std::string uploadUrl;
        std::string backupUploadUrl;
        std::string mediaUrl;
        int type;
#if WFCHAT_PROTO_SERIALIZABLE
        virtual void Serialize(void *writer) const;
        virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
    };
    
    class TOnlineState : public TSerializable {
    public:
        TOnlineState():platform(0), state(0), lastSeen(0) {}
        virtual ~TOnlineState() {}
        int platform;
        int state;
        int64_t lastSeen;
#if WFCHAT_PROTO_SERIALIZABLE
        virtual void Serialize(void *writer) const;
        virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
    };
    
    class TUserOnlineState : public TSerializable {
    public:
        TUserOnlineState() : customState(0) {}
        virtual ~TUserOnlineState() {}
        std::string userId;
        int customState;
        std::string customText;
        std::list<TOnlineState> states;
#if WFCHAT_PROTO_SERIALIZABLE
        virtual void Serialize(void *writer) const;
        virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
    };
    
    class TSecretChatInfo : public TSerializable {
    public:
        TSecretChatInfo() : state(0), burnTime(0), createTime(0) {}
        virtual ~TSecretChatInfo() {}
        std::string targetId;
        std::string userId;
        int state;
        int burnTime;
        int64_t createTime;
#if WFCHAT_PROTO_SERIALIZABLE
        virtual void Serialize(void *writer) const;
        virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
    };
    
    class TBurnMessageInfo : public TSerializable {
    public:
        TBurnMessageInfo() : messageId(0), messageUid(0), direction(0), burnTime(0), isMedia(0), messageDt(0) {}
        virtual ~TBurnMessageInfo() {}
        long messageId;
        int64_t messageUid;
        std::string targetId;
        int direction;
        int burnTime;
        int isMedia;
        int64_t messageDt;
#if WFCHAT_PROTO_SERIALIZABLE
        virtual void Serialize(void *writer) const;
        virtual void Unserialize(const Value& value);
#endif //WFCHAT_PROTO_SERIALIZABLE
    };
    

        class GeneralStringCallback {
        public:
            virtual void onSuccess(const std::string &key) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GeneralStringCallback() {}
        };
    
        class GeneralStringListCallback {
        public:
            virtual void onSuccess(const std::list<std::string> &stringList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GeneralStringListCallback() {}
        };

        class UploadMediaCallback {
        public:
            virtual void onSuccess(const std::string &key) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual void onProgress(int current, int total) = 0;
            virtual ~UploadMediaCallback() {}
        };
    
    class GetUploadMediaUrlCallback {
    public:
        virtual void onSuccess(const TUploadMediaUrlEntry &urlEntry) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetUploadMediaUrlCallback() {}
    };

        class SendMsgCallback {
        public:
            virtual void onPrepared(long messageId, int64_t savedTime) = 0;
            virtual void onMediaUploaded(const std::string &remoteUrl) = 0;
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
    
    class GetAuthorizedMediaUrlCallback {
    public:
        virtual void onSuccess(const std::string &remoteUrl, const std::string &backupRemoteUrl) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetAuthorizedMediaUrlCallback() {}
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
            virtual void onSuccess(const std::string &groupId) = 0;
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
    
    class LoadRemoteDomainsCallback {
    public:
        virtual void onSuccess(const std::list<TDomainInfo> &domains) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~LoadRemoteDomainsCallback() {}
    };
    
        class LoadFileRecordCallback {
        public:
            virtual void onSuccess(const std::list<TFileRecord> &fileList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~LoadFileRecordCallback() {}
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

    class GetDomainInfoCallback {
    public:
        virtual void onSuccess(const TDomainInfo &domain) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetDomainInfoCallback() {}
    };
    
        class GetUserInfoCallback {
        public:
            virtual void onSuccess(const std::list<TUserInfo> &userInfoList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetUserInfoCallback() {}
        };

        class GetMyFriendsCallback {
        public:
            virtual void onSuccess(const std::list<std::string> &friendIdList) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetMyFriendsCallback() {}
        };

        class GetFriendRequestCallback {
        public:
            virtual void onSuccess(const std::list<std::string> &newRequests) = 0;
            virtual void onFalure(int errorCode) = 0;
            virtual ~GetFriendRequestCallback() {}
        };

      class GetSettingCallback {
      public:
        virtual void onSuccess(bool hasNewRequest) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetSettingCallback() {}
      };
    
    class GetOneUserInfoCallback {
    public:
        virtual void onSuccess(const TUserInfo &tUserInfo) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetOneUserInfoCallback() {}
    };
    class GetOneGroupInfoCallback {
    public:
        virtual void onSuccess(const mars::stn::TGroupInfo &tGroupInfo) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~GetOneGroupInfoCallback() {}
    };
    
    class WatchOnlineStateCallback {
    public:
        virtual void onSuccess(const std::list<mars::stn::TUserOnlineState> &stateList) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~WatchOnlineStateCallback() {}
    };
    
    class CreateSecretChatCallback {
    public:
        virtual void onSuccess(const std::string &targetId, int line) = 0;
        virtual void onFalure(int errorCode) = 0;
        virtual ~CreateSecretChatCallback() {}
    };
    
    class SecretChatStateCallback {
    public:
        virtual void onStateChanged(const std::string &targetId, int state) = 0;
        virtual ~SecretChatStateCallback() {}
    };
    
    class SecretMessageBurnStateCallback {
    public:
        virtual void onSecretMessageStartBurning(const std::string &targetId, long playedMsgId) = 0;
        virtual void onSecretMessageBurned(const std::list<long> &messageIds) = 0;
        virtual ~SecretMessageBurnStateCallback() {}
    };
    
    class CustomSortAddressCallback {
    public:
        virtual bool sortAddress(bool longLink, std::vector<std::pair<std::string, int>> &ipPorts) = 0;
        virtual ~CustomSortAddressCallback() {}
    };
    
        enum ConnectionStatus {
            kConnectionStatusTimeInconsistent = -9,
            kConnectionStatusNotLicensed = -8,
            kConnectionStatusKickedOff = -7,
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
    
    class NotifyConnectToServerCallback {
    public:
        virtual void OnConnectToServer(const std::string &host, const std::string &ip, int port) = 0;
        virtual void OnConnected(const std::string &host, const std::string &ip, int port, bool mainNW) {}
    };
    
    class TrafficDataCallback {
    public:
        virtual void OnTrafficData(int64_t send, int64_t recv) = 0;
    };
    
    class ErrorEventCallback {
    public:
        virtual void OnErrorEvent(int errorType, const std::string &errMsg) = 0;
    };

        class ReceiveMessageCallback {
        public:
            virtual void onReceiveMessage(const std::list<TMessage> &messageList, bool hasMore) = 0;
            virtual void onRecallMessage(const std::string &operatorId, long long messageUid) = 0;
            virtual void onDeleteMessage(long long messageUid) = 0;
            virtual void onUserReceivedMessage(const std::map<std::string, int64_t> &userReceived) = 0;
            virtual void onUserReadedMessage(const std::list<TReadEntry> &userReceived) = 0;
        };
    
        class ConferenceEventCallback {
        public:
            virtual void onConferenceEvent(const std::string &event) = 0;
        };

        class OnlineEventCallback {
        public:
            virtual void onOnlineEvent(const std::list<mars::stn::TUserOnlineState> &events) = 0;
        };

        extern std::string getCurrentUserId();

        extern void useEncryptSM4();
        extern void useEncryptAES256();
        extern void setTimeOffset(int timeoffset);
        extern void setTcpShortLink();
        extern bool isTCPShortLink();
        extern void noUseFts();
        extern bool setAuthInfo(const std::string &userId, const std::string &token);
        extern void setLiteMode(bool liteMode);
        extern void setLowBPSMode(bool lowBPSMode);
        extern void Disconnect(uint8_t flag);
        extern int64_t Connect(const std::string& host);
        extern void setBackupAddressStrategy(int strategy);
        extern void setBackupAddress(const std::string &host, int port);
        extern int getConnectedNetworkType();
        extern int getRoutePort();
        extern void AppWillTerminate();
        extern void setConnectionStatusCallback(ConnectionStatusCallback *callback);
        extern void setCustomSortAddressCallback(CustomSortAddressCallback *callback);
        extern void setNotifyConnectToServerCallback(NotifyConnectToServerCallback *callback);
        extern void setTrafficDataCallback(TrafficDataCallback *callback);
        extern void setErrorEventCallback(ErrorEventCallback *callback);
    
        extern void setReceiveMessageCallback(ReceiveMessageCallback *callback);
        extern void setConferenceEventCallback(ConferenceEventCallback *callback);
        extern void setOnlineEventCallback(OnlineEventCallback *callback);
    
        extern void setDNSResult(std::vector<std::string> serverIPs);
        extern void setRefreshUserInfoCallback(GetUserInfoCallback *callback);
        extern void setRefreshGroupInfoCallback(GetGroupInfoCallback *callback);
        extern void setRefreshGroupMemberCallback(GetGroupMembersCallback *callback);

        extern void setRefreshChannelInfoCallback(GetChannelInfoCallback *callback);
        extern void setRefreshFriendListCallback(GetMyFriendsCallback *callback);
        extern void setRefreshFriendRequestCallback(GetFriendRequestCallback *callback);
        extern void setRefreshSettingCallback(GetSettingCallback *callback);
        extern void setSecretChatStateCallback(SecretChatStateCallback *callback);
        extern void setSecretMessageBurnStateCallback(SecretMessageBurnStateCallback *callback);
        extern void setGetDomainInfoCallback(GetDomainInfoCallback *callback);
        extern ConnectionStatus getConnectionStatus();

        extern int64_t getServerDeltaTime();
        extern void setDeviceToken(const std::string &appName, const std::string &deviceToken, int pushType);

        extern long sendMessage(TMessage &tmsg, SendMsgCallback *callback, int expireDuration);

        extern bool sendMessageEx(long messageId, SendMsgCallback *callback, int expireDuration);
    
        extern bool cancelSendingMessage(long messageId);

        extern void recallMessage(long long messageUid, GeneralOperationCallback *callback);
        extern void deleteRemoteMessage(long long messageUid, GeneralOperationCallback *callback);
        extern void updateRemoteMessageContent(long long messageUid, const TMessageContent &messageContent, bool distribute, bool updateLocal, GeneralOperationCallback *callback);
        extern void loadRemoteMessages(const TConversation &conv, const std::list<int> &contentTypes, long long beforeUid, int count, LoadRemoteMessagesCallback *callback);

        extern void loadRemoteConversationMessages(const TConversation &conv, const std::list<int> &contentTypes, long long beforeUid, int count, LoadRemoteMessagesCallback *callback);

        extern void loadRemoteLineMessages(int type, const std::list<int> &contentTypes, long long beforeUid, int count, LoadRemoteMessagesCallback *callback);
    
        extern void loadRemoteMessage(long long messageUid, LoadRemoteMessagesCallback *callback);
        extern void loadRemoteConversationMessagesEx(const TConversation &conv, const std::list<int> &contentTypes, long long messageUid, int count, bool before, bool saveToDb, LoadRemoteMessagesCallback *callback);
    
        extern void GetMessages(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser, LoadRemoteMessagesCallback *callback);
    
        extern void GetMessagesByMessageStatus(int conversationType, const std::string &target, int line, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser, LoadRemoteMessagesCallback *callback);
    
        extern void GetMentionedMessages(int conversationType, const std::string &target, int line, bool desc, int count, int64_t startPoint, LoadRemoteMessagesCallback *callback);
    
        extern void GetMessages(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser, LoadRemoteMessagesCallback *callback);
    
        extern void GetMessagesByMessageStatus(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser, LoadRemoteMessagesCallback *callback);
    
        extern void GetMessagesByTimes(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startTimestamp, const std::string &withUser, LoadRemoteMessagesCallback *callback);
    
        extern void GetUserMessages(const std::string &user, int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, LoadRemoteMessagesCallback *callback);
    
        extern void GetUserMessages(const std::string &user, const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, LoadRemoteMessagesCallback *callback);
    
        extern void clearRemoteConversationMessages(int conversationType, const std::string &target, int line, GeneralOperationCallback *callback);

        extern void loadConversationFileRecords(const TConversation &conv, const std::string &fromUser, long long beforeUid, int order, int count, LoadFileRecordCallback *callback);
        extern void loadMyFileRecords(long long beforeUid, int order, int count, LoadFileRecordCallback *callback);
        extern void deleteFileRecords(long long messageUid, GeneralOperationCallback *callback);
        extern void searchConversationFileRecords(const std::string &keyword, const TConversation &conv, const std::string &fromUser, long long beforeUid, int order, int count, LoadFileRecordCallback *callback);
        extern void searchMyFileRecords(const std::string &keyword, long long beforeUid, int order, int count, LoadFileRecordCallback *callback);
    
        extern int uploadGeneralMedia(const std::string &fileName, const std::string &mediaData, int mediaType, UpdateMediaCallback *callback);

        extern void getAuthorizedMediaUrl(long long messageUid, int mediaType, const std::string &mediaUrl, GetAuthorizedMediaUrlCallback *callback);
        extern void getUploadMediaUrl(const std::string &fileName, int mediaType, const std::string &contentType, GetUploadMediaUrlCallback *callback);

        extern int modifyMyInfo(const std::list<std::pair<int, std::string>> &infos, GeneralOperationCallback *callback);

        extern int modifyUserSetting(int scope, const std::string &key, const std::string &value, GeneralOperationCallback *callback);

        extern void searchUser(const std::string &keyword, int searchType, int page, SearchUserCallback *callback);
        extern void searchUser(const std::string &domainId, const std::string &keyword, int searchType, int page, SearchUserCallback *callback);
        extern void searchUser(const std::string &domainId, const std::string &keyword, int searchType, int userType, int page, SearchUserCallback *callback);
        extern void sendFriendRequest(const std::string &userId, const std::string &reason, const std::string &extra, GeneralOperationCallback *callback);

        extern void loadFriendRequestFromRemote(int64_t head = 0);
        extern void loadFriendFromRemote(int64_t head = 0);
        extern void handleFriendRequest(const std::string &userId, bool accept, const std::string &extra, GeneralOperationCallback *callback);
        extern void deleteFriend(const std::string &userId, GeneralOperationCallback *callback);
        extern void setFriendAlias(const std::string &userId, const std::string &alias, GeneralOperationCallback *callback);

        extern void blackListRequest(const std::string &userId, bool blacked, GeneralOperationCallback *callback);
    
    
        extern void loadRemoteDomains(LoadRemoteDomainsCallback *callback);
    
        extern void watchOnlineState(int type, const std::list<std::string> &targets, int duration, WatchOnlineStateCallback *callback);
        extern void unwatchOnlineState(int type, const std::list<std::string> &targets, GeneralOperationCallback *callback);
    
        extern void requireLock(const std::string &lockId, int64_t duration, GeneralOperationCallback *callback);
    
        extern void releaseLock(const std::string &lockId, GeneralOperationCallback *callback);
    
        extern void setUserAgent(const std::string &userAgent);
        extern void addHttpHeader(const std::string &header, const std::string &value);
    
        extern void sendMomentsRequest(const std::string &path, const std::string &data, GeneralStringCallback *callback);

        extern void (*createGroup)(const std::string &groupId, const std::string &groupName, const std::string &groupPortrait, int groupType, const std::string &groupExtra, const std::list<std::string> &groupMembers, const std::string &memberExtra, const std::list<int> &notifyLines, TMessageContent &content, CreateGroupCallback *callback);

        extern void (*addMembers)(const std::string &groupId, const std::list<std::string> &members, const std::string &extra, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void (*kickoffMembers)(const std::string &groupId, const std::list<std::string> &members, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void quitGroup(const std::string &groupId, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback, bool keepMsg = false);

        extern void (*dismissGroup)(const std::string &groupId, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void (*getGroupInfo)(const std::list<std::pair<std::string, int64_t>> &groupIdList, GetGroupInfoCallback *callback);

        extern void (*modifyGroupInfo)(const std::string &groupId, int type, const std::string &newValue, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void (*modifyGroupAlias)(const std::string &groupId, const std::string &newAlias, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
    
        extern void modifyGroupMemberAlias(const std::string &groupId, const std::string &memberId, const std::string &newAlias, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
    
        extern void modifyGroupMemberExtra(const std::string &groupId, const std::string &memberId, const std::string &extra, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void (*getGroupMembers)(const std::string &groupId, int64_t updateDt, int64_t dtSum);

        extern void (*transferGroup)(const std::string &groupId, const std::string &newOwner, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void SetGroupManager(const std::string &groupId, const std::list<std::string> &userIds, int setOrDelete, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);
    
        extern void MuteOrAllowGroupMember(const std::string &groupId, const std::list<std::string> &userIds, int setOrDelete, bool isAllow, const std::list<int> &notifyLines, TMessageContent &content, GeneralOperationCallback *callback);

        extern void (*getUserInfo)(const std::list<std::pair<std::string, int64_t>> &userReqList, GetUserInfoCallback *callback);

        extern void getMyGroups(GeneralStringListCallback *callback);
        extern void getCommonGroups(const std::string &userId, GeneralStringListCallback *callback);
    
        extern void reloadGroupInfoFromRemote(const std::list<std::pair<std::string, int64_t>> &groupReqList);
        extern void reloadOneGroupInfo(const std::string &groupId, int64_t timestamp, GetOneGroupInfoCallback *callback);
        extern void reloadUserInfoFromRemote(const std::list<std::pair<std::string, int64_t>> &userReqList);
        extern void reloadPartUserInfoFromRemote(const std::list<std::pair<std::string, int64_t>> &userReqList, const std::string &groupId, const std::list<TUserInfo> &existUserInfos, GetUserInfoCallback *callback);
        extern void reloadOneUserInfo(const std::string &userId, const std::string &groupId, int64_t timestamp, GetOneUserInfoCallback *callback);
        extern void reloadGroupMembersFromRemote(const std::string &groupId, int64_t updateDt, int64_t dtSum);
        extern void reloadGroupMembersEx(const std::string &groupId, int64_t updateDt, int64_t dtSum, GetGroupMembersCallback *callback);
        extern void clearFriendRequestUnread(int64_t maxDt);
        extern std::string getJoinedChatroom();
        extern void joinChatroom(const std::string &chatroomId, GeneralOperationCallback *callback);
        extern void quitChatroom(const std::string &chatroomId, GeneralOperationCallback *callback);
        extern void getChatroomInfo(const std::string &chatroomId, int64_t lastUpdateDt, GetChatroomInfoCallback *callback);
        extern void getChatroomMemberInfo(const std::string &chatroomId, int maxCount, GetChatroomMemberInfoCallback *callback);

        extern void syncConversationReadDt(int conversatinType, const std::string &target, int ine, int64_t readedDt, const std::list<std::string> &senders = std::list<std::string>(), long syncId = -1);

        extern void setGroupRemark(const std::string &groupId, const std::string &remark, GeneralOperationCallback *callback);
        extern std::string getGroupRemark(const std::string &groupId);

        extern void createChannel(const std::string &channelId, const std::string &channelName, const std::string &channelPortrait, int status, const std::string &desc, const std::string &extra, const std::string &secret, const std::string &cb, CreateChannelCallback *callback);

        extern void modifyChannelInfo(const std::string &channelId, int type, const std::string &newValue, GeneralOperationCallback *callback);

        extern void transferChannel(const std::string &channelId, const std::string &newOwner, GeneralOperationCallback *callback);

        extern void destoryChannel(const std::string &channelId, GeneralOperationCallback *callback);


        extern void searchChannel(const std::string &keyword, bool puzzy, SearchChannelCallback *callback);

        extern void listenChannel(const std::string &channelId, bool listen, GeneralOperationCallback *callback);
    
        extern void getListenedChannels(GeneralStringListCallback *callback);
    
        extern void createSecretChat(const std::string &userId, CreateSecretChatCallback *callback);
        extern void destroySecretChat(const std::string &targetId, GeneralOperationCallback *callback);
        extern std::string decodeSecretChatMediaData(const std::string &targetId, const unsigned char *indata, int insize);
        extern std::string encodeSecretChatMediaData(const std::string &targetId, const unsigned char *indata, int insize);
    
        extern std::string GetImageThumbPara();

        extern void GetAuthCode(const std::string &applicationId, int type, const std::string &host, GeneralStringCallback *callback);
    
        extern void ApplicationConfig(const std::string &appId, int appType, int64_t timestamp, const std::string &nonceStr, const std::string &signature, GeneralOperationCallback *callback);

        extern void KickoffPCClient(const std::string &pcClientId, GeneralOperationCallback *callback);

    
        extern void setProxyInfo(const std::string &host, const std::string &ip, int port, const std::string &username, const std::string &password);
        extern bool IsCommercialServer();
        extern bool IsReceiptEnabled();
        extern bool IsGroupReceiptEnabled();
        extern bool HasMediaPresignedUrl();
        extern bool HasMediaBackupUrl();
        extern bool IsGlobalDisableSyncDraft();
        extern bool IsEnableUserOnlineState();
        extern bool IsEnableSecretChat();
        extern bool ForcePresignedUrlUpload();
        extern bool IsEnableMesh();
        extern bool IsEnableRemoteControl();
    
        extern void sendConferenceRequest(int64_t sessionId, const std::string &roomId, const std::string &request, bool advance, const std::string &data, GeneralStringCallback *callback);
    
        extern bool filesystem_exists(const std::string &path);
		extern bool filesystem_create_directories(const std::string &path);
        extern bool filesystem_copy_file(const std::string &source, const std::string &dest, bool overwrite);
		extern bool filesystem_copy_files(const std::string &source, const std::string &dest);
        extern bool filesystem_remove(const std::string &path);
		extern void filesystem_copy_directory(const std::string &strSourceDir, const std::string &strDestDir);
        extern void filesystem_files_indirectory(const std::string &strSourceDir, std::list<std::string> &files);
        extern bool GetFeeds(std::string data, std::list<TMomentsFeed> &feeds, bool gzip);
        extern bool GetFeed(std::string data, TMomentsFeed &feed, bool gzip);
        extern bool GetComments(std::string data, std::list<TMomentsComment> &feeds, bool gzip);
        extern const std::string getProtoRevision();
        extern int64_t getAvailableSize();
        extern void SetHeartBeatInterval(int interval);
		
    }
}




#endif /* proto_h */
