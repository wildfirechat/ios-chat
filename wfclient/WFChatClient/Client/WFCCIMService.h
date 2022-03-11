//
//  WFCCIMService.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WFCCMessage.h"
#import "WFCCGroupInfo.h"
#import "WFCCConversationInfo.h"
#import "WFCCUserInfo.h"
#import "WFCCFriendRequest.h"
#import "WFCCConversationSearchInfo.h"
#import "WFCCGroupMember.h"
#import "WFCCGroupSearchInfo.h"
#import "WFCCChatroomInfo.h"
#import "WFCCChatroomMemberInfo.h"
#import "WFCCUnreadCount.h"
#import "WFCCChannelInfo.h"
#import "WFCCPCOnlineInfo.h"
#import "WFCCFileRecord.h"
#import "WFCCFriend.h"

#pragma mark - 频道通知定义
//发送消息状态通知
extern NSString *kSendingMessageStatusUpdated;
extern NSString *kUploadMediaMessageProgresse;
extern NSString *kConnectionStatusChanged;
extern NSString *kReceiveMessages;
extern NSString *kRecallMessages;
extern NSString *kDeleteMessages;
extern NSString *kMessageDelivered;
extern NSString *kMessageReaded;
extern NSString *kMessageUpdated;

#pragma mark - 枚举值定义
/**
 修改个人信息的内容

 - Modify_DisplayName: 修改显示名
 - Modify_Portrait: 修改头像
 - Modify_Gender: 修改性别
 - Modify_Mobile: 修改手机号
 - Modify_Email: 修改邮箱
 - Modify_Address: 修改地址
 - Modify_Company: 修改公司信息
 - Modify_Social: 修改社交信息
 - Modify_Extra: 修改扩展信息
 */
typedef NS_ENUM(NSInteger, ModifyMyInfoType) {
    Modify_DisplayName = 0,
    Modify_Portrait = 1,
    Modify_Gender = 2,
    Modify_Mobile = 3,
    Modify_Email = 4,
    Modify_Address = 5,
    Modify_Company = 6,
    Modify_Social = 7,
    Modify_Extra = 8
};

typedef NS_ENUM(NSInteger, ModifyGroupInfoType) {
    Modify_Group_Name = 0,
    Modify_Group_Portrait = 1,
    Modify_Group_Extra = 2,
    Modify_Group_Mute = 3,
    Modify_Group_JoinType = 4,
    Modify_Group_PrivateChat = 5,
    Modify_Group_Searchable = 6,
    Modify_Group_History_Message = 7,
    Modify_Group_Max_Member_Count = 8
};


typedef NS_ENUM(NSInteger, ModifyChannelInfoType) {
    Modify_Channel_Name = 0,
    Modify_Channel_Portrait = 1,
    Modify_Channel_Desc = 2,
    Modify_Channel_Extra = 3,
    Modify_Channel_Secret = 4,
    Modify_Channel_Callback = 5
};

/**
 个人设置Scope
 
 @discussion 用户设置，1000以内被系统保留。应用不应该直接使用系统预制的范围。应用可以使用1000以上的值。
 */
typedef NS_ENUM(NSInteger, UserSettingScope) {
    //不能直接使用，调用setConversation:silent:方法会使用到此值。
    UserSettingScope_Conversation_Silent = 1,
    //不能直接使用
    UserSettingScope_Global_Silent = 2,
    
    //不能直接使用，调用setConversation:top:方法会使用到此值。
    UserSettingScope_Conversation_Top = 3,
    //不能直接使用
    UserSettingScope_Hidden_Notification_Detail = 4,
    //不能直接使用
    UserSettingScope_Group_Hide_Nickname = 5,
    //不能直接使用
    UserSettingScope_Favourite_Group = 6,
    
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Conversation_Sync = 7,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_My_Channel = 8,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Listened_Channel = 9,
    
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_PC_Online = 10,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Conversation_Readed = 11,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_WebOnline = 12,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_DisableRecipt = 13,
    //不能直接使用
    UserSettingScope_Favourite_User = 14,
    //不能直接使用
    UserSettingScope_Mute_When_PC_Online = 15,
    //不能直接使用
    UserSettingScope_Lines_Readed = 16,
    //不能直接使用
    UserSettingScope_No_Disturbing = 17,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Conversation_Clear_Message = 18,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Conversation_Draft = 19,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Disable_Sync_Draft = 20,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Voip_Silent = 21,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_PTT_Reserved = 22,
    //不能直接使用，协议栈内会使用此值
    UserSettingScope_Custom_State = 23,
    
    //自定义用户设置，请使用1000以上的key
    UserSettingScope_Custom_Begin = 1000
} ;


/**
 搜索用户类型

 - SearchUserType_General: 模糊搜索diaplayName，精确匹配name和电话
 - SearchUserType_Name_Mobile: 精确匹配name和电话
 - SearchUserType_Name: 精确匹配name
 - SearchUserType_Mobile: 精确匹配电话
 */
typedef NS_ENUM(NSInteger, WFCCSearchUserType) {
    SearchUserType_General,
    SearchUserType_Name_Mobile,
    SearchUserType_Name,
    SearchUserType_Mobile,
} ;

typedef NS_ENUM(NSInteger, WFCCPlatformType) {
    PlatformType_UNSET = 0,
    PlatformType_iOS = 1,
    PlatformType_Android = 2,
    PlatformType_Windows = 3,
    PlatformType_OSX = 4,
    PlatformType_WEB = 5,
    PlatformType_WX = 6,
    PlatformType_Linux = 7,
    PlatformType_iPad = 8,
    //Android pad
    PlatformType_APad = 9
} ;

#pragma mark - 用户源
/*
 * ChatClient内置支持用户信息托管，但对于很多应用来说都已经拥有自己的用户信息。此时可以实现用户源并设置到IMServer中去。这样ChatClient会从源中读取信息，从而ChatUIKit不用修改代码。
 * 对于好友关系，由于页面简单。如果客户有自己的好友关系，建议客户自己修改相关UI。
 * 对于群组建议使用我们的托管。
 */
@protocol WFCCUserSource <NSObject>
- (WFCCUserInfo *)getUserInfo:(NSString *)userId
                      refresh:(BOOL)refresh;

