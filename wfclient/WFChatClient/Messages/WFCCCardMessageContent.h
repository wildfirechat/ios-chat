//
//  WFCCTextMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"


typedef NS_ENUM(NSInteger, WFCCCardType) {
    CardType_User = 0,
    CardType_Group = 1,
    CardType_Channel = 3
};

/**
 名片消息
 */
@interface WFCCCardMessageContent : WFCCMessageContent

/**
 构造方法

 @param targetId 目标Id
 @param type 类型，0 用户，1 群组， 3 频道。
 @param fromUser 分享用户。
 @return 名片消息
 */
+ (instancetype)cardWithTarget:(NSString *)targetId type:(WFCCCardType)type from:(NSString *)fromUser;

/**
  名片类型
 */
@property (nonatomic, assign)WFCCCardType type;

/**
 用户ID
 */
@property (nonatomic, strong)NSString *targetId;

/**
 用户号
 */
@property (nonatomic, strong)NSString *name;

/**
 用户昵称
 */
@property (nonatomic, strong)NSString *displayName;

/**
 用户头像
 */
@property (nonatomic, strong)NSString *portrait;

/**
分享的用户ID
 */
@property (nonatomic, strong)NSString *fromUser;
@end
