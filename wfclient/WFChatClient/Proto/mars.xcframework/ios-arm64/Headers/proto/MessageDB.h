//
//  MessageDB.h
//  stn
//
//  Created by WF Chat on 2017/8/26.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#ifndef MessageDB_hpp
#define MessageDB_hpp

#include "proto/proto.h"
#include <map>
#include <set>
namespace mars {
    namespace stn {
        class UpdateConversationData;
        class LoadRemoteMessagesPublishCallback;
        class SyncReadEntry;
        class RecyclableStatement;
        class DB2;
        class SyncBurnReadedEntry;
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
            bool BatchDeleteMessage(std::list<int64_t> messageUids);
            
            bool UpdateMessageTimeline(int64_t timeline, const std::string &node);
            bool UpdateRecvAndReadTimeline(int64_t timeline, bool isRead);
            bool UpdateGroupConvTimeline(int64_t timeline);
            bool UpdateNoFtsTimeline(bool noFts);
            bool UpdateFriendRequestTimeline(int64_t timeline);
            int64_t GetMessageTimeline(std::string &node, int64_t &recvHead, int64_t &readHead, int64_t &groupHead, bool &noFts, int64_t &frHead);
            int64_t GetSettingVersion();
            bool UpdateUserSettings(std::list<TUserSettingEntry> &settings);
            std::string GetUserSetting(int scope, const std::string &key);
            std::map<std::string, std::string> GetUserSettings(int scope);
            
            bool updateConversationTimestamp(int conversationType, const std::string &target, int line, int64_t timestamp, long messageId, bool unread, bool mentionedMe, bool mentionAll, bool isRecall);
            bool updateConversationTimestamp(int conversationType, const std::string &target, int line, int64_t timestamp);
            bool updateConversationIsTop(int conversationType, const std::string &target, int line, int istop);
            bool updateConversationIsSilent(int conversationType, const std::string &target, int line, bool issilent, bool createIfNotExist = true);
            bool updateConversationDraft(int conversationType, const std::string &target, int line, const std::string &draft, bool syncRemote = true);
            
            std::string getConversationDraft(int conversationType, const std::string &target, int line);
            
