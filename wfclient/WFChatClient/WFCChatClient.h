//
//  WFChatClient.h
//  WFChatClient
//
//  Created by heavyrain on 2017/11/5.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for WFChatClient.
FOUNDATION_EXPORT double WFChatClientVersionNumber;

//! Project version string for WFChatClient.
FOUNDATION_EXPORT const unsigned char WFChatClientVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WFChatClient/PublicHeader.h>


#import <WFChatClient/WFCCIMService.h>
#import <WFChatClient/WFCCNetworkService.h>
#import <WFChatClient/Common.h>

#import <WFChatClient/WFCCMessage.h>
#import <WFChatClient/WFCCMessageContent.h>
#import <WFChatClient/WFCCAddGroupeMemberNotificationContent.h>
#import <WFChatClient/WFCCCreateGroupNotificationContent.h>
#import <WFChatClient/WFCCDismissGroupNotificationContent.h>
#import <WFChatClient/WFCCImageMessageContent.h>
#import <WFChatClient/WFCCKickoffGroupMemberNotificationContent.h>
#import <WFChatClient/WFCCMediaMessageContent.h>
#import <WFChatClient/WFCCNotificationMessageContent.h>
#import <WFChatClient/WFCCTipNotificationMessageContent.h>
#import <WFChatClient/WFCCQuitGroupNotificationContent.h>
#import <WFChatClient/WFCCSoundMessageContent.h>
#import <WFChatClient/WFCCFileMessageContent.h>
#import <WFChatClient/WFCCTextMessageContent.h>
#import <WFChatClient/WFCCPTextMessageContent.h>
#import <WFChatClient/WFCCUnknownMessageContent.h>
#import <WFChatClient/WFCCChangeGroupNameNotificationContent.h>
#import <WFChatClient/WFCCChangeGroupPortraitNotificationContent.h>
#import <WFChatClient/WFCCModifyGroupAliasNotificationContent.h>
#import <WFChatClient/WFCCTransferGroupOwnerNotificationContent.h>
#import <WFChatClient/WFCCStickerMessageContent.h>
#import <WFChatClient/WFCCLocationMessageContent.h>
#import <WFChatClient/WFCCCallStartMessageContent.h>
#import <WFChatClient/WFCCTypingMessageContent.h>
#import <WFChatClient/WFCCRecallMessageContent.h>
#import <WFChatClient/WFCCVideoMessageContent.h>
#import <WFChatClient/WFCCFriendAddedMessageContent.h>
#import <WFChatClient/WFCCFriendGreetingMessageContent.h>
#import <WFChatClient/WFCCGroupPrivateChatNotificationContent.h>
#import <WFChatClient/WFCCGroupJoinTypeNotificationContent.h>
#import <WFChatClient/WFCCGroupSetManagerNotificationContent.h>
#import <WFChatClient/WFCCGroupMemberMuteNotificationContent.h>
#import <WFChatClient/WFCCGroupMemberAllowNotificationContent.h>
#import <WFChatClient/WFCCDeleteMessageContent.h>
#import <WFChatClient/WFCCGroupMuteNotificationContent.h>
#import <WFChatClient/WFCCPCLoginRequestMessageContent.h>
#import <WFChatClient/WFCCCardMessageContent.h>
#import <WFChatClient/WFCCThingsDataContent.h>
#import <WFChatClient/WFCCThingsLostEventContent.h>
#import <WFChatClient/WFCCConferenceInviteMessageContent.h>
#import <WFChatClient/WFCCCompositeMessageContent.h>
#import <WFChatClient/WFCCLinkMessageContent.h>
#import <WFChatClient/WFCCKickoffGroupMemberVisibleNotificationContent.h>
#import <WFChatClient/WFCCQuitGroupVisibleNotificationContent.h>
#import <WFChatClient/WFCCModifyGroupMemberExtraNotificationContent.h>
#import <WFChatClient/WFCCModifyGroupExtraNotificationContent.h>
#import <WFChatClient/WFCCPTTInviteMessageContent.h>
#import <WFChatClient/WFCCConversation.h>
#import <WFChatClient/WFCCConversationInfo.h>
#import <WFChatClient/WFCCConversationSearchInfo.h>
#import <WFChatClient/WFCCGroupSearchInfo.h>
#import <WFChatClient/WFCCFriendRequest.h>
#import <WFChatClient/WFCCFriend.h>
#import <WFChatClient/WFCCGroupInfo.h>
#import <WFChatClient/WFCCGroupMember.h>
#import <WFChatClient/WFCCUserInfo.h>
#import <WFChatClient/WFCCChatroomInfo.h>
#import <WFChatClient/WFCCUnreadCount.h>
#import <WFChatClient/WFCCUtilities.h>
#import <WFChatClient/WFCCPCOnlineInfo.h>
#import <WFChatClient/WFCCDeliveryReport.h>
#import <WFChatClient/WFCCReadReport.h>
#import <WFChatClient/WFCCFileRecord.h>
#import <WFChatClient/WFCCQuoteInfo.h>
#import <WFChatClient/WFCCEnums.h>

