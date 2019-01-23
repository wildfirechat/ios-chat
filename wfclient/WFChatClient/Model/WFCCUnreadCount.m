//
//  WFCCUnreadCount.m
//  WFChatClient
//
//  Created by WF Chat on 2018/9/30.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "WFCCUnreadCount.h"

@implementation WFCCUnreadCount
+(instancetype)countOf:(int)unread mention:(int)mention mentionAll:(int)mentionAll {
    WFCCUnreadCount *count = [[WFCCUnreadCount alloc] init];
    count.unread = unread;
    count.unreadMention = mention;
    count.unreadMentionAll = mentionAll;
    return count;
}
@end
