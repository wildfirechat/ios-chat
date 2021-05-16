//
//  WFCUEnum.h
//  WFChatUIKit
//
//  Created by heavyrian.lee on 2021/5/16.
//  Copyright © 2021 WildfireChat. All rights reserved.
//

#ifndef WFCUEnum_h
#define WFCUEnum_h


/**
 添加好友来源

 - FriendSource_Unknown: 未知
 - FriendSource_Search: 搜索
 - FriendSource_Group: 群组，targetId为群主ID
 - FriendSource_QrCode: 二维码，targetId为分享二维码的用户Id
 - FriendSource_Card: 用户名片，targetId为分享名片的用户Id
 */
typedef NS_ENUM(NSInteger, WFCUFriendSourceType) {
    FriendSource_Unknown,
    FriendSource_Search,
    FriendSource_Group,
    FriendSource_QrCode,
    FriendSource_Card,
};

/**
 群成员来源

 - GroupMemberSource_Unknown: 搜索
 - GroupMemberSource_Search: 搜索
 - GroupMemberSource_Invite: 邀请，targetId为邀请人的用户id
 - GroupMemberSource_QrCode: 二维码，targetId为分享群二维码的用户id
 - GroupMemberSource_Card: 群名片，targetId为分享群名片的用户Id
 */
typedef NS_ENUM(NSInteger, WFCUGroupMemberSourceType) {
    GroupMemberSource_Unknown,
    GroupMemberSource_Search,
    GroupMemberSource_Invite,
    GroupMemberSource_QrCode,
    GroupMemberSource_Card,
};

#endif /* WFCUEnum_h */
