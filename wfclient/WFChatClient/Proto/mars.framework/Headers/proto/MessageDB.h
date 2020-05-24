//
//  MessageDB.h
//  stn
//
//  Created by WF Chat on 2017/8/26.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef MessageDB_hpp
#define MessageDB_hpp

#include "mars/proto/proto.h"
#include <map>
namespace mars {
    namespace stn {
        class UpdateConversationData;
        class LoadRemoteMessagesPublishCallback;
        class SyncReadEntry;
        class MessageDB {
            
        private:
            MessageDB();
            virtual ~MessageDB();
            
        public:
            static MessageDB* Instance();
            long InsertMessage(TMessage &msg, bool updateConversationTime = true, std::list<UpdateConversationData*> *delayUpdateDatas = NULL);
            
            void RegisterMessageFlag(int type, int flag);
            bool UpdateMessageContent(long messageId, TMessageContent &msgConstnet);
            bool DeleteMessage(long messageId);
            
            bool UpdateMessageContentByUid(int64_t messageUid, TMessageContent &msgConstnet);
            bool DeleteMessageByUid(int64_t messageUid);
            
            bool UpdateMessageTimeline(int64_t timeline, const std::string &node);
            bool UpdateRecvAndReadTimeline(int64_t timeline, bool isRead);
            int64_t GetMessageTimeline(std::string &node, int64_t &recvHead, int64_t &readHead);
            int64_t GetSettingVersion();
            bool UpdateUserSettings(std::list<TUserSettingEntry> &settings);
            std::string GetUserSetting(int scope, const std::string &key);
            std::map<std::string, std::string> GetUserSettings(int scope);
            
            bool updateConversationTimestamp(int conversationType, const std::string &target, int line, int64_t timestamp, long messageId, bool unread, bool mentionedMe, bool mentionAll, bool isRecall);
            bool updateConversationTimestamp(int conversationType, const std::string &target, int line, int64_t timestamp);
            bool updateConversationIsTop(int conversationType, const std::string &target, int line, bool istop);
            bool updateConversationIsSilent(int conversationType, const std::string &target, int line, bool issilent);
            bool updateConversationDraft(int conversationType, const std::string &target, int line, const std::string &draft);
            