- (WFCCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId refresh:(BOOL)refresh;

- (NSArray<WFCCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId;

- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
              error:(void(^)(int errorCode))errorBlock;

- (void)searchUser:(NSString *)keyword
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock;


-(void)modifyMyInfo:(NSDictionary<NSNumber */*ModifyMyInfoType*/, NSString *> *)values
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;
@end

@protocol ReceiveMessageFilter;
@class WFCCUserOnlineState;
@class WFCCUserCustomState;

#pragma mark - IM服务

/**
 IM服务
 */
@interface WFCCIMService : NSObject <ReceiveMessageFilter>

/**
 IM服务单例

 @return IM服务单例
 */
+ (WFCCIMService*)sharedWFCIMService;


@property(nonatomic, weak)id<WFCCUserSource> userSource;

#pragma mark - 会话相关
/**
 获取会话信息
 
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @return 会话信息
 */
- (NSArray<WFCCConversationInfo *> *)getConversationInfos:(NSArray<NSNumber *> *)conversationTypes
                                                    lines:(NSArray<NSNumber *> *)lines;

/**
 获取会话信息
 
 @param conversation 会话
 @return 会话信息
 */
- (WFCCConversationInfo *)getConversationInfo:(WFCCConversation *)conversation;

/**
 搜索会话
 
 @param keyword 关键词
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @return 会话搜索结果信息
 */
- (NSArray<WFCCConversationSearchInfo *> *)searchConversation:(NSString *)keyword inConversation:(NSArray<NSNumber *> *)conversationTypes lines:(NSArray<NSNumber *> *)lines;

/**
 删除会话
 
 @param conversation 会话
 @param clearMessage 是否删除会话中的消息
 */
- (void)removeConversation:(WFCCConversation *)conversation
              clearMessage:(BOOL)clearMessage;

/**
 设置或取消会话置顶
 
 @param conversation 会话
 @param top 是否置顶
 */
- (void)setConversation:(WFCCConversation *)conversation
                    top:(BOOL)top
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 设置会话免打扰
 
 @param conversation 会话
 @param silent 是否免打扰
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setConversation:(WFCCConversation *)conversation
                 silent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 获取会话是否免打扰状态
 
 @param conversation 会话
 @return 会话是否免打扰
 */
- (BOOL)isConversationSilent:(WFCCConversation *)conversation;
/**
 设置会话草稿
 
 @param conversation 会话
 @param draft 草稿
 */
- (void)setConversation:(WFCCConversation *)conversation
                  draft:(NSString *)draft;

/**
 更新会话的时间
 
 @param conversation 会话
 @param timestamp 时间戳
 */
- (void)setConversation:(WFCCConversation *)conversation
              timestamp:(long long)timestamp;

/**
 获取会话列表第一条未读消息Id
 
 @param conversation 会话
 
 @return 会话中最早一条未读消息Id
 */
- (long)getFirstUnreadMessageId:(WFCCConversation *)conversation;

/**
 清除远端会话消息，仅专业版支持。
 
 @param conversation 会话
 @param successBlock 删除成功
 @param errorBlock 删除失败
 */
- (void)clearRemoteConversationMessage:(WFCCConversation *)conversation
                               success:(void(^)(void))successBlock
                                 error:(void(^)(int error_code))errorBlock;

#pragma mark - 未读数相关
/**
 获取指定类型会话的未读数
 
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @return 未读数
 */
- (WFCCUnreadCount *)getUnreadCount:(NSArray<NSNumber *> *)conversationTypes
                       lines:(NSArray<NSNumber *> *)lines;

/**
 获取某个会话的未读数
 
 @param conversation 会话
 @return 未读数
 */
- (WFCCUnreadCount *)getUnreadCount:(WFCCConversation *)conversation;

/**
 清空会话未读数。
 
 @param conversation 会话
 */
- (void)clearUnreadStatus:(WFCCConversation *)conversation;

/**
清空会话未读数

@param conversationTypes 会话类型
@param lines 线路
*/
- (void)clearUnreadStatus:(NSArray<NSNumber *> *)conversationTypes
                              lines:(NSArray<NSNumber *> *)lines;

/**
 清空所有会话的未读数。仅清理本地消息的未读数，没有同步到其他端，如果多端使用，请避免使用此方法
 */
- (void)clearAllUnreadStatus DEPRECATED_MSG_ATTRIBUTE("use clearUnreadStatus:lines: instead");

/**
 清空消息未读。
 
 @param messageId 消息ID
 @discuss 这个函数只能清除本地的状态，不能同步到服务器或者其他端。建议一般情况下不要用这个接口。
 */
- (void)clearMessageUnreadStatus:(long)messageId;

/**
 设置会话的最后一条接收消息为未读状态。
 
 @param conversation 会话
 @param sync 是否同步到其它客户端
 @return YES设置成功，NO消息不存在或已经存在未读。
 */
- (BOOL)markAsUnRead:(WFCCConversation *)conversation syncToOtherClient:(BOOL)sync;

/**
 设置媒体消息已播放（已经放开限制，所有消息都可以设置为已读状态）
 
 @param messageId 消息ID
 */
- (void)setMediaMessagePlayed:(long)messageId;

/**
 设置消息的本地附加信息，注意信息不在多端之间同步。
 
 @param messageId 消息ID
 @param extra          附加信息
 
 @return YES更新成功，NO消息不存在
 */
- (BOOL)setMessage:(long)messageId localExtra:(NSString *)extra;
/**
获取会话内已读状态

@param conversation 会话
@return 会话的每个用户的已读时间
*/
- (NSMutableDictionary<NSString *, NSNumber *> *)getConversationRead:(WFCCConversation *)conversation;

/**
获取会话内已送达状态

@param conversation 会话
@return 会话的每个用户的已送达时间
*/
- (NSMutableDictionary<NSString *, NSNumber *> *)getMessageDelivery:(WFCCConversation *)conversation;

#pragma mark - 消息相关
/**
 获取消息
 @discuss 获取从fromIndex起count条旧的消息。如果想要获取比fromIndex新的消息，count传负值。
 
 @param conversation 会话
 @param contentTypes 消息类型
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

/**
 获取消息
 @discuss 获取从fromIndex起count条旧的消息。如果想要获取比fromIndex新的消息，count传负值。
 
 @param conversation 会话
 @param messageStatus 消息状态WFCCMessageStatus
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

/**
 获取某类会话信息
 
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @param contentTypes 消息类型
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                           lines:(NSArray<NSNumber *> *)lines
                                    contentTypes:(NSArray<NSNumber *> *)contentTypes
                                            from:(NSUInteger)fromIndex
                                           count:(NSInteger)count
                                        withUser:(NSString *)user;

/**
 获取某类会话信息
 
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @param messageStatus 消息状态
 @param fromIndex 起始index
 @param count 总数
 @param user 对话用户
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getMessages:(NSArray<NSNumber *> *)conversationTypes
                                  lines:(NSArray<NSNumber *> *)lines
                          messageStatus:(NSArray<NSNumber *> *)messageStatus
                                   from:(NSUInteger)fromIndex
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

/**
 获取消息
 @discuss 获取从fromTime起count条旧的消息。如果想要获取比fromIndex新的消息，count传负值。
 
 @param conversation 会话
 @param contentTypes 消息类型
 @param fromTime 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getMessages:(WFCCConversation *)conversation
                           contentTypes:(NSArray<NSNumber *> *)contentTypes
                               fromTime:(NSUInteger)fromTime
                                  count:(NSInteger)count
                               withUser:(NSString *)user;

/**
 获取用户会话消息
 @discuss 获取从fromIndex起count条旧的消息。如果想要获取比fromIndex新的消息，count传负值。
 
 @param userId 用户ID
 @param conversation 会话
 @param contentTypes 消息类型
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                               conversation:(WFCCConversation *)conversation
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count;

/**
 获取用户某类会话信息
 
 @param userId 用户ID
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @param contentTypes 消息类型
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)getUserMessages:(NSString *)userId
                          conversationTypes:(NSArray<NSNumber *> *)conversationTypes
                                      lines:(NSArray<NSNumber *> *)lines
                               contentTypes:(NSArray<NSNumber *> *)contentTypes
                                       from:(NSUInteger)fromIndex
                                      count:(NSInteger)count;
/**
 获取服务器消息
 @discussion 获取得到的消息数目有可能少于指定的count数，如果count不为0就意味着还有更多的消息可以获取，只有获取到的消息数为0才表示没有更多的消息了。
 
 @param conversation 会话
 @param beforeMessageUid 起始index
 @param count 总数
 @param successBlock 返回消息
 @param errorBlock 返回错误码
 */
- (void)getRemoteMessages:(WFCCConversation *)conversation
                   before:(long long)beforeMessageUid
                    count:(NSUInteger)count
             contentTypes:(NSArray<NSNumber *> *)contentTypes
                  success:(void(^)(NSArray<WFCCMessage *> *messages))successBlock
                    error:(void(^)(int error_code))errorBlock;

/**
 获取一条远端消息，消息不会存储在数据库中
 
 @param messageUid     消息ID
 @param successBlock 返回消息
 @param errorBlock      返回错误码
 */
- (void)getRemoteMessage:(long long)messageUid
                 success:(void(^)(WFCCMessage *message))successBlock
                   error:(void(^)(int error_code))errorBlock;
/**
 获取消息
 
 @param messageId 消息ID
 @return 消息实体
 */
- (WFCCMessage *)getMessage:(long)messageId;

/**
 获取消息
 
 @param messageUid 消息UID
 @return 消息实体
 */
- (WFCCMessage *)getMessageByUid:(long long)messageUid;

/**
 搜索消息
 
 @param conversation 会话，如果为空将搜索所有会话
 @param keyword 关键词
 @param desc order
 @param offset offset
 @param limit limit
 @return 命中的消息
 */
- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset;

/**
 搜索消息
 
 @param conversation 会话，如果为空将搜索所有会话
 @param keyword 关键词
 @param contentTypes 过滤的消息类型
 @param desc order
 @param offset offset
 @param limit limit
 @return 命中的消息
 */
- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset;

/**
 搜索消息
 
 @param conversation 会话，如果为空将搜索所有会话
 @param keyword 关键词
 @param contentTypes 过滤的消息类型
 @param startTime 消息的开始时间，单位为毫秒，如果不需要开始时间请用0。
 @param endTime 消息的结束时间，单位为毫秒，如果不需要结束时间请用0.。
 @param desc order
 @param offset offset
 @param limit limit
 @return 命中的消息
 */
- (NSArray<WFCCMessage *> *)searchMessage:(WFCCConversation *)conversation
                                  keyword:(NSString *)keyword
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                startTime:(int64_t)startTime
                                  endTime:(int64_t)endTime
                                    order:(BOOL)desc
                                    limit:(int)limit
                                   offset:(int)offset;

/**
 获取某类会话信息
 
 @param conversationTypes 会话类型
 @param lines 默认传 @[@(0)]
 @param contentTypes 消息类型
 @param keyword 关键字
 @param fromIndex 起始index
 @param count 总数
 @return 消息实体
 */
- (NSArray<WFCCMessage *> *)searchMessage:(NSArray<NSNumber *> *)conversationTypes
                                    lines:(NSArray<NSNumber *> *)lines
                             contentTypes:(NSArray<NSNumber *> *)contentTypes
                                  keyword:(NSString *)keyword
                                     from:(NSUInteger)fromIndex
                                    count:(NSInteger)count;
/**
 发送消息

 @param conversation 会话
 @param content 消息内容
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock;

/**
 发送媒体消息

 @param conversation 会话
 @param content 消息内容
 @param successBlock 成功的回调
 @param progressBlock 上传进度的回调，注意仅当媒体内容大于300K才会有回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock;

/**
 发送消息
 
 @param conversation 会话
 @param content 消息内容
 @param expireDuration 消息的有效期，0不限期，单位秒
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock;

/**
 发送消息
 
 @param conversation 会话
 @param content 消息内容
 @param toUsers 在会话中只发给该用户，如果为空则发到会话中
 @param expireDuration 消息的有效期，0不限期，单位秒
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)send:(WFCCConversation *)conversation
              content:(WFCCMessageContent *)content
              toUsers:(NSArray<NSString *> *)toUsers
       expireDuration:(int)expireDuration
              success:(void(^)(long long messageUid, long long timestamp))successBlock
                error:(void(^)(int error_code))errorBlock;

/**
 发送媒体消息
 
 @param conversation 会话
 @param content 消息内容
 @param expireDuration 消息的有效期，0不限期，单位秒
 @param successBlock 成功的回调
 @param progressBlock 上传进度的回调，注意仅当媒体内容大于300K才会有回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock;


/**
 发送媒体消息
 
 @param conversation 会话
 @param content 消息内容
 @param toUsers 在会话中只发给该用户，如果为空则发到会话中
 @param expireDuration 消息的有效期，0不限期，单位秒
 @param successBlock 成功的回调
 @param progressBlock 上传进度的回调，注意仅当媒体内容大于300K才会有回调
 @param errorBlock 失败的回调
 @return 消息实体
 */
- (WFCCMessage *)sendMedia:(WFCCConversation *)conversation
                   content:(WFCCMessageContent *)content
                   toUsers:(NSArray<NSString *> *)toUsers
            expireDuration:(int)expireDuration
                   success:(void(^)(long long messageUid, long long timestamp))successBlock
                  progress:(void(^)(long uploaded, long total))progressBlock
                     error:(void(^)(int error_code))errorBlock;

/**
 发送已保存消息，消息状态必须是发送中或者发送失败

 @param message 已经存储在本地待发送的消息
 @param expireDuration 消息的有效期，0不限期，单位秒
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @return 协议栈是否可以发送
 */
- (BOOL)sendSavedMessage:(WFCCMessage *)message
          expireDuration:(int)expireDuration
                 success:(void(^)(long long messageUid, long long timestamp))successBlock
                   error:(void(^)(int error_code))errorBlock;
/**
 撤回消息
 
 @param message 待撤回的消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @discuss 服务器不检查可撤回时间，应用逻辑来处理。
 */
- (void)recall:(WFCCMessage *)message
       success:(void(^)(void))successBlock
         error:(void(^)(int error_code))errorBlock;

/**
 上传媒体(图片、语音、文件等)
 
 @param fileName 文件名，可为空
 @param mediaData 媒体信息
 @param mediaType 媒体类型
 @param successBlock 成功的回调
 @param progressBlock 上传进度的回调，注意仅当媒体内容大于300K才会有回调
 @param errorBlock 失败的回调
 */
- (void)uploadMedia:(NSString *)fileName
          mediaData:(NSData *)mediaData
          mediaType:(WFCCMediaType)mediaType
            success:(void(^)(NSString *remoteUrl))successBlock
           progress:(void(^)(long uploaded, long total))progressBlock
              error:(void(^)(int error_code))errorBlock;

/**
 同步上传媒体(图片、语音、文件等)，成功或者失败之后才会返回
 
 @param fileName 文件名，可为空
 @param mediaData 媒体信息
 @param mediaType 媒体类型
 @param successBlock 成功的回调
 @param progressBlock 上传进度的回调，注意仅当媒体内容大于300K才会有回调
 @param errorBlock 失败的回调
 
 @return 是否上传成功
 */
- (BOOL)syncUploadMedia:(NSString *)fileName
              mediaData:(NSData *)mediaData
              mediaType:(WFCCMediaType)mediaType
                success:(void(^)(NSString *remoteUrl))successBlock
               progress:(void(^)(long uploaded, long total))progressBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 获取上传接口，用来上传大文件。只有专业版才支持，使用前先调用isSupportBigFilesUpload检查是否支持
 
 @param fileName 文件名
 @param mediaType 媒体类型
 @param contentType Http的ContentType header，为空时默认为"application/octet-stream"
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getUploadUrl:(NSString *)fileName
           mediaType:(WFCCMediaType)mediaType
         contentType:(NSString *)contentType
            success:(void(^)(NSString *uploadUrl, NSString *downloadUrl, NSString *backupUploadUrl, int type))successBlock
              error:(void(^)(int error_code))errorBlock;

/**
 是否支持大文件上传
 
 @return YES支持大文件上传，调用getUploadUrl:getUploadUrl:success:error:方法获取到上传url，然后再在应用层上传。
 */
- (BOOL)isSupportBigFilesUpload;

/**
 删除消息
 
 @param messageId 消息ID
 @return 是否删除成功
 */
- (BOOL)deleteMessage:(long)messageId;

/**
 删除远端消息，仅专业版支持。
 
 @param messageUid 消息UID
 @param successBlock 删除成功
 @param errorBlock 删除失败
 */
- (void)deleteRemoteMessage:(long long)messageUid
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock;

/**
 更新远端消息，仅专业版支持。
 
 @discussion 客户端仅能更新自己发送的消息，更新的消息类型不能变，更新的消息类型是服务配置允许更新的内容。Server API更新则没有限制。
 
 @param messageUid 消息UID
 @param content 更新消息内容
 @param distribute 是否分发到其他客户端
 @param updateLocal 是否更新本地消息内容
 @param successBlock 删除成功
 @param errorBlock 删除失败
 */
- (void)updateRemoteMessage:(long long)messageUid
                    content:(WFCCMessageContent *)content
                 distribute:(BOOL)distribute
                updateLocal:(BOOL)updateLocal
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock;

/**
 删除会话中的消息
 
 @param conversation 会话
 */
- (void)clearMessages:(WFCCConversation *)conversation;

/**
 删除会话中的before之前的旧消息。
 
 @param conversation 会话，如果conversation为nil，则清除所有会话的消息。
 @param before 时间点，单位是毫秒
 */
- (void)clearMessages:(WFCCConversation *)conversation before:(int64_t)before;

/**
 注册自定义消息类型
 
 @param contentClass 自定义消息
 */
- (void)registerMessageContent:(Class)contentClass;

/**
 消息解码
 
 @param payload 消息Payload
 @return 消息内容
 */
- (WFCCMessageContent *)messageContentFromPayload:(WFCCMessagePayload *)payload;


/**
 插入消息
 
 @param conversation 会话
 @param content 消息内容
 @param status 消息状态，注意消息状态会影响消息方向
 @param serverTime 时间，0为当前时间
 @return 消息实体
 */
- (WFCCMessage *)insert:(WFCCConversation *)conversation
                 sender:(NSString *)sender
                content:(WFCCMessageContent *)content
                 status:(WFCCMessageStatus)status
                 notify:(BOOL)notify
             serverTime:(long long)serverTime;

/**
 更新消息内容。只更新本地消息内容，无法更新服务器和远端。
 
 @param messageId 消息ID
 @param content 消息内容
 */
- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content;

/**
 更新消息内容及时间。只更新本地消息内容，无法更新服务器和远端。
 
 @param messageId 消息ID
 @param content   消息内容
 @param timestamp 消息时间戳
 */
- (void)updateMessage:(long)messageId
              content:(WFCCMessageContent *)content
            timestamp:(long long)timestamp;

/**
更新消息状态，需要确保状态跟消息的方向相对应。一般情况下协议栈会自动处理好，不建议客户手动操作状态。。只更新本地消息内容，无法更新服务器和远端。

@param messageId 消息ID
@param status 消息状态
 
@return YES 更新成功。NO 消息不存在，或者状态与消息方向不匹配
*/
- (BOOL)updateMessage:(long)messageId status:(WFCCMessageStatus)status;

/**
 插入消息。只插入到本地，无法更新服务器和远端。
 
 @param message 待插入的消息
 @return 插入消息的id
 */
- (long)insertMessage:(WFCCMessage *)message;

/**
 获取会话的消息数
 
 @param conversation 会话。
 @return 会话的消息数。
 */
- (int)getMessageCount:(WFCCConversation *)conversation;
#pragma mark - 用户相关
/**
 获取用户信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的单聊会话中时或者此人的用户信息页面使用一次true。
 
 @param userId 用户ID
 @param refresh 是否强制从服务器更新，如果本地没有或者强制，会从服务器刷新，然后发出通知kUserInfoUpdated。
 @return 本地的用户信息，可能为空
 */
- (WFCCUserInfo *)getUserInfo:(NSString *)userId
                      refresh:(BOOL)refresh;

/**
 获取用户信息
 @discussion 获取用户信息，如果在群中有群昵称也一并返回
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的单聊会话中时或者此人的用户信息页面使用一次true。
 
 @param userId 用户ID
 @param groupId 群组ID
 @param refresh 是否强制从服务器更新，如果本地没有或者强制，会从服务器刷新，然后发出通知kUserInfoUpdated。
 @return 本地的用户信息，可能为空
 */
- (WFCCUserInfo *)getUserInfo:(NSString *)userId inGroup:(NSString *)groupId refresh:(BOOL)refresh;

/**
 批量获取用户信息
 
 @param userIds 用户ID列表
 @param groupId 群组ID
 @return 本地的用户信息列表。本地不存在的用户会返回只有id的用户信息，同时会拉取。
 */
- (NSArray<WFCCUserInfo *> *)getUserInfos:(NSArray<NSString *> *)userIds inGroup:(NSString *)groupId;

/**
 搜索用户
 
 @param keyword 关键词
 @param searchType 搜索类型
 @param page page
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)searchUser:(NSString *)keyword
        searchType:(WFCCSearchUserType)searchType
              page:(int)page
           success:(void(^)(NSArray<WFCCUserInfo *> *machedUsers))successBlock
             error:(void(^)(int errorCode))errorBlock;

/**
 获取用户信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的单聊会话中时或者此人的用户信息页面使用true
 
 @param userId 用户ID
 @param refresh 是否强制从服务器更新，如果本地没有或者强制，会从服务器刷新，然后发出通知kUserInfoUpdated。
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getUserInfo:(NSString *)userId
            refresh:(BOOL)refresh
            success:(void(^)(WFCCUserInfo *userInfo))successBlock
            error:(void(^)(int errorCode))errorBlock;
#pragma mark - 好友相关
/**
 查询用户和当前用户是否是好友关系

 @param userId 用户ID
 @return 是否是好友
 */
- (BOOL)isMyFriend:(NSString *)userId;

/**
 获取当前用户的好友列表

 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 好友列表的用户ID
 */
- (NSArray<NSString *> *)getMyFriendList:(BOOL)refresh;

/**
 获取当前用户的好友列表

 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 好友列表
 */
- (NSArray<WFCCFriend *> *)getFriendList:(BOOL)refresh;

/**
 搜索好友
 @param keyword 关键词
 @return 好友用户信息
 */
- (NSArray<WFCCUserInfo *> *)searchFriends:(NSString *)keyword;

/**
 搜索群组
 @param keyword 关键词
 @return 群组搜索结果
 */
- (NSArray<WFCCGroupSearchInfo *> *)searchGroups:(NSString *)keyword;

/**
 获取收到的好友请求

 @return 好友请求
 */
- (NSArray<WFCCFriendRequest *> *)getIncommingFriendRequest;

/**
 获取发出的好友请求

 @return 好友请求
 */
- (NSArray<WFCCFriendRequest *> *)getOutgoingFriendRequest;

/**
 获取某一条好友请求记录
 @param uerId 对方用户ID
 @param direction 0 发送的好友请求；1 收到的好友请求。
 
 @return 好友请求
 */
- (WFCCFriendRequest *)getFriendRequest:(NSString *)uerId direction:(int)direction;

/**
 从服务器更新好友请求
 */
- (void)loadFriendRequestFromRemote;

/**
 获取未读的好友请求数

 @return 未读的好友请求数
 */
- (int)getUnreadFriendRequestStatus;

/**
 清除好友请求的未读数
 */
- (void)clearUnreadFriendRequestStatus;

/**
 删除好友
 
 @param userId 用户ID
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)deleteFriend:(NSString *)userId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock;

/**
 发送好友请求

 @param userId 用户ID
 @param reason 请求说明
 @param extra 扩展信息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)sendFriendRequest:(NSString *)userId
                   reason:(NSString *)reason
                    extra:(NSString *)extra
                  success:(void(^)(void))successBlock
                    error:(void(^)(int error_code))errorBlock;

/**
 处理好友请求

 @param userId 用户ID
 @param accpet 是否接受
 @param extra 附加信息，如果接受，附加信息会添加到好友附加信息中
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)handleFriendRequest:(NSString *)userId
                     accept:(BOOL)accpet
                      extra:(NSString *)extra
                    success:(void(^)(void))successBlock
                      error:(void(^)(int error_code))errorBlock;

- (NSString *)getFriendAlias:(NSString *)friendId;

- (void)setFriend:(NSString *)friendId
            alias:(NSString *)alias
          success:(void(^)(void))successBlock
            error:(void(^)(int error_code))errorBlock;

- (NSString *)getFriendExtra:(NSString *)friendId;
/**
 查询用户是否被加入黑名单
 
 @param userId 用户ID
 @return 是否被加入黑名单
 */
- (BOOL)isBlackListed:(NSString *)userId;

/**
 获取当前用户的黑名单列表
 
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 黑名单列表的用户ID
 */
- (NSArray<NSString *> *)getBlackList:(BOOL)refresh;

/**
 设置黑名单
 
 @param userId 用户ID
 @param isBlackListed YES 加入黑名单； NO 取消黑名单
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setBlackList:(NSString *)userId
       isBlackListed:(BOOL)isBlackListed
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock;

#pragma mark - 群相关
/**
 获取群成员信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的群聊会话详情中时使用一次true。
 
 @param groupId 群ID
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 群成员信息列表
 */
- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                                    forceUpdate:(BOOL)refresh;

/**
 根据成员类型获取群成员信息
 
 @param groupId 群ID
 @param memberType 群成员类型
 @return 群成员信息列表
 */
- (NSArray<WFCCGroupMember *> *)getGroupMembers:(NSString *)groupId
                                    type:(WFCCGroupMemberType)memberType;

/**
 获取群成员信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的群聊会话详情中时使用一次true。
 
 @param groupId 群ID
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getGroupMembers:(NSString *)groupId
                refresh:(BOOL)refresh
                success:(void(^)(NSString *groupId, NSArray<WFCCGroupMember *> *))successBlock
                  error:(void(^)(int errorCode))errorBlock;

/**
 获取群信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的群聊会话中时使用一次true。
 
 @param groupId 群ID
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 群信息
 */
- (WFCCGroupInfo *)getGroupInfo:(NSString *)groupId
                        refresh:(BOOL)refresh;

/**
 获取群信息
 @discussion refresh 为true会导致一次网络同步，代价特别大，应该尽量避免使用true，仅当在进入此人的群聊会话中时使用一次true。
 
 @param groupId 群ID
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getGroupInfo:(NSString *)groupId
             refresh:(BOOL)refresh
             success:(void(^)(WFCCGroupInfo *groupInfo))successBlock
               error:(void(^)(int errorCode))errorBlock;
/**
 获取群成员信息
 
 @param groupId 群ID
 @param memberId 群成员ID
 @return 群成员信息
 */
- (WFCCGroupMember *)getGroupMember:(NSString *)groupId
                           memberId:(NSString *)memberId;

/**
 创建群

 @param groupId 群ID
 @param groupName 群名称
 @param groupPortrait 群头像
 @param groupMembers 群成员
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)createGroup:(NSString *)groupId
               name:(NSString *)groupName
           portrait:(NSString *)groupPortrait
               type:(WFCCGroupType)type
         groupExtra:(NSString *)groupExtra
            members:(NSArray *)groupMembers
        memberExtra:(NSString *)memberExtra
        notifyLines:(NSArray<NSNumber *> *)notifyLines
      notifyContent:(WFCCMessageContent *)notifyContent
            success:(void(^)(NSString *groupId))successBlock
              error:(void(^)(int error_code))errorBlock;

/**
 添加群成员

 @param members 成员的用户ID列表
 @param groupId 群ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)addMembers:(NSArray *)members
           toGroup:(NSString *)groupId
       memberExtra:(NSString *)memberExtra
       notifyLines:(NSArray<NSNumber *> *)notifyLines
     notifyContent:(WFCCMessageContent *)notifyContent
           success:(void(^)(void))successBlock
             error:(void(^)(int error_code))errorBlock;

/**
 踢出群成员

 @param members 成员的用户ID列表
 @param groupId 群ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)kickoffMembers:(NSArray *)members
             fromGroup:(NSString *)groupId
           notifyLines:(NSArray<NSNumber *> *)notifyLines
         notifyContent:(WFCCMessageContent *)notifyContent
               success:(void(^)(void))successBlock
                 error:(void(^)(int error_code))errorBlock;

/**
 退群

 @param groupId 群ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)quitGroup:(NSString *)groupId
      notifyLines:(NSArray<NSNumber *> *)notifyLines
    notifyContent:(WFCCMessageContent *)notifyContent
          success:(void(^)(void))successBlock
            error:(void(^)(int error_code))errorBlock;

/**
 解散群

 @param groupId 群ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)dismissGroup:(NSString *)groupId
         notifyLines:(NSArray<NSNumber *> *)notifyLines
       notifyContent:(WFCCMessageContent *)notifyContent
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock;

/**
 修改群信息

 @param groupId 群ID
 @param type    要修改的群属性
 @param newValue    要修改的群属性值
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyGroupInfo:(NSString *)groupId
                   type:(ModifyGroupInfoType)type
               newValue:(NSString *)newValue
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 修改自己的群昵称

 @param groupId 群ID
 @param newAlias 昵称
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyGroupAlias:(NSString *)groupId
                   alias:(NSString *)newAlias
             notifyLines:(NSArray<NSNumber *> *)notifyLines
           notifyContent:(WFCCMessageContent *)notifyContent
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock;

/**
 修改群成员的昵称，群主可以修改所有人，群管理员可以修改普通成员的群昵称

 @param groupId 群ID
 @param newAlias 昵称
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyGroupMemberAlias:(NSString *)groupId
                      memberId:(NSString *)memberId
                         alias:(NSString *)newAlias
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock;

/**
 修改自己的群成员附加信息

 @param groupId 群ID
 @param extra 附加信息
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyGroupMemberExtra:(NSString *)groupId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock;

/**
 修改群成员的附加信息，群主可以修改所有人，群管理员可以修改普通成员的附加信息

 @param groupId 群ID
 @param extra 附加信息
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyGroupMemberExtra:(NSString *)groupId
                      memberId:(NSString *)memberId
                         extra:(NSString *)extra
                   notifyLines:(NSArray<NSNumber *> *)notifyLines
                 notifyContent:(WFCCMessageContent *)notifyContent
                       success:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock;
/**
 转移群主

 @param groupId 群ID
 @param newOwner 群主的用户ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)transferGroup:(NSString *)groupId
                   to:(NSString *)newOwner
          notifyLines:(NSArray<NSNumber *> *)notifyLines
        notifyContent:(WFCCMessageContent *)notifyContent
              success:(void(^)(void))successBlock
                error:(void(^)(int error_code))errorBlock;

/**
 设置群管理
 
 @param groupId 群ID
 @param isSet    设置或取消
 @param memberIds    成员ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setGroupManager:(NSString *)groupId
                  isSet:(BOOL)isSet
              memberIds:(NSArray<NSString *> *)memberIds
            notifyLines:(NSArray<NSNumber *> *)notifyLines
          notifyContent:(WFCCMessageContent *)notifyContent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 设置群成员禁言，仅专业版支持
 
 @param groupId 群ID
 @param isSet    设置或取消
 @param memberIds    成员ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)muteGroupMember:(NSString *)groupId
                     isSet:(BOOL)isSet
                 memberIds:(NSArray<NSString *> *)memberIds
               notifyLines:(NSArray<NSNumber *> *)notifyLines
             notifyContent:(WFCCMessageContent *)notifyContent
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;

/**
 设置群成员允许名单，当设置群全局禁言时，仅群主/群管理/运行名单成员可以发言，仅专业版支持
 
 @param groupId 群ID
 @param isSet    设置或取消
 @param memberIds    成员ID
 @param notifyLines 默认传 @[@(0)]
 @param notifyContent 通知消息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)allowGroupMember:(NSString *)groupId
                   isSet:(BOOL)isSet
               memberIds:(NSArray<NSString *> *)memberIds
             notifyLines:(NSArray<NSNumber *> *)notifyLines
           notifyContent:(WFCCMessageContent *)notifyContent
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock;
/**
 获取当前用户收藏的群组
 
 @return 当前用户收藏的群组ID
 */
- (NSArray<NSString *> *)getFavGroups;

/**
 是否是当前用户收藏的群组
 
 @return 是否是当前用户收藏的群组
 */
- (BOOL)isFavGroup:(NSString *)groupId;

/**
 设置群组收藏状态
 
 @param groupId 群组ID
 @param fav 是否收藏
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setFavGroup:(NSString *)groupId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock;
#pragma mark - 个人设置相关
/**
 获取个人设置

 @param scope 设置项的scope
 @param key 设置项的key
 @return 设置值
 */
- (NSString *)getUserSetting:(UserSettingScope)scope
                         key:(NSString *)key;

/**
 获取个人一类设置
 
 @param scope 设置项的scope
 @return scope对应的所有设置值
 */
- (NSDictionary<NSString *, NSString *> *)getUserSettings:(UserSettingScope)scope;

/**
 设置个人设置项

 @param scope 设置项的scope
 @param key 设置项的key
 @param value 值
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setUserSetting:(UserSettingScope)scope
                   key:(NSString *)key
                 value:(NSString *)value
               success:(void(^)(void))successBlock
                 error:(void(^)(int error_code))errorBlock;

/**
 修改个人信息
 
 @param values 信息
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 @discuss 性别属性是int类型，修改时需要转为字符串类型
 */
-(void)modifyMyInfo:(NSDictionary<NSNumber */*ModifyMyInfoType*/, NSString *> *)values
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;



/**
是否全局静音

@return YES，当前用户全局静音；NO，没有全局静音
*/
- (BOOL)isGlobalSilent;

/**
修改全局静音状态

@param silent 是否静音
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setGlobalSilent:(BOOL)silent
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
是否实时音视频通知面打扰。服务器端2021.9.20后支持分别设置通知免打扰和实时音视频免打扰

@return YES，当前用户音视频不通知；NO，当前用户音视频通知
*/
- (BOOL)isVoipNotificationSilent;

/**
修改实时音视频通知面打扰。服务器端2021.9.20后支持分别设置通知免打扰和实时音视频免打扰

@param silent 是否静音
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setVoipNotificationSilent:(BOOL)silent
                          success:(void(^)(void))successBlock
                            error:(void(^)(int error_code))errorBlock;

/**
是否开启草稿同步

@return YES，同步；NO，不同步
*/
- (BOOL)isEnableSyncDraft;

/**
修改是否开启草稿同步

@param enable 是否同步
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setEnableSyncDraft:(BOOL)enable
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;

/**
获取免打扰时间

 @param resultBlock 免打扰时间回调，时间为UTC 0点开始的分钟数，需要转换成当地时间。
 @param errorBlock 不存在时调用，error_code为-1
*/
- (void)getNoDisturbingTimes:(void(^)(int startMins, int endMins))resultBlock
                       error:(void(^)(int error_code))errorBlock;

/**
修改免打扰时间

@param startMins 起始时间，一天中的分钟数，时间为UTC，需要转换成当地时间。
@param endMins 结束时间，一天中的分钟数。可以小于startMins，如果小于表示隔夜。
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setNoDisturbingTimes:(int)startMins
                     endMins:(int)endMins
                     success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock;

/**
取消免打扰时间

@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)clearNoDisturbingTimes:(void(^)(void))successBlock
                         error:(void(^)(int error_code))errorBlock;

/**
 当前时间是否是免打扰
 */
- (BOOL)isNoDisturbing;

/**
是否隐藏推送详情

@return YES，隐藏推送详情，提示“您收到一条消息”；NO，推送显示消息摘要
*/
- (BOOL)isHiddenNotificationDetail;

/**
修改全局静音状态

@param hidden 是否静音
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setHiddenNotificationDetail:(BOOL)hidden
                            success:(void(^)(void))successBlock
                              error:(void(^)(int error_code))errorBlock;

/**
是否隐藏群组会话中群成员昵称显示

@return YES，群组会话中不显示群成员昵称；NO，显示
*/
- (BOOL)isHiddenGroupMemberName:(NSString *)groupId;

/**
修改隐藏群组会话中群成员昵称显示状态

@param hidden 是否隐藏
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)setHiddenGroupMemberName:(BOOL)hidden
                           group:(NSString *)groupId
                         success:(void(^)(void))successBlock
                           error:(void(^)(int error_code))errorBlock;
/**
当前用户是否启用消息回执功能，仅专业版有效

@return YES，开启消息回执功能；NO，关闭个人的消息回执功能。
@disscussion 仅当服务器开启这个功能才有效
*/
- (BOOL)isUserEnableReceipt;
/**
修改当前用户是否启用消息回执功能，仅专业版有效

@param enable 是否开启
@param successBlock 成功的回调
@param errorBlock 失败的回调
 @disscussion 仅当服务器开启这个功能才有效
*/
- (void)setUserEnableReceipt:(BOOL)enable
                success:(void(^)(void))successBlock
                       error:(void(^)(int error_code))errorBlock;



/**
 获取当前用户星标用户
 
 @return 当前用户星标用户
 */
- (NSArray<NSString *> *)getFavUsers;

/**
 是否是星标用户
 
 @return 是否是星标用户
 */
- (BOOL)isFavUser:(NSString *)userId;

/**
 设置星标用户
 
 @param userId 用户ID
 @param fav 是否星标
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)setFavUser:(NSString *)userId fav:(BOOL)fav success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock;
#pragma mark - 聊天室相关
- (void)joinChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock;

- (void)quitChatroom:(NSString *)chatroomId
             success:(void(^)(void))successBlock
               error:(void(^)(int error_code))errorBlock;

- (void)getChatroomInfo:(NSString *)chatroomId
                upateDt:(long long)updateDt
                success:(void(^)(WFCCChatroomInfo *chatroomInfo))successBlock
                  error:(void(^)(int error_code))errorBlock;

- (void)getChatroomMemberInfo:(NSString *)chatroomId
                      maxCount:(int)maxCount
                      success:(void(^)(WFCCChatroomMemberInfo *memberInfo))successBlock
                        error:(void(^)(int error_code))errorBlock;

#pragma mark - 频道相关
- (void)createChannel:(NSString *)channelName
             portrait:(NSString *)channelPortrait
                 desc:(NSString *)desc
                extra:(NSString *)extra
            success:(void(^)(WFCCChannelInfo *channelInfo))successBlock
              error:(void(^)(int error_code))errorBlock;

/**
 获取频道信息
 
 @param channelId 频道ID
 @param refresh 是否强制从服务器更新，如果不刷新则从本地缓存中读取
 @return 群信息
 */
- (WFCCChannelInfo *)getChannelInfo:(NSString *)channelId
                            refresh:(BOOL)refresh;

/**
 修改频道信息
 
 @param channelId 群ID
 @param type    要修改的群属性
 @param newValue    要修改的群属性值
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)modifyChannelInfo:(NSString *)channelId
                   type:(ModifyChannelInfoType)type
               newValue:(NSString *)newValue
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 搜索频道
 
 @param keyword 关键词
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)searchChannel:(NSString *)keyword success:(void(^)(NSArray<WFCCChannelInfo *> *machedChannels))successBlock error:(void(^)(int errorCode))errorBlock;

/**
 是否收听频道
 
 @param channelId 频道ID
 @return YES，收听；NO，未收听
 */
- (BOOL)isListenedChannel:(NSString *)channelId;

/**
 收听或者取消收听频道
 
 @param channelId 频道ID
 @param listen 是否收听
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)listenChannel:(NSString *)channelId listen:(BOOL)listen success:(void(^)(void))successBlock error:(void(^)(int errorCode))errorBlock;

/**
 获取当前用户创建的频道
 
 @return 当前用户创建的频道ID
 */
- (NSArray<NSString *> *)getMyChannels;

/**
 获取当前用户收听的频道
 
 @return 当前用户收听的频道ID
 */
- (NSArray<NSString *> *)getListenedChannels;

/**
 销毁频道
 
 @param channelId 频道ID
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)destoryChannel:(NSString *)channelId
               success:(void(^)(void))successBlock
                 error:(void(^)(int error_code))errorBlock;

#pragma mark - 其它接口
/**
获取PC在线信息

@return PC端在线状态
*/
- (NSArray<WFCCPCOnlineInfo *> *)getPCOnlineInfos;

/**
踢掉PC或者Web

@param pcClientId PC或Web端的clientId
@param successBlock 成功的回调
@param errorBlock 失败的回调
*/
- (void)kickoffPCClient:(NSString *)pcClientId
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock;

/**
 PC/Web在线时，是否发送通知

 @return 是否通知
 */
- (BOOL)isMuteNotificationWhenPcOnline;

/**
 设置PC/Web在线时，手机是否默认静音。缺省值为YES，如果IM服务配置server.mobile_default_silent_when_pc_online 为false时，需要调用此函数设置为NO，此时静音状态意义翻转。

 @param defaultSilent 缺省值是否为静音。
 */
- (void)setDefaultSilentWhenPcOnline:(BOOL)defaultSilent;

/**
 设置PC/Web在线时，是否发送通知

 @param isMute 是否通知
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)muteNotificationWhenPcOnline:(BOOL)isMute
                             success:(void(^)(void))successBlock
                               error:(void(^)(int error_code))errorBlock;

/**
 获取会话文件。conversation不为空时，获取该会话内的文件记录；当conversation为空时，获取用户收到的所有文件记录。

 @param conversation 会话
 @param fromUser 该用户发送的文件，如果为空返回所有文件
 @param messageUid 起始记录的UID
 @param count count
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getConversationFiles:(WFCCConversation *)conversation
                    fromUser:(NSString *)fromUser
            beforeMessageUid:(long long)messageUid
                       count:(int)count
                     success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                       error:(void(^)(int error_code))errorBlock;

/**
 获取当前用户发送的文件。

 @param beforeMessageUid 起始记录的UID
 @param count count
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)getMyFiles:(long long)beforeMessageUid
             count:(int)count
           success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
             error:(void(^)(int error_code))errorBlock;

/**
 删除文件记录。发送者可以删除，另外如果在群里，群主和管理员也可以删除。

 @param messageUid 起始记录的UID
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)deleteFileRecord:(long long)messageUid
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock;

/**
 搜索文件。conversation不为空时，搜索该会话内的文件记录；当conversation为空时，搜索用户收到的所有文件记录。

 @param keyword 关键字
 @param conversation 会话
 @param fromUser 该用户发送的文件，如果为空返回所有文件
 @param messageUid 起始记录的UID
 @param count count
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)searchFiles:(NSString *)keyword
       conversation:(WFCCConversation *)conversation
           fromUser:(NSString *)fromUser
   beforeMessageUid:(long long)messageUid
              count:(int)count
            success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
              error:(void(^)(int error_code))errorBlock;

/**
 搜索当前用户发送的文件。

 @param keyword 关键字
 @param beforeMessageUid 起始记录的UID
 @param count count
 @param successBlock 成功的回调
 @param errorBlock 失败的回调
 */
- (void)searchMyFiles:(NSString *)keyword
     beforeMessageUid:(long long)beforeMessageUid
                count:(int)count
              success:(void(^)(NSArray<WFCCFileRecord *> *files))successBlock
                error:(void(^)(int error_code))errorBlock;

/**
获取媒体文件授权访问地址

@param messageUid 消息Uid
@param mediaType 媒体类型
@param mediaPath 媒体Path
@param successBlock 成功的回调，backupAuthorizedUrl仅当支持双网环境才有意义
@param errorBlock 失败的回调
*/
- (void)getAuthorizedMediaUrl:(long long)messageUid
                    mediaType:(WFCCMediaType)mediaType
                    mediaPath:(NSString *)mediaPath
                      success:(void(^)(NSString *authorizedUrl, NSString *backupAuthorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock;

/**
amr文件转成wav数据

@param amrPath amr文件路径
@return wav数据
*/
- (NSData *)getWavData:(NSString *)amrPath;

/**
 获取图片缩略图参数
 
 @return 图片缩略图参数
 */
- (NSString *)imageThumbPara;


/**
 开启数据库事务。注意：该方法仅仅在做数据迁移时使用，其它情况不要使用；另外开启成功后一定要注意commit，需要配对使用.
 
 @return 是否开启成功。
 */
- (BOOL)beginTransaction;

/**
提交数据库事务。注意：该方法仅仅在做数据迁移时使用，其它情况不要使用；需要跟beginTransaction配对使用
 
*/
- (void)commitTransaction;

/**
 是否是商业版IM服务。
 */
- (BOOL)isCommercialServer;

/**
是否支持已送达报告和已阅读报告
*/
- (BOOL)isReceiptEnabled;

/*
 是否应用关闭草稿同步功能
 */
- (BOOL)isGlobalDisableSyncDraft;

/*
 获取用户的在线状态
 */
- (WFCCUserOnlineState *)getUserOnlineState:(NSString *)userId;

- (WFCCUserCustomState *)getMyCustomState;

- (void)setMyCustomState:(WFCCUserCustomState *)state
                 success:(void(^)(void))successBlock
                   error:(void(^)(int error_code))errorBlock;

- (void)watchOnlineState:(WFCCConversationType)conversationType
                 targets:(NSArray<NSString *> *)targets
                duration:(int)watchDuration
                 success:(void(^)(NSArray<WFCCUserOnlineState *> *states))successBlock
                   error:(void(^)(int error_code))errorBlock;

- (void)unwatchOnlineState:(WFCCConversationType)conversationType
                   targets:(NSArray<NSString *> *)targets
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock;

- (BOOL)isEnableUserOnlineState;
/*
 音视频会议相关
 */
- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock;

- (void)sendConferenceRequest:(long long)sessionId
                         room:(NSString *)roomId
                      request:(NSString *)request
                     advanced:(BOOL)advanced
                         data:(NSString *)data
                      success:(void(^)(NSString *authorizedUrl))successBlock
                        error:(void(^)(int error_code))errorBlock;

- (void)requireLock:(NSString *)lockId
           duration:(NSUInteger)duration
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;

- (void)releaseLock:(NSString *)lockId
            success:(void(^)(void))successBlock
              error:(void(^)(int error_code))errorBlock;

//内部调用，请勿使用
- (void)putUseOnlineStates:(NSArray<WFCCUserOnlineState *> *)states;
@end
