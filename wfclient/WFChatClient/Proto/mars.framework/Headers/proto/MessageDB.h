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
        class MessageDB {
            
        private:
            MessageDB();
            virtual ~MessageDB();
            
        public:
            static MessageDB* Instance();
            long InsertMessage(TMessage &msg);
            
            void RegisterMessageFlag(int type, int flag);
            bool UpdateMessageContent(long messageId, TMessageContent &msgConstnet);
            bool DeleteMessage(long messageId);
            
            bool UpdateMessageContentByUid(int64_t messageUid, TMessageContent &msgConstnet);
            bool DeleteMessageByUid(int64_t messageUid);
            
            bool UpdateMessageTimeline(int64_t timeline);
            int64_t GetMessageTimeline();
            int64_t GetSettingVersion();
            bool UpdateUserSettings(const std::list<TUserSettingEntry> &settings);
            std::string GetUserSetting(int scope, const std::string &key);
            std::map<std::string, std::string> GetUserSettings(int scope);
            
            bool updateConversationTimestamp(int conversationType, const std::string &target, int line, int64_t timestamp);
            bool updateConversationIsTop(int conversationType, const std::string &target, int line, bool istop);
            bool updateConversationIsSilent(int conversationType, const std::string &target, int line, bool issilent);
            bool updateConversationDraft(int conversationType, const std::string &target, int line, const std::string &draft);
            
            TConversation GetConversation(int conversationType, const std::string &target, int line);
            std::list<TConversation> GetConversationList(const std::list<int> &conversationTypes, const std::list<int> &lines);
            
            bool RemoveConversation(int conversationType, const std::string &target, int line, bool clearMessage = false);
            
            bool ClearMessages(int conversationType, const std::string &target, int line);
            
            std::list<TMessage> GetMessages(int conversationType, const std::string &target, int line, const std::list<int> &contentTypes, bool desc, int count, long startPoint, const std::string &withUser);
          
            TMessage GetMessageById(long messageId);
            TMessage GetMessageByUid(long long messageUid);
          
            
          
            bool updateMessageStatus(long messageId, MessageStatus status);
            bool updateMessageUidAndTimestamp(long messageId, int64_t messageUid, int64_t sendTime);
            bool updateMessageRemoteMediaUrl(long messageId, const std::string &remoteMediaUrl);
            bool updateMessageLocalMediaPath(long messageId, const std::string &localMediaPath);
            
            TUnreadCount GetUnreadCount(int conversationType, const std::string &target, int line);
            
            TUnreadCount GetUnreadCount(const std::list<int> &conversationTypes, const std::list<int> lines);
            bool ClearUnreadStatus(int conversationType, const std::string &target, int line);
            bool ClearAllUnreadStatus();
            
            bool FailSendingMessages();
            
            int64_t getConversationReadMaxDt(int conversationType, const std::string &target, int line);
            bool updateConversationRead(int conversationType, const std::string &target, int line, int64_t dt);
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
            
            TUserInfo getUserInfo(const std::string &userId, const std::string &groupId, bool refresh);
            std::list<TUserInfo> getUserInfos(const std::list<std::string> &userIds, const std::string &groupId);
            long InsertUserInfoOrReplace(const TUserInfo &userInfo);
            long UpdateMyInfo(const std::list<std::pair<int, std::string>> &infos);
            
            bool isMyFriend(const std::string &userId);
            bool isBlackListed(const std::string &userId);
            std::list<std::string> getMyFriendList(bool refresh);
            std::list<std::string> getBlackList(bool refresh);
            
            std::string GetFriendAlias(const std::string &friendId);
            
            int64_t getFriendRequestHead();
            int64_t getFriendHead();
            
            long InsertFriendRequestOrReplace(const TFriendRequest &friendRequest);
            std::list<TFriendRequest> getFriendRequest(int direction);
            
            long InsertFriendOrReplace(const std::string &friendUid, int state, int64_t timestamp, const std::string &alias);
            
            int unreadFriendRequest();
            void clearUnreadFriendRequestStatus();
            int getMessageFlag(int type);
            int64_t getUnreadFriendRequestMaxDt();
            
            
            TChannelInfo GetChannelInfo(const std::string &channelId, bool refresh);
            long InsertOrUpdateChannelInfo(const TChannelInfo &channelInfo);
        private:
            bool GetConversationSilent(int conversationType, const std::string &target, int line);
            static MessageDB* instance_;
        };
        
    }
}


#endif /* MessageDB_hpp */