            TConversation GetConversation(int conversationType, const std::string &target, int line);
            std::list<TConversation> GetConversationList(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            bool RemoveConversation(int conversationType, const std::string &target, int line, bool clearMessage = false);
            
            bool ClearMessages(int conversationType, const std::string &target, int line);
            bool ClearMessages(int conversationType, const std::string &target, int line, int64_t before);
            
            std::list<TMessage> GetMessages(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessages(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessages(const std::list<int> &conversationTypes, const std::list<int> &lines, const int messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser);

          
            TMessage GetMessageById(long messageId);
            TMessage GetMessageByUid(long long messageUid);
          
            
          
            bool updateMessageStatus(long messageId, MessageStatus status);
            bool updateMessageUidAndTimestamp(long messageId, int64_t messageUid, int64_t sendTime);
            bool updateMessageRemoteMediaUrl(long messageId, const std::string &remoteMediaUrl);
            bool updateMessageLocalMediaPath(long messageId, const std::string &localMediaPath);
            
            int GetMsgTotalCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(const std::list<int> &conversationTypes, const std::list<int> lines);
            std::list<std::string> GetUnreadMsgSender(int conversationType, const std::string &target, int line);
            bool ClearUnreadStatus(int conversationType, const std::string &target, int line);
            bool ClearUnreadStatus(const std::list<int> &conversationTypes, const std::list<int> lines);
            bool ClearAllUnreadStatus();
            
            bool FailSendingMessages();
            
            int64_t getConversationReadMaxDt(int conversationType, const std::string &target, int line);
            bool updateConversationRead(int conversationType, const std::string &target, int line, int64_t dt);
            bool updateConversationReaded(int conversationType, const std::string &target, int line, int64_t dt);
            std::list<TMessage> SearchMessages(int conversationType, const std::string &target, int line, const std::string &keyword, int limit);
            
            std::list<TConversationSearchresult> SearchConversations(const std::list<int> &conversationTypes, const std::list<int> lines, const std::string &keyword, int limit);
            
            std::list<TUserInfo> SearchFriends(const std::string &keyword, int limit);
            std::list<TGroupSearchResult> SearchGroups(const std::string &keyword, int limit);
            
            TGroupInfo GetGroupInfo(const std::string &groupId, bool refresh);
            long InsertGroupInfo(const TGroupInfo &groupInfo);
            bool UpdateGroupInfo(const std::string &groupId, int type, const std::string &newValue);
            std::list<TGroupMember> GetGroupMembers(const std::string &groupId, bool refresh);
            TGroupMember GetGroupMember(const std::string &groupId, const std::string &memberId);
            bool RemoveGroupAndMember(const std::string &groupId);
            void UpdateGroupMember(const std::list<TGroupMember> &retList);
            void RemoveGroupMembers(const std::string &groupId, const std::list<std::string> &members);
            void AddGroupMembers(const std::string &groupId, const std::list<std::string> &members);
            int UpdateGroupManager(const std::string &groupId, const std::list<std::string> &members, int setOrDelete);
            int UpdateGroupMemberMute(const std::string &groupId, const std::list<std::string> &members, int setOrDelete);
            
            TUserInfo getUserInfo(const std::string &userId, const std::string &groupId, bool refresh);
            std::list<TUserInfo> getUserInfos(const std::list<std::string> &userIds, const std::string &groupId);
            long InsertUserInfoOrReplace(const TUserInfo &userInfo);
            long UpdateMyInfo(const std::list<std::pair<int, std::string>> &infos);
            
            bool isMyFriend(const std::string &userId);
            bool isBlackListed(const std::string &userId);
            std::list<std::string> getMyFriendList(bool refresh);
            std::list<std::string> getBlackList(bool refresh);
            
            std::string GetFriendAlias(const std::string &friendId);
            std::string GetFriendExtra(const std::string &friendId);
            
            int64_t getFriendRequestHead();
            int64_t getFriendHead();
            
            long InsertFriendRequestOrReplace(const TFriendRequest &friendRequest);
            std::list<TFriendRequest> getFriendRequest(int direction);
            
            long InsertFriendOrReplace(const std::string &friendUid, int state, int blacked, int64_t timestamp, const std::string &alias, const std::string &extra);
            long UpdateFriendAlias(const std::string &friendUid, const std::string &alias);
            long UpdateBlacklist(const std::string &friendUid, int blacked);
            
            bool DeleteFriend(const std::string &friendUid);
            
            int unreadFriendRequest();
            void clearUnreadFriendRequestStatus();
            int getMessageFlag(int type);
            int64_t getUnreadFriendRequestMaxDt();
            bool updateFriendRequestStatus(const std::string &friendUid, int status);
            
            
            TChannelInfo GetChannelInfo(const std::string &channelId, bool refresh);
            long InsertOrUpdateChannelInfo(const TChannelInfo &channelInfo);
            
            bool BeginTransaction();
            void CommitTransaction();
            friend class LoadRemoteMessagesPublishCallback;
            std::list<TConversation> GetConversationListOld(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            long InsertRead(const TReadEntry &entry);
            long InsertDelivery(const TDeliveryEntry &entry);
            
            std::map<std::string, int64_t> GetConversationRead(int conversationType, const std::string &target, int line);
            std::map<std::string, int64_t> GetDelivery(int conversationType, const std::string &target);
            int64_t GetDelivery(std::string userId);
            
            long saveConversationSync(int conversatinType, const std::string &target, int line, int64_t readedDt, const std::list<std::string> &senders);
            SyncReadEntry loadConversationSync();
            bool deleteConvSync(long _id);
        private:
            bool GetConversationSilent(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(int conversationType, const std::string &target, int line, bool clearLastMessageId = false);
            bool updateConversationUnread(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(const std::list<int> &conversationTypes, const std::list<int> lines, bool clearLastMessageId = false);
            bool updateConversationLastMessage(int conversationType, const std::string &target, int line, bool forceUpdate = false);
            static MessageDB* instance_;
        };
    
        class UpdateConversationData {
        public:
            UpdateConversationData() : conversationType(0), target(""), line(0), timestamp(0), lastMessageId(0), unreadCount(false), unreadMention(false), unreadMentionAll(false), isRecall(false) {}
            virtual ~UpdateConversationData() {}
        public:
            int conversationType;
            std::string target;
            int line;
            int64_t timestamp;
            long lastMessageId;
            bool unreadCount;
            bool unreadMention;
            bool unreadMentionAll;
            bool isRecall;
        };
    }
}


#endif /* MessageDB_hpp */
