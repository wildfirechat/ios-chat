//
//  WFCCTextMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/8/16.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCCMessageContent.h"

/**
 文本消息
 */
@interface WFCCTextMessageContent : WFCCMessageContent

/**
 构造方法

 @param text 文本
 @return 文本消息
 */
+ (instancetype)contentWith:(NSString *)text;

/**
 文本内容
 */
@property (nonatomic, strong)NSString *text;


/**
 提醒类型，1，提醒部分对象（mentinedTarget）。2，提醒全部。其他不提醒
 */
@property (nonatomic, assign)int mentionedType;

/**
 提醒对象，mentionedType 1时有效
 */
@property (nonatomic, strong)NSArray<NSString *> *mentionedTargets;
@end
