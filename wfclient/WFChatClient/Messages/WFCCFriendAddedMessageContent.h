//
//  WFCCFriendAddedMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 好友添加成功的通知。一般可以显示为你已添加XXX为好友了，可以开始聊天了。本消息和WFCCFriendGreetingMessageContent为后添加的，之前服务器端是直接发送了2个tip消息，这样就没有办法做多语言化了。但现在还不能直接使用这两个消息，因为有历史兼容问题，可以先加上这两个功能，等您的应用的SDK都更新支持这两个消息以后，再在服务器端加上。
 */
@interface WFCCFriendAddedMessageContent : WFCCNotificationMessageContent

@end
