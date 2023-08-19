//
//  WFCCGroupSettingsNotificationContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/19.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCNotificationMessageContent.h"

/**
 建群的通知消息
 */
@interface WFCCGroupSettingsNotificationContent : WFCCNotificationMessageContent

/**
 群组ID
 */
@property (nonatomic, strong)NSString *groupId;

/**
 操作者ID
 */
@property (nonatomic, strong)NSString *operatorId;

/**
 修改设置类型。7为修改是否查看历史消息；8为修改群最大成员数，9为修改是否为超级群
 */
@property (nonatomic, assign)int type;

/**
 修改后的数据
 */
@property (nonatomic, assign)int value;

@end