            TConversation GetConversation(int conversationType, const std::string &target, int line);
            bool isExistConversation(int conversationType, const std::string &target, int line);
            std::list<TConversation> GetConversationList(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            bool RemoveConversation(int conversationType, const std::string &target, int line, bool clearMessage = false, bool sync = true);
            bool RemoveGroupMessageBefore(const std::string &groupId, int64_t beforeTime);
            bool ClearMessages(int conversationType, const std::string &target, int line);
            bool ClearMessages(int conversationType, const std::string &target, int line, int64_t before);
            bool ClearMessagesKeepLatest(int conversationType, const std::string &target, int line, int count);
            bool ClearUserMessages(const std::string &userId, int64_t start, int64_t end);
            bool ClearAllMessages(bool removeConveration);
            bool DeleteExpiredMessages();
            
            
            bool InsertMessageExpire(long messageId, int conversationType, const std::string &target, int line, int64_t expireTime);
            
            long GetConversationFirstUnreadMessageId(int conversationType, const std::string &target, int line);
            std::list<TMessage> GetMessages(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByMessageStatus(int conversationType, const std::string &target, int line, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMentionedMessages(int conversationType, const std::string &target, int line, bool desc, int count, int64_t startPoint);
            
            std::list<TMessage> GetMessages(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByMessageStatus(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &messageStatus, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> GetMessagesByTimes(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startTimestamp, const std::string &withUser);
            
            std::list<TMessage> GetUserMessages(const std::string &user, int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint);
            std::list<TMessage> GetUserMessages(const std::string &user, const std::list<int> &conversationTypes, const std::list<int> &lines, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint);
            
            std::list<std::pair<std::string, int>> GetMessageCountByDay(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, int64_t startTime, int64_t endTime);

          
            TMessage GetMessageById(long messageId);
            TMessage GetMessageByUid(long long messageUid);
            int64_t GetNewestMessageTimestamp();
          
            
          
            bool updateMessageStatus(long messageId, MessageStatus status);
            bool updateMessageUidAndTimestamp(long messageId, int64_t messageUid, int64_t sendTime, bool *duplicated);
            bool updateMessageRemoteMediaUrl(long messageId, const std::string &remoteMediaUrl);
            bool updateMessageLocalMediaPath(long messageId, const std::string &localMediaPath);
            
            bool setMessageLocalExtra(long messageId, const std::string &extra);
            
            int GetMsgTotalCount(int conversationType, const std::string &target, int line);
            int GetConversationMessageCount(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            TUnreadCount GetUnreadCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(const std::list<int> &conversationTypes, const std::list<int> lines);
            std::list<std::string> GetUnreadMsgSender(int conversationType, const std::string &target, int line, int64_t before = 0);
            bool ClearUnreadStatus(int conversationType, const std::string &target, int line);
            bool ClearUnreadStatus(const std::list<int> &conversationTypes, const std::list<int> lines);
            bool ClearUnreadStatus(int messageId);
            bool ClearUnreadStatusBeforeMessage(int messageId, int conversationType, const std::string &target, int line);
            bool ClearUnreadStatusBeforeTime(int conversationType, const std::string &target, int line, int64_t timestamp, bool sync);
            bool ClearAllUnreadStatus();
            int64_t SetLastReceivedMessageUnRead(int conversationType, const std::string &target, int line, int64_t lastMsgUid, int64_t timestamp);
            int64_t getLastReceivedMessageUid(int conversationType, const std::string &target, int line);
            
            bool FailSendingMessages();
            
            int64_t getConversationReadMaxDt(int conversationType, const std::string &target, int line);
            bool updateConversationRead(int conversationType, const std::string &target, int line, int64_t dt);
            bool updateLineRead(int conversationType, int line, int64_t dt);
            bool updateConversationReaded(int conversationType, const std::string &target, int line, int64_t dt);
            std::list<TMessage> SearchMessages(int conversationType, const std::string &target, int line, const std::string &keyword, int limit, const std::string &withUser);
            std::list<TMessage> SearchMessages(int conversationType, const std::string &target, int line, const std::string &keyword, bool desc, int limit, int offset, const std::string &withUser);
            std::list<TMessage> SearchMessagesByTypes(int conversationType, const std::string &target, int line, const std::string &keyword, const std::list<int> &contentTypes, bool desc, int limit, int offset, const std::string &withUser);
            std::list<TMessage> SearchMessagesByTypesAndTimes(int conversationType, const std::string &target, int line, const std::string &keyword, const std::list<int> &contentTypes, int64_t startTime, int64_t endTime, bool desc, int limit, int offset, const std::string &withUser);
            std::list<TMessage> SearchMessagesEx(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::string &keyword, const std::list<int> &contentTypes, bool desc, int count, int64_t startPoint, const std::string &withUser);
            
            std::list<TMessage> SearchMentionedMessages(int conversationType, const std::string &target, int line, const std::string &keyword, bool desc, int limit, int offset);
            std::list<TMessage> SearchMentionedMessagesEx(const std::list<int> &conversationTypes, const std::list<int> &lines, const std::string &keyword, bool desc, int limit, int offset);
            
            std::list<TConversationSearchresult> SearchConversations(const std::list<int> &conversationTypes, const std::list<int> lines, const std::string &keyword, int limit);
            std::list<TConversationSearchresult> SearchConversationsEx(const std::list<int> &conversationTypes, const std::list<int> lines, const std::string &keyword, int64_t startTime, int64_t endTime, bool desc, int limit, int offset);
            std::list<TConversationSearchresult> SearchConversationsEx2(const std::list<int> &conversationTypes, const std::list<int> lines, const std::string &keyword, const std::list<int> &contentTypes, int64_t startTime, int64_t endTime, bool desc, int limit, int offset, bool onlyMentionedMsg);
            
            std::list<TUserInfo> SearchFriends(const std::string &keyword, int limit);
            std::list<TGroupSearchResult> SearchGroups(const std::string &keyword, int limit);
            
            TGroupInfo GetGroupInfo(const std::string &groupId, bool refresh);
            std::list<TGroupInfo> GetGroupInfos(const std::list<std::string> &groupIds, bool refresh);
            void GetGroupInfo(const std::string &userId, bool refresh, GetOneGroupInfoCallback *callback);
            void BatchRefreshGroupInfo(const std::set<std::string> &groupIds);
            long InsertGroupInfo(const TGroupInfo &groupInfo);
            bool UpdateGroupInfo(const std::string &groupId, int type, const std::string &newValue);
            std::list<TGroupMember> GetGroupMembers(const std::string &groupId, bool refresh);
            TGroupMember GetGroupMember(const std::string &groupId, const std::string &memberId);
            std::list<TGroupMember> GetGroupMembersByType(const std::string &groupId, int type);
            std::list<TGroupMember> GetGroupMembersByCount(const std::string &groupId, int count);
            void GetGroupMembers(const std::string &groupId, bool refresh, GetGroupMembersCallback *callback);
            bool RemoveGroupAndMember(const std::string &groupId, bool keepGroupName = false);
            bool RemoveAllGroupMember(const std::string &groupId, bool removeUserSettings = true);
            void RemoveAllGroupUserSettings(const std::string &groupId);
            void UpdateGroupMember(const std::list<TGroupMember> &retList);
            void RemoveGroupMembers(const std::string &groupId, const std::list<std::string> &members);
            void AddGroupMembers(const std::string &groupId, const std::list<std::string> &members, const std::string &extra, bool isCreate);
            int UpdateGroupManager(const std::string &groupId, const std::list<std::string> &members, int setOrDelete);
            int UpdateGroupMemberMuteOrAllow(const std::string &groupId, const std::list<std::string> &members, int setOrDelete, bool isAllow);
            int UpdateGroupMemberAlias(const std::string &groupId, const std::string &memberId, const std::string &alias);
            int UpdateGroupMemberExtra(const std::string &groupId, const std::string &memberId, const std::string &extra);
            
            TUserInfo getUserInfo(const std::string &userId, const std::string &groupId, bool refresh);
            TUserInfo getLocalUserInfo(const std::string &userId, const std::string &groupId);
            std::list<TUserInfo> getUserInfos(const std::list<std::string> &userIds, const std::string &groupId);
            void GetUserInfo(const std::string &userId, bool refresh, GetOneUserInfoCallback *callback);
            void GetUserInfo(const std::string &userId, const std::string &groupId, bool refresh, GetOneUserInfoCallback *callback);
            std::list<TUserInfo> GetUserInfos(const std::list<std::string> &userIds, const std::string &groupId, std::list<std::string> &needRefreshList);
            void BatchGetUserInfos(const std::list<std::string> &userIds, const std::string &groupId, GetUserInfoCallback *callback);
            
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
            
            std::list<TFriendRequest> getFriendRequestByStatus(int status, int direction);
            int getFriendRequestCountByStatus(int status, int direction);
            
            long InsertFriendOrReplace(const std::string &friendUid, int state, int blacked, int64_t timestamp, const std::string &alias, const std::string &extra);
            long UpdateFriendAlias(const std::string &friendUid, const std::string &alias);
            long UpdateBlacklist(const std::string &friendUid, int blacked);
            
            bool DeleteFriend(const std::string &friendUid);
            
            int unreadFriendRequest();
            bool clearUnreadFriendRequestStatus();
            int getMessageFlag(int type);
            int64_t getUnreadFriendRequestMaxDt();
            bool updateFriendRequestStatus(const std::string &friendUid, int status);
            bool ClearFriendRequest(bool incomming, int64_t beforeTime = 0);
            bool DeleteFriendRequest(const std::string &friendUid, bool incomming);
            
            
            TDomainInfo GetDomainInfo(const std::string &domainId, bool refresh);
            int SaveDomainInfo(const TDomainInfo &domain);
            
            
            TChannelInfo GetChannelInfo(const std::string &channelId, bool refresh);
            long InsertOrUpdateChannelInfo(const TChannelInfo &channelInfo);
            
            bool BeginTransaction();
            bool CommitTransaction();
            bool RollbackTransaction();
            friend class LoadRemoteMessagesPublishCallback;
            std::list<TConversation> GetConversationListOld(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            long InsertRead(const TReadEntry &entry);
            long InsertDelivery(const TDeliveryEntry &entry);
            
            std::map<std::string, int64_t> GetConversationRead(int conversationType, const std::string &target, int line);
            std::map<std::string, int64_t> GetDelivery(int conversationType, const std::string &target);
            int64_t GetSingleDelivery(const std::string &userId);
            std::map<std::string, int64_t> GetGroupDelivery(const std::string &targetId);
            
            long saveConversationSync(int conversatinType, const std::string &target, int line, int64_t readedDt, const std::list<std::string> &senders);
            SyncReadEntry loadConversationSync();
            bool deleteConvSync(long _id);
            bool updateConversationLastMessage(int conversationType, const std::string &target, int line, bool forceUpdate = false);
            
            TSecretChatInfo GetSecretChatInfo(const std::string &targetId);
            bool SetSecretChatBurnTime(const std::string &targetId, int ms);
            
            std::pair<int, int64_t> GetMessageBurnTime(long messageId);
            
            int getSecretChatBurnTime(const std::string &targetId);
            bool createSecretChat(const std::string &targetId, const std::string &userId, const std::string dhx);
            bool acceptSecretChat(const std::string &targetId, const std::string &userId);
            bool establishedSecretChat(const std::string &targetId, const std::string &userId, const std::string dhkey);
            bool cancelSecretChat(const std::string &targetId, const std::string &userId);
            bool removeSecretChat(const std::string &targetId);

            std::string getSecretChatX(const std::string &targetId);
            std::string getSecretChatKey(const std::string &targetId);
            
            bool insertBurnMessageInfo(long messageId, int64_t messageUid, const std::string &targetId, int direction, int burnTime, int media, int64_t messageDt);
            TBurnMessageInfo getBurnMessageInfo(long messageId);
            int64_t burnMessageReaded(const std::string &targetId, int direction, int64_t readDt = 0, int64_t msgDt = 0);
            int64_t getBurnMessageReadTime(const std::string &targetId);
            int64_t burnMessagePlayed(long messageId, int64_t readDt = 0);
            std::list<long> getBurnedMessage(int64_t dt);
            int removeBurnedMessageInfo(int64_t dt);
            int64_t getLastestBurnMessageTime();
            long insertSyncBurnReaded(int type, const std::string &target, int line, int64_t readDt, int64_t value);
            bool deleteSyncBurnReaded(long sid);
            SyncBurnReadedEntry getSyncBurnReadedEntry();
            void deleteUserMessages(const std::list<std::string> &userIds);
            void _OnCheckBurn();
            void _OnCheckReroute();
            int64_t getConversationReadFromUserSetting(int type, const std::string &target, int line);
            friend DB2;
        private:
            std::string getLoadMessageSql(DB2 *db, const std::string &where, const std::string &orderBy, int count);
            int64_t GetGroupMembersMaxDt(const std::string &groupId);
            bool GetConversationSilent(int conversationType, const std::string &target, int line);
            bool isConversationExist(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(int conversationType, const std::string &target, int line, bool clearLastMessageId = false);
            bool updateConversationUnread(int conversationType, const std::string &target, int line);
            int64_t maxConversationMessageTime(int conversationType, const std::string &target, int line);
            bool clearConversationUnread(const std::list<int> &conversationTypes, const std::list<int> &lines, bool clearLastMessageId = false);
            bool clearAllConversationUnread(bool clearLastMessageId = false);
            void getMsgFromStateMent(DB2 *db, RecyclableStatement &statementHandle, TMessage &msg);
            void startBurnMessageCheck();
            void stopBurnMessageCheck();
            std::list<TConversation> getUserConversations(const std::string &user, int64_t start, int64_t end);
            void removeUserSingleConversations(const std::string &userId);
            void removeUserSingleMessages(const std::string &userId);
            static MessageDB* instance_;
        };
    
        class UpdateConversationData {
        public:
            UpdateConversationData() : conversationType(0), target(""), line(0), timestamp(0), lastMessageId(0), unreadCount(false), unreadMention(false), unreadMentionAll(false), isRecallOrDelete(false) {}
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
            bool isRecallOrDelete;
        };
    }
}


#endif /* MessageDB_hpp */
