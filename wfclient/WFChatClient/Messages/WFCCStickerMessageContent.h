//
//  WFCCImageMessageContent.h
//  WFChatClient
//
//  Created by heavyrain on 2017/9/2.
//  Copyright © 2017年 wildfire chat. All rights reserved.
//

#import "WFCCMediaMessageContent.h"
#import <UIKit/UIKit.h>

/**
 图片消息
 */
@interface WFCCStickerMessageContent : WFCCMediaMessageContent

/**
 构造方法

 @param stickerPath 表情路径
 @return 表情消息
 */
+ (instancetype)contentFrom:(NSString *)stickerPath;

@property (nonatomic, assign)CGSize size;
@end
