//
//  WFCCUnreadCount.h
//  WFChatClient
//
//  Created by WF Chat on 2018/9/30.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WFCCUnreadCount : NSObject
+(instancetype)countOf:(int)unread mention:(int)mention mentionAll:(int)mentionAll;
@property(nonatomic, assign)int unread;
@property(nonatomic, assign)int unreadMention;
@property(nonatomic, assign)int unreadMentionAll;
@end

NS_ASSUME_NONNULL_END
