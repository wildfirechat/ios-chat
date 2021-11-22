//
//  WFCCMarkUnreadMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"


/**
 标记未读同步消息
 */
@interface WFCCMarkUnreadMessageContent : WFCCMessageContent


/**
  消息ID
 */
@property (nonatomic, assign)int64_t messageUid;

/**
  时间戳
 */
@property (nonatomic, assign)int64_t timestamp;
@end
