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
#include <set>
namespace mars {
    namespace stn {
        class UpdateConversationData;
        class LoadRemoteMessagesPublishCallback;
        class SyncReadEntry;
        class RecyclableStatement;
        class DB2;
        class MessageDB {
            
        private:
            MessageDB();
            virtual ~MessageDB();
            
        public:
            static MessageDB* Instance();
            long InsertMessage(TMessage &msg, bool updateConversationTime = true, std::list<UpdateConversationData*> *delayUpdateDatas = NULL, int remote_flag = 0);
            
            void RegisterMessageFlag(int type, int flag);
            bool UpdateMessageContent(long messageId, TMessageContent &msgConstnet);
            bool UpdateMessageContentAndTime(long messageId, TMessageContent &msgConstnet, int64_t timestamp);
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
            bool updateConversationIsSilent(int conversationType, const std::string &target, int line, bool issilent, bool createIfNotExist = true);
            bool updateConversationDraft(int conversationType, const std::string &target, int line, const std::string &draft, bool syncRemote = true);
            
            std::string getConversationDraft(int conversationType, const std::string &target, int line);
            
            TConversation GetConversation(int conversationType, const std::string &target, int line);
            std::list<TConversation> GetConversationList(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            bool RemoveConversation(int conversationType, const std::string &target, int line, bool clearMessage = false);
            
            bool ClearMessages(int conversationType, const std::string &target, int line);
            bool ClearMessages(int conversationType, const std::string &target, int line, int64_t before);
            
            long GetConversationFirstUnreadMessageId(int conversationType, const std::string &target, int line);
            std::list<TMessage> GetMessages(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByMessageStatus(int conversationType, const std::string &target, int line, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessages(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByMessageStatus(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByTimes(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startTimestamp, const std::string &withUser);
            
            std::list<TMessage> GetUserMessages(const std::string &user, int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint);
            std::list<TMessage> GetUserMessages(const std::string &user, const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint);

          
            TMessage GetMessageById(long messageId);
            TMessage GetMessageByUid(long long messageUid);
          
            
          
            bool updateMessageStatus(long messageId, MessageStatus status);
            bool updateMessageUidAndTimestamp(long messageId, int64_t messageUid, int64_t sendTime);
            bool updateMessageRemoteMediaUrl(long messageId, const std::string &remoteMediaUrl);
            bool updateMessageLocalMediaPath(long messageId, const std::string &localMediaPath);
            
            bool setMessageLocalExtra(long messageId, const std::string &extra);
            
            int GetMsgTotalCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(const std::list<int> &conversationTypes, const std::list<int> lines);
            std::list<std::string> GetUnreadMsgSender(int conversationType, const std::string &target, int line);
            bool ClearUnreadStatus(int conversationType, const std::string &target, int line);
            bool ClearUnreadStatus(const std::list<int> &conversationTypes, const std::list<int> lines);
            bool ClearUnreadStatus(int messageId);
            bool ClearAllUnreadStatus();
            
            bool FailSendingMessages();
            
            int64_t getConversationReadMaxDt(int conversationType, const std::string &target, int line);
            bool updateConversationRead(int conversationType, const std::string &target, int line, int64_t dt);
            bool updateLineRead(int conversationType, int line, int64_t dt);
            bool updateConversationReaded(int conversationType, const std::string &target, int line, int64_t dt);
            std::list<TMessage> SearchMessages(int conversationType, const std::string &target, int line, const std::string &keyword, int limit);
            std::list<TMessage> SearchMessages(int conversationType, const std::string &target, int line, const std::string &keyword, bool desc, int limit, int offset);
            std::list<TMessage> SearchMessagesEx(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::string &keyword, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint);
            
            std::list<TConversationSearchresult> SearchConversations(const std::list<int> &conversationTypes, const std::list<int> lines, const std::string &keyword, int limit);
            
            std::list<TUserInfo> SearchFriends(const std::string &keyword, int limit);
            std::list<TGroupSearchResult> SearchGroups(const std::string &keyword, int limit);
            
            TGroupInfo GetGroupInfo(const std::string &groupId, bool refresh);
            void GetGroupInfo(const std::string &userId, bool refresh, GetOneGroupInfoCallback *callback);
            void BatchRefreshGroupInfo(const std::set<std::string> &groupIds);
            long InsertGroupInfo(const TGroupInfo &groupInfo);
            bool UpdateGroupInfo(const std::string &groupId, int type, const std::string &newValue);
            std::list<TGroupMember> GetGroupMembers(const std::string &groupId, bool refresh);
            TGroupMember GetGroupMember(const std::string &groupId, const std::string &memberId);
            std::list<TGroupMember> GetGroupMembersByType(const std::string &groupId, int type);
            void GetGroupMembers(const std::string &groupId, bool refresh, GetGroupMembersCallback *callback);
            bool RemoveGroupAndMember(const std::string &groupId);
            bool RemoveAllGroupMember(const std::string &groupId);
            void UpdateGroupMember(const std::list<TGroupMember> &retList);
            void RemoveGroupMembers(const std::string &groupId, const std::list<std::string> &members);
            void AddGroupMembers(const std::string &groupId, const std::list<std::string> &members, const std::string &extra);
            int UpdateGroupManager(const std::string &groupId, const std::list<std::string> &members, int setOrDelete);
            int UpdateGroupMemberMuteOrAllow(const std::string &groupId, const std::list<std::string> &members, int setOrDelete, bool isAllow);
            int UpdateGroupMemberAlias(const std::string &groupId, const std::string &memberId, const std::string &alias);
            int UpdateGroupMemberExtra(const std::string &groupId, const std::string &memberId, const std::string &extra);
            
            TUserInfo getUserInfo(const std::string &userId, const std::string &groupId, bool refresh);
            std::list<TUserInfo> getUserInfos(const std::list<std::string> &userIds, const std::string &groupId);
            void GetUserInfo(const std::string &userId, bool refresh, GetOneUserInfoCallback *callback);
            
            long InsertUserInfoOrReplace(const TUserInfo &userInfo);
            long UpdateMyInfo(const std::list<std::pair<int, std::string>> &infos);
            
            bool isMyFriend(const std::string &userId);
            bool isBlackListed(const std::string &userId);
            std::list<std::string> getMyFriendList(bool refresh);
            std::list<TFriend> getFriendList(bool refresh);
            std::list<std::string> getBlackList(bool refresh);
            
            std::string GetFriendAlias(const std::string &friendId);
            std::string GetFriendExtra(const std::string &friendId);
            
            int64_t getFriendRequestHead();
            int64_t getFriendHead();
            
            long InsertFriendRequestOrReplace(const TFriendRequest &friendRequest);
            std::list<TFriendRequest> getFriendRequest(int direction);
            TFriendRequest getFriendRequest(const std::string &userId, int direction);
            
            long InsertFriendOrReplace(const std::string &friendUid, int state, int blacked, int64_t timestamp, const std::string &alias, const std::string &extra);
            long UpdateFriendAlias(const std::string &friendUid, const std::string &alias);
            long UpdateBlacklist(const std::string &friendUid, int blacked);
            
            bool DeleteFriend(const std::string &friendUid);
            
            int unreadFriendRequest();
            bool clearUnreadFriendRequestStatus();
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
            int64_t GetGroupMembersMaxDt(const std::string &groupId);
            bool GetConversationSilent(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(int conversationType, const std::string &target, int line, bool clearLastMessageId = false);
            bool updateConversationUnread(int conversationType, const std::string &target, int line);
            int64_t maxConversationMessageTime(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(const std::list<int> &conversationTypes, const std::list<int> &lines, bool clearLastMessageId = false);
            bool clearAllConversationUnread(bool clearLastMessageId = false);
            bool updateConversationLastMessage(int conversationType, const std::string &target, int line, bool forceUpdate = false);
            void getMsgFromStateMent(DB2 *db, RecyclableStatement &statementHandle, TMessage &msg);
            
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
